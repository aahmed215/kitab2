// ═══════════════════════════════════════════════════════════════════
// USER_CHART.DART — Custom Chart Data Model
// User-created charts for the Insights screen's "My Charts" tab.
// Maps to the `user_charts` table in Supabase.
// See SPEC.md §14.5 for chart builder specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_chart.freezed.dart';
part 'user_chart.g.dart';

/// A user-created custom chart configuration.
@freezed
class UserChart with _$UserChart {
  const factory UserChart({
    required String id,
    required String userId,

    /// User-given chart name
    required String name,

    /// Chart type: 'kpi_number', 'line', 'vertical_bar', 'horizontal_bar',
    /// 'pie', 'heat_map', 'progress_ring', 'table'
    required String chartType,

    /// Data source: 'activity', 'routine', 'category',
    /// 'all_activities', 'all_routines', 'conditions'
    required String dataSourceType,

    /// Specific activity/routine ID (null for aggregate sources)
    String? dataSourceId,

    /// What's being measured
    required String measure,

    /// Specific field ID if measuring a field value
    String? measureFieldId,

    /// Aggregation: 'sum', 'average', 'min', 'max', 'count', 'latest'
    @Default('count') String calculation,

    /// Grouping: 'daily', 'weekly', 'monthly', 'yearly',
    /// 'day_of_week', 'time_of_day', 'category', 'activity'
    @Default('daily') String groupBy,

    /// Period: 'this_week', 'this_month', 'last_30', 'last_3m',
    /// 'last_6m', 'this_year', 'all_time', 'custom', etc.
    @Default('this_month') String periodType,

    /// Custom period start (null unless periodType = 'custom')
    DateTime? periodStart,
    DateTime? periodEnd,

    /// For Ramadan comparison periods
    int? periodHijriYear,

    /// Whether condition periods are overlaid on the chart
    @Default(false) bool showConditions,

    /// Whether this chart is pinned to favorites
    @Default(false) bool isFavorite,

    /// Display order in My Charts list
    @Default(0) int sortOrder,

    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _UserChart;

  factory UserChart.fromJson(Map<String, dynamic> json) =>
      _$UserChartFromJson(json);
}
