import 'dart:io';
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
  late Future<BoundingBox> boundingBoxFuture;

  @override
  void initState() {
    boundingBoxFuture = SudokuScanner.detectGrid(widget.imagePath);
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
    return Container(
      color: Colors.black,
      child: Center(
        child: Image.file(File(widget.imagePath)),
      ),
    );
  }

  Widget _getBoundingBox() {
    return FutureBuilder(
      future: boundingBoxFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Container();
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _getButtonBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ElevatedButton(
        onPressed: () async {
          final valueList = SudokuScanner.extractGrid(widget.imagePath, await boundingBoxFuture);
          widget.showSudoku(valueList);
        },
        child: const Icon(Icons.navigate_next),
      ),
    );
  }
}
