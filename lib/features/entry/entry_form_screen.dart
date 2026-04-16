// ═══════════════════════════════════════════════════════════════════
// ENTRY_FORM_SCREEN.DART — Full Expanded Entry Form
// Used for: retroactive logging from Book +, editing existing entries,
// and detailed entry creation.
// All fields visible — no collapsed/iceberg state.
// See SPEC.md §8.6 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/engines/engines.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_providers.dart';
import '../../core/utils/provider_refresh.dart';
import '../../core/theme/kitab_theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/widgets/kitab_toast.dart';
import '../../core/widgets/datetime_tz_picker.dart';
import '../../data/models/activity.dart';
import '../../data/models/category.dart' as domain;
import '../../data/models/entry.dart';
import 'widgets/field_input_builder.dart';

const _uuid = Uuid();
const _linkageEngine = LinkageEngine();

class EntryFormScreen extends ConsumerStatefulWidget {
  final Entry? existingEntry;
  final Activity? preselectedActivity;
  /// When true, the form is embedded in another screen (master-detail)
  /// and should NOT call Navigator.pop on save/delete.
  final bool embedded;
  /// Called when save completes in embedded mode.
  final VoidCallback? onSaved;
  /// Called when delete completes in embedded mode.
  final VoidCallback? onDeleted;
  /// Called when the unsaved changes state changes (for parent to track).
  final ValueChanged<bool>? onDirtyChanged;

  const EntryFormScreen({
    super.key,
    this.existingEntry,
    this.preselectedActivity,
    this.embedded = false,
    this.onSaved,
    this.onDeleted,
    this.onDirtyChanged,
  });

  @override
  ConsumerState<EntryFormScreen> createState() => EntryFormScreenState();
}

class EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  Activity? _selectedActivity;
  domain.Category? _selectedCategory;
  late DateTimeTz _loggedAtTz;
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};
  bool _saving = false;
  bool _hasUnsavedChanges = false;

  /// Public getter for parent to check dirty state via GlobalKey.
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      widget.onDirtyChanged?.call(true);
    }
  }

  // Activity search
  List<Activity> _allActivities = [];
  List<Activity> _filteredActivities = [];
  Map<String, domain.Category> _categories = {};
  bool _showSuggestions = false;

  // Time & Duration
  bool _showTimeDuration = false;
  DateTimeTz? _startTimeTz;
  DateTimeTz? _endTimeTz;

  // Auto-linked period
  DateTime? _linkedPeriodStart;
  DateTime? _linkedPeriodEnd;
  String? _linkType;

  // Schedule context
  bool _showScheduleContext = false;
  DateTime? _expectedStart; // time-only but stored as DateTime for picker
  DateTime? _expectedEnd;

  // Activity location
  double? _activityLocationLat;
  double? _activityLocationLng;
  String? _activityLocationName;

  // Ad-hoc fields
  final List<_AdHocField> _adHocFields = [];

  // Timer segments (for timer entries)
  List<Map<String, String>> _segments = [];
  bool get _isTimerEntry => _segments.isNotEmpty;
  bool get _hasMultipleSegments => _segments.length > 1;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    _loggedAtTz = DateTimeTz(dateTime: entry?.loggedAt ?? DateTime.now());
    _notesController.text = entry?.notes ?? '';
    _selectedActivity = widget.preselectedActivity;

    if (entry != null) {
      _nameController.text = entry.name;
      // Pre-populate field values (skip adhoc fields — handled separately below)
      entry.fieldValues.forEach((key, value) {
        if (!key.startsWith('adhoc_')) {
          _fieldControllers[key] = TextEditingController(text: value.toString());
        }
      });
      // Reconstruct ad-hoc fields from saved data
      entry.fieldValues.forEach((key, value) {
        if (key.startsWith('adhoc_') && value is Map) {
          final label = value['label'] as String? ?? 'Field';
          final typeKey = value['type'] as String? ?? 'text';
          final savedValue = value['value'];
          final field = _AdHocField(label: label, typeKey: typeKey);
          field.controller.text = savedValue?.toString() ?? '';
          _adHocFields.add(field);
        }
      });
      // Parse timer segments
      if (entry.timerSegments != null && entry.timerSegments!.isNotEmpty) {
        _segments = entry.timerSegments!.map((s) => Map<String, String>.from(s)).toList();
        _showTimeDuration = true;
        // Auto-fill start/end from segments
        final firstStart = DateTime.parse(_segments.first['start']!);
        final lastEnd = DateTime.parse(_segments.last['end']!);
        _startTimeTz = DateTimeTz(dateTime: firstStart.toLocal());
        _endTimeTz = DateTimeTz(dateTime: lastEnd.toLocal());
      }
      // Parse preset time/duration values from fieldValues
      else if (entry.fieldValues.containsKey('start_time') ||
          entry.fieldValues.containsKey('end_time') ||
          entry.fieldValues.containsKey('duration_minutes') ||
          entry.fieldValues.containsKey('duration_seconds')) {
        _showTimeDuration = true;
        // Parse start time
        final rawStart = entry.fieldValues['start_time'];
        if (rawStart is String) {
          final dt = DateTime.tryParse(rawStart);
          if (dt != null) _startTimeTz = DateTimeTz(dateTime: dt.toLocal());
        }
        // Parse end time
        final rawEnd = entry.fieldValues['end_time'];
        if (rawEnd is String) {
          final dt = DateTime.tryParse(rawEnd);
          if (dt != null) _endTimeTz = DateTimeTz(dateTime: dt.toLocal());
        }
      }
      // Initialize period linkage from existing entry
      _linkedPeriodStart = entry.periodStart;
      _linkedPeriodEnd = entry.periodEnd;
      _linkType = entry.linkType;

      // Schedule context fields
      final rawExpectedStart = entry.fieldValues['expected_start'];
      if (rawExpectedStart is String) {
        _expectedStart = DateTime.tryParse(rawExpectedStart);
      }
      final rawExpectedEnd = entry.fieldValues['expected_end'];
      if (rawExpectedEnd is String) {
        _expectedEnd = DateTime.tryParse(rawExpectedEnd);
      }
      _showScheduleContext = _linkedPeriodStart != null || _expectedStart != null || _expectedEnd != null;

      // Activity location fields
      final rawLat = entry.fieldValues['activity_location_lat'];
      final rawLng = entry.fieldValues['activity_location_lng'];
      if (rawLat is num) _activityLocationLat = rawLat.toDouble();
      if (rawLng is num) _activityLocationLng = rawLng.toDouble();
      _activityLocationName = entry.fieldValues['activity_location_name'] as String?;
    } else if (widget.preselectedActivity != null) {
      _nameController.text = widget.preselectedActivity!.name;
      _buildFieldControllers(widget.preselectedActivity!);
      if (widget.preselectedActivity!.fields.any((f) => f['type'] == 'preset')) {
        _showTimeDuration = true;
      }
    }

    _loadActivities();

    // Auto-populate activity location from current location for new entries
    if (!_isEditing) {
      _autoPopulateLocation();
    }
  }

  Future<void> _autoPopulateLocation() async {
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location != null && mounted) {
      setState(() {
        _activityLocationLat = location.latitude;
        _activityLocationLng = location.longitude;
        // TODO: Reverse geocode for name (async, update when ready)
      });
    }
  }

  Future<void> _loadActivities() async {
    final userId = ref.read(currentUserIdProvider);
    final activities = await ref.read(activityRepositoryProvider).getByUser(userId);
    final categories = await ref.read(categoryRepositoryProvider).getByUser(userId);

    if (mounted) {
      setState(() {
        _allActivities = activities.where((a) => !a.isArchived).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _categories = {for (final c in categories) c.id: c};

        // Resolve _selectedActivity from entry's activityId when editing
        if (_selectedActivity == null && widget.existingEntry?.activityId != null) {
          final match = activities
              .where((a) => a.id == widget.existingEntry!.activityId)
              .firstOrNull;
          if (match != null) {
            _selectedActivity = match;
          }
        }

        if (_selectedActivity != null) {
          _selectedCategory = _categories[_selectedActivity!.categoryId];
        }
      });

      // Auto-link for preselected activity (after prayer times are available)
      if (_selectedActivity != null && _linkedPeriodStart == null && widget.existingEntry == null) {
        _selectActivity(_selectedActivity!);
      }
    }
  }

  void _buildFieldControllers(Activity activity) {
    _fieldControllers.clear();
    for (final field in activity.fields) {
      if (field['type'] == 'preset') continue; // Presets handled in Time & Duration
      final fieldId = field['id'] as String? ?? '';
      final existingValue = widget.existingEntry?.fieldValues[fieldId]?.toString() ?? '';
      _fieldControllers[fieldId] = TextEditingController(text: existingValue);
    }
  }

  void _selectActivity(Activity activity) {
    setState(() {
      _selectedActivity = activity;
      _selectedCategory = _categories[activity.categoryId];
      _nameController.text = activity.name;
      _showSuggestions = false;
      _markDirty();
      _buildFieldControllers(activity);
      if (activity.fields.any((f) => f['type'] == 'preset')) {
        _showTimeDuration = true;
      }

      // Compute expected times if schedule has time window
      if (activity.schedule != null) {
        final result = PeriodEngine.resolveExpectedTimes(
          scheduleJson: activity.schedule,
          date: _loggedAtTz.dateTime,
          // TODO: pass prayer resolver from activity location if dynamic
        );
        if (result.start != null) _expectedStart = result.start;
        if (result.end != null) _expectedEnd = result.end;
        _showScheduleContext = _linkedPeriodStart != null || _expectedStart != null || _expectedEnd != null;
      }
    });
    // Compute linkage asynchronously (fetches entry counts)
    _recomputeLinkage();
  }

  void _clearActivity() {
    setState(() {
      _selectedActivity = null;
      _selectedCategory = null;
      _fieldControllers.clear();
      _markDirty();
    });
  }

  void _filterActivities(String query) {
    if (query.isEmpty) {
      _filteredActivities = List.from(_allActivities);
    } else {
      _filteredActivities = _allActivities
          .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  String? get _calculatedDuration {
    if (_startTimeTz == null || _endTimeTz == null) return null;
    final diff = _endTimeTz!.dateTime.difference(_startTimeTz!.dateTime);
    if (diff.isNegative) return null;
    if (diff.inHours > 0) {
      final mins = diff.inMinutes.remainder(60);
      return mins > 0 ? '${diff.inHours}h ${mins}m' : '${diff.inHours}h';
    }
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return '${diff.inSeconds}s';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    for (final c in _fieldControllers.values) c.dispose();
    for (final f in _adHocFields) f.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
        appBar: widget.embedded ? null : AppBar(
          title: Text(_isEditing ? 'Edit Entry' : 'New Entry', style: KitabTypography.h2),
          actions: [
            if (_isEditing)
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(KitabSpacing.lg),
              children: [
                // ═══ ACTIVITY SEARCH ═══
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Activity',
                    hintText: 'Search or type a name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _nameController.clear();
                              _clearActivity();
                              setState(() { _filterActivities(''); _showSuggestions = true; });
                            },
                          )
                        : null,
                  ),
                  onTap: () => setState(() => _showSuggestions = true),
                  onChanged: (query) {
                    _clearActivity();
                    setState(() {
                      _filterActivities(query);
                      _showSuggestions = query.isNotEmpty || _filteredActivities.isNotEmpty;
                      _markDirty();
                    });
                  },
                ),

                // Suggestions
                if (_showSuggestions && _filteredActivities.isNotEmpty && _selectedActivity == null)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                      borderRadius: KitabRadii.borderSm,
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredActivities.length,
                      itemBuilder: (_, index) {
                        final activity = _filteredActivities[index];
                        final cat = _categories[activity.categoryId];
                          return ListTile(
                            dense: true,
                            leading: Text(cat?.icon ?? '📁', style: const TextStyle(fontSize: 18)),
                            title: Text(activity.name),
                            subtitle: cat != null ? Text(cat.name, style: KitabTypography.caption.copyWith(color: KitabColors.gray500)) : null,
                            onTap: () => _selectActivity(activity),
                          );
                        },
                      ),
                    ),

                // Category line
                if (_selectedCategory != null) ...[
                  const SizedBox(height: KitabSpacing.sm),
                  Row(
                    children: [
                      Text(_selectedCategory!.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(_selectedCategory!.name, style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
                    ],
                  ),
                ],

                // ═══ LOGGED TIME (always visible, standalone) ═══
                const SizedBox(height: KitabSpacing.lg),
                DateTimeTzTile(
                  label: 'Logged Time',
                  value: _loggedAtTz,
                  icon: Icons.access_time,
                  onChanged: (v) {
                    setState(() { _loggedAtTz = v; _markDirty(); });
                    // Re-link if no start time is set (loggedAt is the link source)
                    if (_startTimeTz == null) _recomputeLinkage();
                  },
                ),

                // ═══ TIME & DURATION ═══
                const Divider(),
                SwitchListTile(
                  title: Text('Time & Duration', style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  value: _showTimeDuration,
                  onChanged: (v) => setState(() { _showTimeDuration = v; _markDirty(); }),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_showTimeDuration) ...[
                  // If multiple segments, overall start/end/duration are read-only
                  if (_hasMultipleSegments) ...[
                    _readOnlyTimeTile('Start Time', _startTimeTz, Icons.login),
                    _readOnlyTimeTile('End Time', _endTimeTz, Icons.logout),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.timer, size: 20, color: KitabColors.gray400),
                      title: const Text('Active Duration'),
                      subtitle: Text(
                        _segmentActiveDuration,
                        style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray600, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_segmentIdleDuration != '0m')
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.pause_circle_outline, size: 20, color: KitabColors.gray400),
                        title: const Text('Idle Duration'),
                        subtitle: Text(
                          _segmentIdleDuration,
                          style: KitabTypography.bodySmall.copyWith(color: KitabColors.warning, fontWeight: FontWeight.w500),
                        ),
                      ),
                    Text('${_segments.length} segments — edit individually below',
                        style: KitabTypography.caption.copyWith(color: KitabColors.gray400)),
                  ] else ...[
                    DateTimeTzTile(
                      label: 'Start Time',
                      value: _startTimeTz,
                      icon: Icons.login,
                      onChanged: (v) {
                        setState(() {
                          _startTimeTz = v;
                          _endTimeTz ??= DateTimeTz(
                            dateTime: v.dateTime.add(const Duration(minutes: 5)),
                            utcOffset: v.utcOffset,
                            tzLabel: v.tzLabel,
                          );
                          _markDirty();
                        });
                        // Re-link based on the new start time
                        _recomputeLinkage();
                      },
                    ),
                    DateTimeTzTile(
                      label: 'End Time',
                      value: _endTimeTz,
                      icon: Icons.logout,
                      onChanged: (v) => setState(() {
                        _endTimeTz = v;
                        // Auto-set start time 5 min earlier if not set
                        _startTimeTz ??= DateTimeTz(
                          dateTime: v.dateTime.subtract(const Duration(minutes: 5)),
                          utcOffset: v.utcOffset,
                          tzLabel: v.tzLabel,
                        );
                        _markDirty();
                      }),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.timer, size: 20, color: KitabColors.gray400),
                      title: const Text('Duration'),
                      subtitle: Text(
                        _isTimerEntry ? _segmentActiveDuration : (_calculatedDuration ?? '—'),
                        style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray600, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],

                // ═══ SEGMENTS (only when multiple) ═══
                if (_hasMultipleSegments) ...[
                  const Divider(),
                  Text('Segments', style: KitabTypography.h3),
                  const SizedBox(height: KitabSpacing.sm),
                  ..._segments.asMap().entries.map((entry) {
                    final i = entry.key;
                    final seg = entry.value;
                    return _buildSegmentTile(seg, i);
                  }),
                ],

                // ═══ SCHEDULE CONTEXT ═══
                const Divider(),
                SwitchListTile(
                  title: Text('Schedule Context', style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  value: _showScheduleContext,
                  onChanged: (v) => setState(() { _showScheduleContext = v; _markDirty(); }),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_showScheduleContext) ...[
                  // Linked Period
                  if (_linkedPeriodStart != null && _linkedPeriodEnd != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.date_range,
                          color: _linkType == 'auto' ? KitabColors.primary : KitabColors.success),
                      title: Text(_linkType == 'auto' ? 'Auto-linked Period' : 'Linked Period'),
                      subtitle: Text(
                        ref.watch(dateFormatterProvider).fullDateWithDay(_linkedPeriodStart!),
                        style: KitabTypography.bodySmall.copyWith(
                          color: _linkType == 'auto' ? KitabColors.primary : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
                        tooltip: 'Change period',
                        onPressed: _showPeriodPicker,
                      ),
                    ),
                  ] else if (_selectedActivity?.schedule != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link_off, color: KitabColors.warning),
                      title: const Text('No matching period'),
                      subtitle: Text(
                        'No period matches the current time.',
                        style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
                      ),
                      trailing: TextButton(
                        onPressed: _showPeriodPicker,
                        child: const Text('Link manually'),
                      ),
                    ),
                  ],
                  // Expected Start
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag, size: 20, color: KitabColors.gray400),
                    title: const Text('Expected Start'),
                    subtitle: Text(
                      _expectedStart != null
                          ? ref.watch(dateFormatterProvider).time(_expectedStart!)
                          : 'Not set',
                      style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray600),
                    ),
                    trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
                    onTap: () => _pickExpectedTime(isStart: true),
                  ),
                  // Expected End
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag, size: 20, color: KitabColors.gray400),
                    title: const Text('Expected End'),
                    subtitle: Text(
                      _expectedEnd != null
                          ? ref.watch(dateFormatterProvider).time(_expectedEnd!)
                          : 'Not set',
                      style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray600),
                    ),
                    trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
                    onTap: () => _pickExpectedTime(isStart: false),
                  ),
                ],

                // ═══ NOTES ═══
                const SizedBox(height: KitabSpacing.sm),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Any additional notes...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  onChanged: (_) => setState(() => _markDirty()),
                ),

                // ═══ FIELDS ═══
                const Divider(),
                Text('Fields', style: KitabTypography.h3),
                const SizedBox(height: KitabSpacing.sm),

                // Activity Location (always first, always visible)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place, size: 20, color: KitabColors.gray400),
                  title: const Text('Activity Location'),
                  subtitle: Text(_activityLocationName ?? 'Not set'),
                  trailing: const Icon(Icons.edit, size: 18, color: KitabColors.gray400),
                  onTap: () { /* TODO: Open location picker */ },
                ),

                // Template fields
                if (_selectedActivity != null && _nonPresetFields.isNotEmpty)
                  ..._nonPresetFields.map((field) {
                    final fieldId = field['id'] as String? ?? '';
                    final label = field['label'] as String? ?? 'Field';
                    final type = field['type'] as String? ?? 'text';
                    final unit = field['unit'] as String?;
                    final controller = _fieldControllers.putIfAbsent(fieldId, () => TextEditingController());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: KitabSpacing.md),
                      child: FieldInputBuilder.build(
                        context: context,
                        fieldId: fieldId,
                        label: label,
                        type: type,
                        unit: unit,
                        config: field,
                        controller: controller,
                        onChanged: (_) => setState(() => _markDirty()),
                      ),
                    );
                  }),

                // ═══ ADDITIONAL FIELDS (ad-hoc) ═══
                if (_adHocFields.isNotEmpty) ...[
                  const SizedBox(height: KitabSpacing.md),
                  Text('Additional Fields', style: KitabTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: KitabColors.gray600,
                  )),
                  const SizedBox(height: KitabSpacing.xs),
                  ..._adHocFields.asMap().entries.map((entry) {
                    final i = entry.key;
                    final field = entry.value;
                    return _buildAdHocField(field, i);
                  }),
                ],
                const SizedBox(height: KitabSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _showAddFieldMenu,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Field'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                const SizedBox(height: KitabSpacing.xl),

                // ═══ SAVE BUTTON ═══
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving || _hasDuplicateFieldNames || (!_hasUnsavedChanges && _isEditing) ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'Save Changes' : 'Log Entry'),
                  ),
                ),

                // ═══ DELETE BUTTON (for existing entries) ═══
                if (_isEditing) ...[
                  const SizedBox(height: KitabSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete Entry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KitabColors.error,
                        side: const BorderSide(color: KitabColors.error),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: KitabSpacing.lg),
              ],
            ),
          ),
        ),
    );

    // Embedded mode: no PopScope (parent handles discard)
    if (widget.embedded) return content;

    // Full-page mode: prompt before discarding unsaved changes
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasUnsavedChanges) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Discard changes?'),
              content: const Text('You have unsaved changes that will be lost.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Keep Editing'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _hasUnsavedChanges = false;
                    Navigator.pop(context);
                  },
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
        }
      },
      child: content,
    );
  }

  List<Map<String, dynamic>> get _nonPresetFields {
    if (_selectedActivity == null) return [];
    return _selectedActivity!.fields.where((f) => f['type'] != 'preset').toList();
  }


  // ─── Ad-hoc fields ───
  Widget _buildAdHocField(_AdHocField field, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
      padding: const EdgeInsets.all(KitabSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: KitabColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: field.labelController,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Field name',
                    errorText: _isReservedFieldName(field.labelController.text)
                        ? 'Reserved field name'
                        : _isFieldNameTaken(field.labelController.text, field.id)
                            ? 'Name already used'
                            : null,
                  ),
                  style: KitabTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  onChanged: (_) => setState(() => _markDirty()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: KitabColors.error),
                onPressed: () => setState(() {
                  field.controller.dispose();
                  field.labelController.dispose();
                  _adHocFields.removeAt(index);
                  _markDirty();
                }),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: KitabSpacing.xs),
          FieldInputBuilder.build(
            context: context,
            fieldId: field.id,
            label: '',
            type: field.typeKey,
            unit: null,
            controller: field.controller,
            onChanged: (_) => setState(() => _markDirty()),
          ),
        ],
      ),
    );
  }

  /// Whether any ad-hoc field has a duplicate name.
  bool get _hasDuplicateFieldNames {
    for (final f in _adHocFields) {
      if (_isFieldNameTaken(f.labelController.text, f.id)) return true;
    }
    return false;
  }

  /// Get all current field names (template + ad-hoc, case-insensitive).
  Set<String> _allFieldNames({String? excludeId}) {
    final names = <String>{};
    // Template field names
    if (_selectedActivity != null) {
      for (final f in _selectedActivity!.fields) {
        final label = f['label'] as String? ?? '';
        if (label.isNotEmpty) names.add(label.toLowerCase());
      }
    }
    // Notes is always present
    names.add('notes');
    // Ad-hoc field names
    for (final f in _adHocFields) {
      if (excludeId != null && f.id == excludeId) continue;
      names.add(f.labelController.text.trim().toLowerCase());
    }
    return names;
  }

  /// Generate a unique field name by appending a number if needed.
  String _uniqueFieldName(String baseName) {
    final existing = _allFieldNames();
    if (!existing.contains(baseName.toLowerCase())) return baseName;
    for (var i = 2; i <= 99; i++) {
      final candidate = '$baseName $i';
      if (!existing.contains(candidate.toLowerCase())) return candidate;
    }
    return '$baseName ${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Check if a field name conflicts with existing names (for rename validation).
  bool _isFieldNameTaken(String name, String fieldId) {
    final existing = _allFieldNames(excludeId: fieldId);
    return existing.contains(name.trim().toLowerCase());
  }

  /// Reserved field names that cannot be used for ad-hoc fields (case-insensitive).
  static const _reservedFieldNames = [
    'activity location',
    'expected start',
    'expected end',
    'logged time',
  ];

  /// Check if a name is reserved (case-insensitive).
  bool _isReservedFieldName(String name) {
    return _reservedFieldNames.contains(name.trim().toLowerCase());
  }

  void _showAddFieldMenu() {
    const types = [
      ('Number', 'number', Icons.pin),
      ('Text', 'text', Icons.text_fields),
      ('Star Rating', 'rating', Icons.star),
      ('Mood', 'mood', Icons.sentiment_satisfied),
      ('Yes / No', 'boolean', Icons.check_circle_outline),
      ('Location', 'location', Icons.location_on),
      ('List', 'list', Icons.list),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(KitabSpacing.md),
              child: Text('Add Field', style: KitabTypography.h3),
            ),
            ...types.map((t) => ListTile(
              leading: Icon(t.$3, color: KitabColors.primary),
              title: Text(t.$1),
              onTap: () {
                Navigator.pop(ctx);
                final uniqueName = _uniqueFieldName(t.$1);
                if (_isReservedFieldName(uniqueName)) {
                  KitabToast.error(context, '"$uniqueName" is a reserved field name');
                  return;
                }
                setState(() {
                  _adHocFields.add(_AdHocField(label: uniqueName, typeKey: t.$2));
                  _markDirty();
                });
              },
            )),
            const SizedBox(height: KitabSpacing.md),
          ],
        ),
      ),
    );
  }

  // ─── Segment helpers ───

  String get _segmentActiveDuration {
    var total = Duration.zero;
    for (final seg in _segments) {
      final start = DateTime.parse(seg['start']!);
      final end = DateTime.parse(seg['end']!);
      total += end.difference(start);
    }
    return _formatDur(total);
  }

  String get _segmentIdleDuration {
    var total = Duration.zero;
    for (var i = 1; i < _segments.length; i++) {
      final prevEnd = DateTime.parse(_segments[i - 1]['end']!);
      final nextStart = DateTime.parse(_segments[i]['start']!);
      final gap = nextStart.difference(prevEnd);
      if (!gap.isNegative) total += gap;
    }
    return _formatDur(total);
  }

  String _formatDur(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    return '${d.inSeconds}s';
  }

  Widget _readOnlyTimeTile(String label, DateTimeTz? value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, size: 20, color: KitabColors.gray400),
      title: Text(label),
      subtitle: Text(
        value?.formatted ?? '—',
        style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500),
      ),
    );
  }

  Widget _buildSegmentTile(Map<String, String> seg, int index) {
    final start = DateTime.parse(seg['start']!).toLocal();
    final end = DateTime.parse(seg['end']!).toLocal();
    final duration = end.difference(start);
    final fmt = ref.watch(dateFormatterProvider);
    final startStr = fmt.timeWithSeconds(start);
    final endStr = fmt.timeWithSeconds(end);

    // Idle time after this segment (if not the last)
    String? idleStr;
    if (index < _segments.length - 1) {
      final nextStart = DateTime.parse(_segments[index + 1]['start']!);
      final idle = nextStart.difference(end);
      if (!idle.isNegative && idle.inSeconds > 0) {
        idleStr = _formatDur(idle);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(KitabSpacing.sm),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: KitabColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KitabColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: KitabColors.primary.withValues(alpha: 0.1),
                child: Text('${index + 1}', style: KitabTypography.caption.copyWith(
                  color: KitabColors.primary, fontWeight: FontWeight.w600, fontSize: 11,
                )),
              ),
              const SizedBox(width: KitabSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start time (tappable to edit)
                    InkWell(
                      onTap: () => _editSegmentStart(index),
                      child: Row(
                        children: [
                          Text('Start: $startStr', style: KitabTypography.bodySmall),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 12, color: KitabColors.gray400),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // End time (tappable to edit)
                    InkWell(
                      onTap: () => _editSegmentEnd(index),
                      child: Row(
                        children: [
                          Text('End: $endStr', style: KitabTypography.bodySmall),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 12, color: KitabColors.gray400),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Duration: ${_formatDur(duration)}',
                        style: KitabTypography.caption.copyWith(color: KitabColors.gray500)),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: KitabColors.error),
                onPressed: () => _deleteSegment(index),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        // Idle gap indicator
        if (idleStr != null)
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 2),
            child: Row(
              children: [
                const Icon(Icons.pause, size: 12, color: KitabColors.warning),
                const SizedBox(width: 4),
                Text('$idleStr idle', style: KitabTypography.caption.copyWith(color: KitabColors.warning)),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _editSegmentStart(int index) async {
    final seg = _segments[index];
    final start = DateTime.parse(seg['start']!).toLocal();
    final end = DateTime.parse(seg['end']!).toLocal();
    final duration = end.difference(start);

    final newStart = await _pickFullDateTime(
      context,
      initial: DateTimeTz(dateTime: start),
      helpText: 'Segment ${index + 1} — Start',
    );
    if (newStart == null || !mounted) return;

    // Preserve duration: shift end to match
    _applySegmentEdit(index, newStart.dateTime, newStart.dateTime.add(duration));
  }

  Future<void> _editSegmentEnd(int index) async {
    final seg = _segments[index];
    final start = DateTime.parse(seg['start']!).toLocal();
    final end = DateTime.parse(seg['end']!).toLocal();
    final duration = end.difference(start);

    final newEnd = await _pickFullDateTime(
      context,
      initial: DateTimeTz(dateTime: end),
      helpText: 'Segment ${index + 1} — End',
    );
    if (newEnd == null || !mounted) return;

    // Preserve duration: shift start to match
    _applySegmentEdit(index, newEnd.dateTime.subtract(duration), newEnd.dateTime);
  }

  /// Apply a segment edit, then resolve overlaps and refresh overall times.
  void _applySegmentEdit(int index, DateTime newStart, DateTime newEnd) {
    // Ensure no negative duration
    if (newEnd.isBefore(newStart) || newEnd == newStart) {
      KitabToast.error(context, 'Invalid time range');
      return;
    }

    setState(() {
      _segments[index] = {
        'start': newStart.toUtc().toIso8601String(),
        'end': newEnd.toUtc().toIso8601String(),
      };
      _resolveOverlaps();
      _refreshOverallFromSegments();
      _markDirty();
    });
  }

  /// Delete a segment. If only 1 remains, it becomes the overall start/end.
  void _deleteSegment(int index) {
    if (_segments.length <= 1) {
      KitabToast.error(context, 'Cannot delete the last segment');
      return;
    }

    setState(() {
      _segments.removeAt(index);
      _refreshOverallFromSegments();
      _markDirty();
    });
  }

  /// Resolve overlaps between segments by shifting later segments forward.
  /// Preserves each segment's duration.
  void _resolveOverlaps() {
    for (var i = 1; i < _segments.length; i++) {
      final prevEnd = DateTime.parse(_segments[i - 1]['end']!);
      final currStart = DateTime.parse(_segments[i]['start']!);
      final currEnd = DateTime.parse(_segments[i]['end']!);
      final currDuration = currEnd.difference(currStart);

      if (currStart.isBefore(prevEnd)) {
        // Overlap detected — shift this segment to start right after previous end
        final newStart = prevEnd;
        final newEnd = newStart.add(currDuration);
        _segments[i] = {
          'start': newStart.toUtc().toIso8601String(),
          'end': newEnd.toUtc().toIso8601String(),
        };
      }
    }
  }

  /// Update overall start/end from the first/last segment.
  void _refreshOverallFromSegments() {
    if (_segments.isEmpty) return;
    final firstStart = DateTime.parse(_segments.first['start']!);
    final lastEnd = DateTime.parse(_segments.last['end']!);
    _startTimeTz = DateTimeTz(dateTime: firstStart.toLocal());
    _endTimeTz = DateTimeTz(dateTime: lastEnd.toLocal());
  }

  /// Full date + time + timezone picker (reuses the same 3-step flow as DateTimeTzTile).
  Future<DateTimeTz?> _pickFullDateTime(
    BuildContext context, {
    required DateTimeTz initial,
    String? helpText,
  }) async {
    // Step 1: Date
    final date = await showDatePicker(
      context: context,
      initialDate: initial.dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: helpText != null ? '$helpText — Date' : null,
    );
    if (date == null || !mounted) return null;

    // Step 2: Time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial.dateTime),
      helpText: helpText != null ? '$helpText — Time' : null,
    );
    if (time == null || !mounted) return null;

    final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Step 3: Timezone
    final newTz = await _pickTimezone(context, initial.utcOffset, initial.tzLabel);

    return DateTimeTz(
      dateTime: newDt,
      utcOffset: newTz?.offset ?? initial.utcOffset,
      tzLabel: newTz?.label ?? initial.tzLabel,
    );
  }

  Future<({Duration offset, String label})?> _pickTimezone(
      BuildContext context, Duration currentOffset, String currentLabel) {
    const commonOffsets = [
      (offset: Duration(hours: -12), label: 'UTC-12 (Baker Island)'),
      (offset: Duration(hours: -11), label: 'UTC-11 (Samoa)'),
      (offset: Duration(hours: -10), label: 'UTC-10 (Hawaii)'),
      (offset: Duration(hours: -9), label: 'UTC-9 (Alaska)'),
      (offset: Duration(hours: -8), label: 'UTC-8 (Pacific)'),
      (offset: Duration(hours: -7), label: 'UTC-7 (Mountain)'),
      (offset: Duration(hours: -6), label: 'UTC-6 (Central)'),
      (offset: Duration(hours: -5), label: 'UTC-5 (Eastern)'),
      (offset: Duration(hours: -4), label: 'UTC-4 (Atlantic)'),
      (offset: Duration(hours: -3), label: 'UTC-3 (Buenos Aires)'),
      (offset: Duration(hours: -2), label: 'UTC-2'),
      (offset: Duration(hours: -1), label: 'UTC-1 (Azores)'),
      (offset: Duration.zero, label: 'UTC+0 (London/GMT)'),
      (offset: Duration(hours: 1), label: 'UTC+1 (Paris/Berlin)'),
      (offset: Duration(hours: 2), label: 'UTC+2 (Cairo/Athens)'),
      (offset: Duration(hours: 3), label: 'UTC+3 (Riyadh/Moscow)'),
      (offset: Duration(hours: 4), label: 'UTC+4 (Dubai)'),
      (offset: Duration(hours: 5), label: 'UTC+5 (Karachi)'),
      (offset: Duration(hours: 5, minutes: 30), label: 'UTC+5:30 (Mumbai)'),
      (offset: Duration(hours: 6), label: 'UTC+6 (Dhaka)'),
      (offset: Duration(hours: 7), label: 'UTC+7 (Bangkok)'),
      (offset: Duration(hours: 8), label: 'UTC+8 (Singapore/Beijing)'),
      (offset: Duration(hours: 9), label: 'UTC+9 (Tokyo)'),
      (offset: Duration(hours: 10), label: 'UTC+10 (Sydney)'),
      (offset: Duration(hours: 12), label: 'UTC+12 (Auckland)'),
    ];

    return showModalBottomSheet<({Duration offset, String label})>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(KitabSpacing.md),
            child: Row(
              children: [
                Text('Timezone', style: KitabTypography.h3),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Current')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: commonOffsets.length,
              itemBuilder: (_, i) {
                final tz = commonOffsets[i];
                final isSelected = tz.offset == currentOffset;
                return ListTile(
                  title: Text(tz.label),
                  trailing: isSelected ? const Icon(Icons.check, color: KitabColors.primary) : null,
                  selected: isSelected,
                  onTap: () {
                    final shortLabel = tz.label.split(' (').first;
                    Navigator.pop(ctx, (offset: tz.offset, label: shortLabel));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Pick a time for expected start or end.
  Future<void> _pickExpectedTime({required bool isStart}) async {
    final initial = isStart ? _expectedStart : _expectedEnd;
    final time = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay.fromDateTime(initial)
          : TimeOfDay.now(),
      helpText: isStart ? 'Expected Start' : 'Expected End',
    );
    if (time == null || !mounted) return;

    final now = DateTime.now();
    final picked = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _expectedStart = picked;
      } else {
        _expectedEnd = picked;
      }
      _markDirty();
    });
  }

  /// Recompute period auto-linkage based on current start time or loggedAt.
  Future<void> _recomputeLinkage() async {
    if (_selectedActivity == null || _selectedActivity!.schedule == null) return;

    if (!mounted) return;

    final linkTime = _startTimeTz?.dateTime ?? _loggedAtTz.dateTime;

    final linkage = _linkageEngine.autoLink(
      loggedAt: linkTime,
      scheduleJson: _selectedActivity!.schedule,
    );

    if (!mounted) return;
    setState(() {
      _linkedPeriodStart = linkage.linkedPeriod?.start;
      _linkedPeriodEnd = linkage.linkedPeriod?.end;
      _linkType = linkage.linkType;
    });
  }

  /// Open a bottom sheet to manually pick a period.
  Future<void> _showPeriodPicker() async {
    if (_selectedActivity == null || _selectedActivity!.schedule == null) return;

    const periodEngine = PeriodEngine();
    final now = DateTime.now();

    // Compute periods for last 30 days up to end of today (no future)
    final todayEnd = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final allPeriods = periodEngine.computePeriods(
      scheduleJson: _selectedActivity!.schedule,
      queryStart: now.subtract(const Duration(days: 30)),
      queryEnd: todayEnd,
    );

    // Deduplicate and filter out future periods (not started yet)
    final seen = <String>{};
    final uniquePeriods = allPeriods.where((p) {
      if (p.start.isAfter(now)) return false; // Skip periods that haven't started
      final key = '${p.start.millisecondsSinceEpoch}_${p.end.millisecondsSinceEpoch}';
      return seen.add(key);
    }).toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    // Fetch entry counts
    final userId = ref.read(currentUserIdProvider);
    final entryRepo = ref.read(entryRepositoryProvider);
    final periodsWithCounts = <({ComputedPeriod period, int entryCount})>[];
    for (final period in uniquePeriods.take(60)) {
      final entries = await entryRepo.getByPeriod(
        userId, _selectedActivity!.id, period.start, period.end,
      );
      periodsWithCounts.add((period: period, entryCount: entries.length));
    }

    if (!mounted) return;

    // Extract dynamic window names from schedule config for display
    String? dynamicWindowLabel;
    final versions = _selectedActivity!.schedule!['versions'] as List<dynamic>?;
    if (versions != null && versions.isNotEmpty) {
      final config = (versions.last as Map<String, dynamic>)['config'] as Map<String, dynamic>?;
      if (config != null) {
        final timeType = config['time_type'] as String?;
        final winStart = config['window_start'] as String?;
        final winEnd = config['window_end'] as String?;
        final startOffset = config['window_start_offset'] as int? ?? 0;
        final endOffset = config['window_end_offset'] as int? ?? 0;
        if (timeType == 'dynamic' && winStart != null && winEnd != null) {
          final startLabel = startOffset != 0
              ? '$winStart ${startOffset > 0 ? '+' : ''}${startOffset}m'
              : winStart;
          final endLabel = endOffset != 0
              ? '$winEnd ${endOffset > 0 ? '+' : ''}${endOffset}m'
              : winEnd;
          dynamicWindowLabel = '$startLabel → $endLabel';
        }
      }
    }

    final picked = await showModalBottomSheet<ComputedPeriod>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(KitabSpacing.md),
            child: Row(
              children: [
                Text('Choose Period', style: KitabTypography.h3),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          // Unlink option
          ListTile(
            leading: const Icon(Icons.link_off, color: KitabColors.gray400),
            title: const Text('No period (unlink)'),
            onTap: () {
              Navigator.pop(ctx);
              setState(() {
                _linkedPeriodStart = null;
                _linkedPeriodEnd = null;
                _linkType = null;
                _markDirty();
              });
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: periodsWithCounts.length,
              itemBuilder: (_, index) {
                final item = periodsWithCounts[index];
                final period = item.period;
                final count = item.entryCount;
                final isToday = _isToday(period.start);
                final isLinked = _linkedPeriodStart == period.start && _linkedPeriodEnd == period.end;
                final fmt = ref.watch(dateFormatterProvider);
                final dateLabel = isToday ? 'Today' : fmt.shortDateWithDayName(period.start);

                // Show dynamic names for all periods, with actual times for today
                String timeLabel;
                if (dynamicWindowLabel != null) {
                  timeLabel = dynamicWindowLabel;
                  if (isToday) {
                    timeLabel += ' (${fmt.time(period.start)} — ${fmt.time(period.end)})';
                  }
                } else {
                  timeLabel = '${fmt.time(period.start)} — ${fmt.time(period.end)}';
                }

                final countLabel = count == 0 ? 'No entries' : '$count ${count == 1 ? 'entry' : 'entries'}';

                return ListTile(
                  leading: Icon(
                    isLinked ? Icons.check_circle : (count > 0 ? Icons.check_circle_outline : Icons.radio_button_unchecked),
                    color: isLinked ? KitabColors.primary : (count > 0 ? KitabColors.success : KitabColors.gray400),
                    size: 20,
                  ),
                  title: Text('$dateLabel: $timeLabel', style: KitabTypography.bodySmall.copyWith(
                    fontWeight: isLinked ? FontWeight.w600 : FontWeight.w400,
                    color: isToday ? KitabColors.primary : null,
                  )),
                  subtitle: Text(countLabel, style: KitabTypography.caption.copyWith(
                    color: count > 0 ? KitabColors.success : KitabColors.gray400,
                  )),
                  selected: isLinked,
                  onTap: () => Navigator.pop(ctx, period),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _linkedPeriodStart = picked.start;
        _linkedPeriodEnd = picked.end;
        _linkType = 'explicit';
        _markDirty();
      });
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // ─── Save ───
  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final activity = _selectedActivity;
      final existing = widget.existingEntry;
      final name = _nameController.text.trim().isEmpty ? 'Untitled' : _nameController.text.trim();

      // Collect field values
      final fieldValues = <String, dynamic>{};
      for (final e in _fieldControllers.entries) {
        final text = e.value.text.trim();
        if (text.isNotEmpty) {
          final asNum = num.tryParse(text);
          fieldValues[e.key] = asNum ?? text;
        }
      }

      // Time & Duration preset values
      if (_showTimeDuration) {
        if (_startTimeTz != null) {
          fieldValues['start_time'] = _startTimeTz!.dateTime.toIso8601String();
          fieldValues['start_time_tz'] = _startTimeTz!.tzLabel;
        }
        if (_endTimeTz != null) {
          fieldValues['end_time'] = _endTimeTz!.dateTime.toIso8601String();
          fieldValues['end_time_tz'] = _endTimeTz!.tzLabel;
        }
        if (_startTimeTz != null && _endTimeTz != null) {
          final duration = _endTimeTz!.dateTime.difference(_startTimeTz!.dateTime);
          fieldValues['duration_minutes'] = duration.inMinutes;
          fieldValues['duration_seconds'] = duration.inSeconds;
          fieldValues['duration'] = duration.inSeconds;
        }
      }

      // Schedule context fields
      if (_expectedStart != null) {
        fieldValues['expected_start'] = _expectedStart!.toIso8601String();
      }
      if (_expectedEnd != null) {
        fieldValues['expected_end'] = _expectedEnd!.toIso8601String();
      }

      // Activity location fields
      if (_activityLocationLat != null && _activityLocationLng != null) {
        fieldValues['activity_location_lat'] = _activityLocationLat;
        fieldValues['activity_location_lng'] = _activityLocationLng;
        fieldValues['activity_location_name'] = _activityLocationName;
      }

      // Ad-hoc fields
      for (final f in _adHocFields) {
        final text = f.controller.text.trim();
        if (text.isNotEmpty) {
          final label = f.labelController.text.trim().isEmpty ? f.label : f.labelController.text.trim();
          final asNum = num.tryParse(text);
          fieldValues['adhoc_${f.id}'] = {
            'label': label,
            'type': f.typeKey,
            'value': asNum ?? text,
          };
        }
      }

      final entry = Entry(
        id: existing?.id ?? _uuid.v4(),
        userId: ref.read(currentUserIdProvider),
        name: name,
        activityId: activity?.id,
        periodStart: existing?.periodStart ?? _linkedPeriodStart,
        periodEnd: existing?.periodEnd ?? _linkedPeriodEnd,
        linkType: existing?.linkType ?? _linkType,
        fieldValues: fieldValues,
        timerSegments: existing?.timerSegments,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        routineEntryId: existing?.routineEntryId,
        source: existing?.source,
        externalId: existing?.externalId,
        loggedAt: _loggedAtTz.dateTime,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await ref.read(entryRepositoryProvider).save(entry);
      refreshAllEntryProviders(ref);
      _hasUnsavedChanges = false;
      widget.onDirtyChanged?.call(false);

      if (mounted) {
        if (widget.embedded) {
          widget.onSaved?.call();
        } else {
          Navigator.pop(context);
        }
        KitabToast.success(context, _isEditing ? 'Entry updated' : 'Entry logged');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Delete ───
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This entry will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KitabColors.error),
            onPressed: () async {
              await ref.read(entryRepositoryProvider).delete(widget.existingEntry!.id);
              refreshAllEntryProviders(ref);
              if (mounted) {
                Navigator.pop(ctx);
                if (widget.embedded) {
                  widget.onDeleted?.call();
                } else {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Discard ───
}

/// An ad-hoc field added by the user in the expanded form.
class _AdHocField {
  final String id;
  final String label;
  final String typeKey;
  final TextEditingController controller;
  final TextEditingController labelController;

  _AdHocField({required this.label, required this.typeKey})
      : id = _uuid.v4(),
        controller = TextEditingController(),
        labelController = TextEditingController(text: label);
}
