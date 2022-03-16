import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:sudokuai/scanner/native_sudoku_scanner_bridge.dart';

class SudokuView extends StatefulWidget {
  final List<int> sudokuGrid;

  const SudokuView({Key? key, required this.sudokuGrid}) : super(key: key);

  @override
  State<SudokuView> createState() => _SudokuViewState();
}

/// A widget that only displays the extracted sudoku grid (not interactable).
class _SudokuViewState extends State<SudokuView> {
  final defaultBackgroundColor = Colors.transparent;
  final highlightBackgroundColor = Color.fromARGB(29, 3, 168, 244);
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: Stack(
        children: <Widget>[
          _getSudokuGrid(),
          _getNumberKeyboard(),
        ],
      ),
    );
  }

  Widget _getSudokuGrid() {
    return GridView.count(
      padding: const EdgeInsets.all(15.0),
      shrinkWrap: true,
      primary: false,
      addAutomaticKeepAlives: false,
      crossAxisCount: 9,
      children: widget.sudokuGrid.mapIndexed((index, item) {
        int colNum = index % 9;
        int rowNum = index ~/ 9;
        return GestureDetector(
          onTap: () {
            if (mounted) {
              setState(() {
                selectedIndex = index;
                // widget.sudokuGrid[index] = item + 1;
              });
            }
          },
          child: Container(
              decoration: BoxDecoration(
                color: (selectedIndex == index) ? highlightBackgroundColor : defaultBackgroundColor,
                border: Border(
                  left: (colNum == 0) ? const BorderSide(width: 3.0) : BorderSide.none,
                  right: BorderSide(
                    width: (colNum % 3 == 2 || colNum == 8) ? 3.0 : 1.0,
                  ),
                  top: (rowNum == 0) ? const BorderSide(width: 3.0) : BorderSide.none,
                  bottom: BorderSide(
                    width: (rowNum % 3 == 2 || rowNum == 8) ? 3.0 : 1.0,
                  ),
                ),
              ),
              child: (item != 0)
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: Text(item.toString()),
                    )
                  : null),
        );
      }).toList(),
    );
  }

  Widget _getNumberKeyboard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GridView.count(
          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
          shrinkWrap: true,
          primary: false,
          addAutomaticKeepAlives: false,
          crossAxisCount: 9,
          children: List.generate(9, (index) {
            int value = index + 1;
            return GestureDetector(
              onTap: () {
                if (selectedIndex != null) {
                  if (mounted) {
                    setState(() {
                      widget.sudokuGrid[selectedIndex!] = value;
                    });
                  }
                }
              },
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(value.toString()),
              ),
            );
          }),
        ),
      ),
    );
  }
}
