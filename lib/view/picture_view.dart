import 'package:flutter/material.dart';
import 'package:sudokuai/scanner/native_sudoku_scanner_bridge.dart';
import 'dart:io';

// A widget that displays the picture taken by the user.
// TODO: rename
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // run debug grid detection from sudoku scanner
    // NativeSudokuScannerBridge.debugGridDetection(imagePath);

    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
        child: Image.file(
          File(imagePath),
        ),
      ),
    );
  }
}
