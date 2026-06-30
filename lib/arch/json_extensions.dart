/// If failed to parse can return `null` or throw an exception.
typedef MapToObjectParser<T> = T? Function(Map<String, dynamic> data);

/// If failed to parse can return `null` or throw an exception.
typedef StringToObjectParser<T> = T? Function(String value);

extension JsonExceptions on Map<String, dynamic> {
  /// Will get [key] and parse it into [T] using [parse] function.
  T? parseObject<T>(String key, MapToObjectParser<T> parse) {
    final value = this[key];
    if (value == null) return null;
    return parse(value);
  }

  /// Will get [key] and parse it into [T] using [parse] function.
  /// Usually used for parsing enums.
  T? parseEnum<T>(String key, StringToObjectParser<T> parse) {
    final value = this[key];
    if (value == null) return null;
    return parse(value);
  }

  /// Will get [key] list and parse it into list of [T] using [parse] function.
  /// If value behind [key] is `null` will return `null`.
  /// If [parse] function will return `null` will skip this value.
  /// If [parse] function will throw an exception will throw an exception.
  List<T>? parseObjectsList<T>(
    String key,
    MapToObjectParser<T> parse,
  ) {
    final value = this[key];
    if (value == null) return null;
    return (value as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(parse)
        .where((element) => element != null)
        .cast<T>()
        .toList();
  }

  /// Will get [key] list and parse it into list of [String].
  List<String>? parseStringsList<T>(String key) {
    final value = this[key];
    if (value == null) return null;
    return (value as List<dynamic>).cast<String>().toList();
  }

  /// Sometime server can use `1` instead of `true` and `0` instead of `false.
  /// This function will parse both variants into `bool`.
  bool parseBoolInt(String key) {
    final value = this[key];
    if (value is bool) return value;
    if (value is int) return value > 0;
    return false;
  }

  /// For integer value server return `5`. For floating-point number server returns `"4.5"`.
  /// This function will parse both variants into `num`.
  num? parseNum(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.parse(value);
    return null;
  }

  /// Sometimes server can return same data under different keys.
  /// This function will return first key that exists in the map from the list of keys provided.
  String getFirstKeyExists(Iterable<String> keys) {
    for (final key in keys) {
      if (containsKey(key)) {
        return key;
      }
    }
    throw Exception('At least one key should exist in the map: $keys');
  }
}
