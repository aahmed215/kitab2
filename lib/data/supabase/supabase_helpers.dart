// ═══════════════════════════════════════════════════════════════════
// SUPABASE_HELPERS.DART — Snake_case ↔ camelCase Conversion
// Supabase tables use snake_case, Dart models use camelCase.
// These helpers bridge the gap for all Supabase repositories.
// ═══════════════════════════════════════════════════════════════════

/// Convert a camelCase Dart map to snake_case for Supabase insert/update.
Map<String, dynamic> toSnakeCase(Map<String, dynamic> map) {
  return map.map((key, value) {
    final snakeKey = _camelToSnake(key);
    return MapEntry(snakeKey, value);
  });
}

/// Convert a snake_case Supabase row to camelCase for Dart fromJson.
Map<String, dynamic> toCamelCase(Map<String, dynamic> map) {
  return map.map((key, value) {
    final camelKey = _snakeToCamel(key);
    return MapEntry(camelKey, value);
  });
}

/// Convert a list of Supabase rows to camelCase.
List<Map<String, dynamic>> toCamelCaseList(List<dynamic> rows) {
  return rows
      .map((row) => toCamelCase(Map<String, dynamic>.from(row as Map)))
      .toList();
}

String _camelToSnake(String input) {
  return input.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

String _snakeToCamel(String input) {
  return input.replaceAllMapped(
    RegExp(r'_([a-z])'),
    (match) => match.group(1)!.toUpperCase(),
  );
}
