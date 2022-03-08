import 'package:flutter/material.dart';
import 'package:sudokuai/scanner/native_sudoku_scanner_bridge.dart';
import 'dart:io';

// A widget that only displays the extracted sudoku grid (can't interact).
class SudokuView extends StatelessWidget {
  final List<int> sudokuGrid;

  const SudokuView({Key? key, required this.sudokuGrid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // run debug grid detection from sudoku scanner
    // NativeSudokuScannerBridge.debugGridDetection(imagePath);

    return Scaffold(
      appBar: AppBar(title: Text('Sudoku')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
        child: _getSudokuGrid(),
      ),
    );
  }

  Widget _getSudokuGrid() {
    int ctr = 0;
    return Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 9,
          children: sudokuGrid.map((item) {
            int colNum = ctr % 9;
            int rowNum = ctr ~/ 9;
            ctr++;
            return Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: (colNum == 0) ? 3.0 : 0.0,
                    ),
                    right: BorderSide(
                      width: (colNum % 3 == 2 || colNum == 8) ? 3.0 : 1.0,
                    ),
                    top: BorderSide(
                      width: (rowNum == 0) ? 3.0 : 0.0,
                    ),
                    bottom: BorderSide(
                      width: (rowNum % 3 == 2 || rowNum == 8) ? 3.0 : 1.0,
                    ),
                  ),
                ),
                child: (item != 0)
                    ? Center(
                        child: Text(
                        item.toString(),
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ))
                    : null);
          }).toList(),
        ));
  }
}
