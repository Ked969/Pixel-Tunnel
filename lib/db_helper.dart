import 'models/stroke.dart';

class DbHelper {
  static final List<Stroke> _memoryStorage = [];

  static Future<void> database() async {}

  static Future<int> insertStroke(Stroke stroke) async {
    _memoryStorage.add(stroke);
    return _memoryStorage.length;
  }

  static Future<List<Stroke>> getStrokes() async {
    return List.from(_memoryStorage);
  }

  static Future<int> clearAll() async {
    int count = _memoryStorage.length;
    _memoryStorage.clear();
    return count;
  }
}
