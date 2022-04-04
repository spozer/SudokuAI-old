import 'dart:io';
import 'dart:ui';
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
  late Future<BoundingBox> boundingBox;
  final GlobalKey _imageWidgetKey = GlobalKey();

  @override
  void initState() {
    boundingBox = SudokuScanner.detectGrid(widget.imagePath);
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
            Container(
              color: Colors.black,
              child: Center(
                child: Stack(children: <Widget>[
                  _getImage(),
                  _getBoundingBox(),
                ]),
              ),
            ),
            _getButtonBar(),
          ],
        ),
      ),
    );
  }

  Widget _getImage() {
    return Image.file(
      File(widget.imagePath),
      key: _imageWidgetKey,
    );
  }

  Widget _getBoundingBox() {
    return FutureBuilder(
      future: boundingBox,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final keyContext = _imageWidgetKey.currentContext;

          if (keyContext == null) {
            return const SizedBox();
          }

          final imageSize = (keyContext.findRenderObject() as RenderBox).size;
          final boundingBox = snapshot.data as BoundingBox;

          return CustomPaint(
            painter: EdgePainter(
              points: boundingBox.asPoints(imageSize),
              color: const Color.fromARGB(255, 43, 188, 255),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _getButtonBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ElevatedButton(
        onPressed: () async {
          final valueList = SudokuScanner.extractGrid(widget.imagePath, await boundingBox);
          widget.showSudoku(valueList);
        },
        style: ElevatedButton.styleFrom(
          elevation: 5,
          primary: const Color.fromARGB(255, 102, 102, 102),
          shadowColor: Colors.black,
        ),
        child: FutureBuilder(
          future: boundingBox,
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
}

class EdgePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  EdgePainter({
    required this.points,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawPoints(PointMode.polygon, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
