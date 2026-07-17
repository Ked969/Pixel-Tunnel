import 'package:flutter/material.dart';
import 'models/stroke.dart';
import 'painter.dart';
import 'cloud_manager.dart';
import 'color_picker_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff1A1C1E),
      ),
      home: const DrawingBoard(),
    );
  }
}

class DrawingBoard extends StatefulWidget {
  const DrawingBoard({super.key});

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  final List<Stroke> _strokes = [];
  List<Offset> _currentPoints = [];
  String _selectedColorHex = '#FF0000';
  double _selectedWidth = 5.0;
  bool _isEraserMode = false;

  @override
  void initState() {
    super.initState();
    _initCloud();
  }

  void _initCloud() async {
    await CloudManager().init();
    CloudManager().onStrokeReceived = (incomingStroke) {
      setState(() {
        _strokes.add(incomingStroke);
      });
    };
  }

  void _handleColorSelection(double localX, double maxWidth) {
    double percent = localX / maxWidth;
    percent = percent.clamp(0.0, 1.0);
    
    final List<double> stops = [0.0, 1/6, 2/6, 3/6, 4/6, 5/6, 1.0];
    final List<Color> colors = const [
      Color(0xFFFF0000),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF0000),
    ];

    if (percent <= 0) {
      _updateColor(colors.first);
      return;
    }
    if (percent >= 1) {
      _updateColor(colors.last);
      return;
    }

    int index = 0;
    for (int i = 0; i < stops.length - 1; i++) {
      if (percent >= stops[i] && percent <= stops[i + 1]) {
        index = i;
        break;
      }
    }

    double t = (percent - stops[index]) / (stops[index + 1] - stops[index]);
    Color pickedColor = Color.lerp(colors[index], colors[index + 1], t)!;
    _updateColor(pickedColor);
  }

  void _updateColor(Color color) {
    String hex = '#${color.value.toRadixString(16).substring(2, 8).toUpperCase()}';
    setState(() {
      _selectedColorHex = hex;
      _isEraserMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentPoints = [details.localPosition];
                _strokes.add(Stroke(
                  points: List.from(_currentPoints),
                  colorHex: _selectedColorHex,
                  width: _selectedWidth,
                  isEraser: _isEraserMode,
                ));
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentPoints.add(details.localPosition);
                _strokes.last = Stroke(
                  points: List.from(_currentPoints),
                  colorHex: _selectedColorHex,
                  width: _selectedWidth,
                  isEraser: _isEraserMode,
                );
              });
            },
            onPanEnd: (details) async {
              if (_strokes.isNotEmpty) {
                final finishedStroke = _strokes.last;
                CloudManager().sendStroke(finishedStroke);
              }
              setState(() {
                _currentPoints = [];
              });
            },
            child: CustomPaint(
              painter: CanvasPainter(_strokes),
              size: Size.infinite,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: SafeArea(
              child: Card(
                color: Colors.grey[900]?.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isEraserMode ? Colors.transparent : HexColor.fromHex(_selectedColorHex),
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                            child: _isEraserMode ? const Icon(Icons.cleaning_services, size: 16) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  onPanUpdate: (details) => _handleColorSelection(details.localPosition.dx, constraints.maxWidth),
                                  onTapDown: (details) => _handleColorSelection(details.localPosition.dx, constraints.maxWidth),
                                  child: const SizedBox(
                                    height: 20,
                                    child: CustomPaint(
                                      painter: ColorPickerPainter(),
                                      child: SizedBox.expand(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              _isEraserMode ? Icons.brush : Icons.cleaning_services,
                              color: _isEraserMode ? Colors.cyan : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEraserMode = !_isEraserMode;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 20),
                      Row(
                        children: [
                          const Icon(Icons.line_weight, size: 18, color: Colors.white54),
                          Expanded(
                            child: Slider(
                              value: _selectedWidth,
                              min: 1.0,
                              max: 50.0,
                              activeColor: _isEraserMode ? Colors.cyan : HexColor.fromHex(_selectedColorHex),
                              inactiveColor: Colors.white12,
                              onChanged: (value) {
                                setState(() {
                                  _selectedWidth = value;
                                });
                              },
                            ),
                          ),
                          Text(
                            "${_selectedWidth.toStringAsFixed(0)}px",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
