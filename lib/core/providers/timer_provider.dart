// ═══════════════════════════════════════════════════════════════════
// TIMER_PROVIDER.DART — Global Timer State Management
// Manages up to 3 concurrent timers that persist across screens.
// Timer state lives in Riverpod, not in widget state.
// See SPEC.md §7.3 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const _maxTimers = 3;

/// A single timer instance.
class TimerState {
  final String id;
  String activityName;
  String? activityId;

  final DateTime startTime;
  final List<Map<String, String>> segments;
  DateTime? currentSegmentStart;

  bool isRunning;
  Duration elapsed;

  TimerState({
    String? id,
    this.activityName = 'Untitled',
    this.activityId,
    DateTime? startTime,
    List<Map<String, String>>? segments,
    this.currentSegmentStart,
    this.isRunning = true,
    this.elapsed = Duration.zero,
  })  : id = id ?? _uuid.v4(),
        startTime = startTime ?? DateTime.now(),
        segments = segments ?? [];

  /// Total active duration across all completed segments.
  Duration get activeDuration {
    var total = Duration.zero;
    for (final seg in segments) {
      final start = DateTime.parse(seg['start']!);
      final end = DateTime.parse(seg['end']!);
      total += end.difference(start);
    }
    // Add current running segment
    if (isRunning && currentSegmentStart != null) {
      total += DateTime.now().difference(currentSegmentStart!);
    }
    return total;
  }

  TimerState copyWith({
    String? activityName,
    String? activityId,
    bool? isRunning,
    Duration? elapsed,
    DateTime? currentSegmentStart,
  }) {
    return TimerState(
      id: id,
      activityName: activityName ?? this.activityName,
      activityId: activityId ?? this.activityId,
      startTime: startTime,
      segments: segments,
      currentSegmentStart: currentSegmentStart ?? this.currentSegmentStart,
      isRunning: isRunning ?? this.isRunning,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

/// Manages all active timers globally.
class ActiveTimersNotifier extends StateNotifier<List<TimerState>> {
  Timer? _ticker;

  ActiveTimersNotifier() : super([]);

  /// Start a new timer. Returns the timer ID, or null if max reached.
  String? startTimer() {
    if (state.length >= _maxTimers) return null;

    final now = DateTime.now();
    final timer = TimerState(
      startTime: now,
      currentSegmentStart: now,
    );

    state = [...state, timer];
    _ensureTicker();
    return timer.id;
  }

  /// Update activity info for a timer.
  void setActivity(String timerId, {required String name, String? activityId}) {
    state = [
      for (final t in state)
        if (t.id == timerId) ...[t..activityName = name..activityId = activityId]
        else t,
    ];
  }

  /// Pause a timer (ends current segment).
  void pause(String timerId) {
    state = [
      for (final t in state)
        if (t.id == timerId)
          _pauseTimer(t)
        else
          t,
    ];
  }

  TimerState _pauseTimer(TimerState t) {
    if (t.isRunning && t.currentSegmentStart != null) {
      t.segments.add({
        'start': t.currentSegmentStart!.toUtc().toIso8601String(),
        'end': DateTime.now().toUtc().toIso8601String(),
      });
    }
    return t.copyWith(
      isRunning: false,
      currentSegmentStart: null,
    );
  }

  /// Resume a paused timer (starts new segment).
  void resume(String timerId) {
    state = [
      for (final t in state)
        if (t.id == timerId)
          t.copyWith(isRunning: true, currentSegmentStart: DateTime.now())
        else
          t,
    ];
  }

  /// Toggle pause/resume.
  void togglePause(String timerId) {
    final timer = state.where((t) => t.id == timerId).firstOrNull;
    if (timer == null) return;
    if (timer.isRunning) {
      pause(timerId);
    } else {
      resume(timerId);
    }
  }

  /// Stop a timer (closes final segment, removes from active list).
  /// Returns the final TimerState for saving.
  TimerState? stop(String timerId) {
    final timer = state.where((t) => t.id == timerId).firstOrNull;
    if (timer == null) return null;

    // Close final segment if running
    final stopped = _pauseTimer(timer);
    stopped.isRunning = false;

    // Remove from active list
    state = state.where((t) => t.id != timerId).toList();
    if (state.isEmpty) _stopTicker();

    return stopped;
  }

  /// Discard a timer without saving.
  void discard(String timerId) {
    state = state.where((t) => t.id != timerId).toList();
    if (state.isEmpty) _stopTicker();
  }

  /// Adjust the start time of a running timer.
  void adjustStartTime(String timerId, DateTime newStart) {
    state = [
      for (final t in state)
        if (t.id == timerId)
          TimerState(
            id: t.id,
            activityName: t.activityName,
            activityId: t.activityId,
            startTime: newStart,
            segments: t.segments,
            currentSegmentStart: t.currentSegmentStart,
            isRunning: t.isRunning,
            elapsed: Duration.zero, // Will be recomputed by _tick
          )
        else
          t,
    ];
  }

  /// Get a specific timer by ID.
  TimerState? getTimer(String timerId) {
    return state.where((t) => t.id == timerId).firstOrNull;
  }

  /// Called every second to update active elapsed times.
  void _tick() {
    state = [
      for (final t in state)
        t.copyWith(elapsed: t.activeDuration),
    ];
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}

/// Global provider for active timers.
final activeTimersProvider =
    StateNotifierProvider<ActiveTimersNotifier, List<TimerState>>((ref) {
  return ActiveTimersNotifier();
});
