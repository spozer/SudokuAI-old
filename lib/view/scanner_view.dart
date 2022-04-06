import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../scanner/sudoku_scanner.dart';
import '../scanner/bounding_box.dart';

class ScannerView extends StatefulWidget {
  final String imagePath;
  final void Function(Future<List<int>> sudokuGrid) showSudoku;
  final void Function() onBack;

  const ScannerView({
    Key? key,
    required this.imagePath,
    required this.showSudoku,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  late Future<void> boundingBoxFuture;
  late Future<ui.Image> imageFuture;

  List<Offset> points = [];
  Size? previewSize;
  Offset previewOffset = const Offset(0, 0);

  @override
  void initState() {
    imageFuture = _getUiImage(widget.imagePath);

    boundingBoxFuture = SudokuScanner.detectGrid(widget.imagePath).then((boundingBox) async {
      final image = await imageFuture;
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final screenSize = MediaQuery.of(context).size;

      double screenAspectRatio = screenSize.height / screenSize.width;
      double imageAspectRatio = imageSize.height / imageSize.width;
      bool fitHeight = (imageAspectRatio > screenAspectRatio);

      final previewWidth = fitHeight ? screenSize.height / imageAspectRatio : screenSize.width;
      final previewHeight = fitHeight ? screenSize.height : screenSize.width * imageAspectRatio;

      previewSize = Size(previewWidth, previewHeight);

      // Adjust for image location.
      previewOffset = Offset(
        (screenSize.width - previewWidth) / 2,
        (screenSize.height - previewHeight) / 2,
      );

      final relativePoints = boundingBox.toPoints(previewSize!);

      // Absolut locations.
      points = List.generate(
        relativePoints.length,
        (index) => relativePoints[index] + previewOffset,
      );
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onBack();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            _getImage(),
            _getBoundingBox(),
            _getButtonBar(),
          ],
        ),
      ),
    );
  }

  Widget _getImage() {
    return FutureBuilder(
      future: imageFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return RawImage(
            image: snapshot.data as ui.Image,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          );
        } else {
          return const Center(
            child: Text("Loading Picture..."),
          );
        }
      },
    );
  }

  Widget _getBoundingBox() {
    return FutureBuilder(
      future: boundingBoxFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (points.isEmpty) {
            return const SizedBox();
          }

          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: <Widget>[
                _getTouchBubble(0),
                _getTouchBubble(1),
                _getTouchBubble(2),
                _getTouchBubble(3),
                CustomPaint(
                  painter: EdgePainter(
                    points: points,
                    color: const Color.fromARGB(255, 43, 188, 255),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _getTouchBubble(int id) {
    assert(id < points.length);

    double bubbleSize = 25.0;
    return Positioned(
      top: points[id].dy - (bubbleSize / 2),
      left: points[id].dx - (bubbleSize / 2),
      child: TouchBubble(
        id: id,
        size: bubbleSize,
        onDraggingStarted: _onDraggingStarted,
        onDrag: _onDrag,
        onDraggingStopped: _onDraggingStopped,
      ),
    );
  }

  Widget _getButtonBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ElevatedButton(
        onPressed: () async {
          if (points.isEmpty || previewSize == null) return;

          final relativePoints = List.generate(
            points.length,
            (index) => points[index] - previewOffset,
          );

          final boundingBox = BoundingBox.fromPoints(relativePoints, previewSize!);
          final valueList = SudokuScanner.extractGrid(widget.imagePath, boundingBox);

          widget.showSudoku(valueList);
        },
        style: ElevatedButton.styleFrom(
          elevation: 5,
          primary: const Color.fromARGB(255, 102, 102, 102),
          shadowColor: Colors.black,
        ),
        child: FutureBuilder(
          future: boundingBoxFuture,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return const Icon(Icons.check);
            } else {
              return const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Offset _clampPosition(Offset position) {
    if (previewSize == null) return position;
    double clampX = position.dx.clamp(previewOffset.dx, previewSize!.width + previewOffset.dx);
    double clampY = position.dy.clamp(previewOffset.dy, previewSize!.height + previewOffset.dy);
    return Offset(clampX, clampY);
  }

  void _onDraggingStarted(int id, Offset newPosition) {
    setState(() {
      points[id] = _clampPosition(newPosition);
    });
  }

  void _onDrag(int id, Offset newPosition) {
    setState(() {
      points[id] = _clampPosition(newPosition);
    });
  }

  void _onDraggingStopped() {
    setState(() {});
  }

  Future<ui.Image> _getUiImage(String imagePath) {
    return File(imagePath).readAsBytes().then(decodeImageFromList);
  }
}

class EdgePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  EdgePainter({
    required List<Offset> points,
    required this.color,
  }) : points = [points[0], points[1], points[3], points[2], points[0]];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawPoints(ui.PointMode.polygon, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class TouchBubble extends StatelessWidget {
  final int id;
  final double size;
  final void Function(int, Offset) onDraggingStarted;
  final void Function(int, Offset) onDrag;
  final void Function() onDraggingStopped;

  const TouchBubble({
    Key? key,
    required this.id,
    required this.size,
    required this.onDraggingStarted,
    required this.onDrag,
    required this.onDraggingStopped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => onDraggingStarted(id, details.globalPosition),
      onPanUpdate: (details) => onDrag(id, details.globalPosition),
      onPanCancel: onDraggingStopped,
      onPanEnd: (_) => onDraggingStopped(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 43, 188, 255).withOpacity(0.5),
          borderRadius: BorderRadius.circular(size / 2),
        ),
      ),
    );
  }
}
