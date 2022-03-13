import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sudokuai/scanner/native_sudoku_scanner_bridge.dart';

/// A widget that only displays the extracted sudoku grid (not interactable).
class SudokuView extends StatelessWidget {
  final List<int> sudokuGrid;

  const SudokuView({Key? key, required this.sudokuGrid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sudoku')),
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
                    left: (colNum == 0)
                        ? BorderSide(
                            width: 3.0,
                          )
                        : BorderSide.none,
                    right: BorderSide(
                      width: (colNum % 3 == 2 || colNum == 8) ? 3.0 : 1.0,
                    ),
                    top: (rowNum == 0)
                        ? BorderSide(
                            width: 3.0,
                          )
                        : BorderSide.none,
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
