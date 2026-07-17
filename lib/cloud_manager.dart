import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/stroke.dart';

class CloudManager {
  static final CloudManager _instance = CloudManager._internal();
  factory CloudManager() => _instance;
  CloudManager._internal();

  final String _databaseUrl = "https://ked969-ehe-default-rtdb.europe-west1.firebasedatabase.app/";

  String myId = "2";
  String friendId = "1";

  Function(Stroke)? onStrokeReceived;
  StreamSubscription? _streamSubscription;
  final http.Client _client = http.Client();

  Future<void> init() async {
    _startListening();
  }

  void _startListening() {
    _streamSubscription?.cancel();

    final url = Uri.parse("$_databaseUrl/tunnel/strokes/$friendId.json");
    final request = http.Request("GET", url)
      ..headers["Accept"] = "text/event-stream";

    _client.send(request).then((response) {
      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith("data:")) {
          final dataString = line.substring(5).trim();
          if (dataString.isEmpty || dataString == "null") return;

          try {
            final parsed = jsonDecode(dataString);
            if (parsed is Map && parsed.containsKey("data")) {
              final actualData = parsed["data"];
              if (actualData == null) return;
              
              if (actualData is Map && actualData.containsKey("points")) {
                _triggerStroke(actualData);
              } else if (actualData is Map) {
                actualData.forEach((key, value) {
                  if (value is Map && value.containsKey("points")) {
                    _triggerStroke(value);
                  }
                });
              }
            }
          } catch (_) {}
        }
      }, onError: (_) {
        Future.delayed(const Duration(seconds: 5), () => _startListening());
      }, onDone: () {
        Future.delayed(const Duration(seconds: 2), () => _startListening());
      });
    }).catchError((_) {
      Future.delayed(const Duration(seconds: 5), () => _startListening());
    });
  }

  void _triggerStroke(Map<dynamic, dynamic> strokeMap) {
    try {
      final stroke = Stroke.fromJson(Map<String, dynamic>.from(strokeMap));
      if (onStrokeReceived != null) {
        onStrokeReceived!(stroke);
      }
    } catch (_) {}
  }

  Future<void> sendStroke(Stroke stroke) async {
    final url = Uri.parse("$_databaseUrl/tunnel/strokes/$myId.json");
    try {
      await http.post(
        url,
        body: jsonEncode(stroke.toJson()),
      );
      _enforceLimit();
    } catch (_) {}
  }

  Future<void> _enforceLimit() async {
    final url = Uri.parse("$_databaseUrl/tunnel/strokes/$myId.json");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != "null") {
        final Map<String, dynamic> currentStrokes = jsonDecode(response.body);
        if (currentStrokes.length > 1024) {
          List<String> sortedKeys = currentStrokes.keys.toList()..sort();
          int overflowCount = sortedKeys.length - 1024;
          for (int i = 0; i < overflowCount; i++) {
            final deleteUrl = Uri.parse("$_databaseUrl/tunnel/strokes/$myId/${sortedKeys[i]}.json");
            await http.delete(deleteUrl);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> clearAllCloudData() async {
    final url = Uri.parse("$_databaseUrl/tunnel/strokes.json");
    try {
      await http.delete(url);
    } catch (_) {}
  }

  void dispose() {
    _streamSubscription?.cancel();
    _client.close();
  }
}
