import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sudokuai/scanner/native_sudoku_scanner_bridge.dart';

class SudokuView extends StatefulWidget {
  final List<int> sudokuGrid;

  const SudokuView({Key? key, required this.sudokuGrid}) : super(key: key);

  @override
  State<SudokuView> createState() => _SudokuViewState();
}

/// A widget that only displays the extracted sudoku grid (not interactable).
class _SudokuViewState extends State<SudokuView> {
  late List<SudokuGridItem> sudokuGrid;
  int? selectedId;

  @override
  void initState() {
    super.initState();

    // Create Sudoku grid.
    sudokuGrid = widget.sudokuGrid.mapIndexed((index, element) {
      int colNum = index % 9;
      int rowNum = index ~/ 9;

      return SudokuGridItem(
        index,
        rowNum,
        colNum,
        value: element,
        isModifiable: (element == 0),
      );
    }).toList();
  }

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

  /// Get background color of grid item based on the currently selected
  /// grid item.
  Color _getColor(SudokuGridItem item) {
    const defaultBackground = Colors.transparent;
    const selectedBackground = Color.fromARGB(100, 43, 188, 255);
    const affectedBackground = Color.fromARGB(100, 150, 150, 150);
    const sameValueBackground = Color.fromARGB(100, 200, 0, 0);

    // Nothing selected yet.
    if (selectedId == null) {
      return defaultBackground;
    }

    // The selected item.
    if (selectedId == item.id) {
      return selectedBackground;
    }

    // Highlight all items that have same value as currently selected item.
    if (item.value == sudokuGrid[selectedId!].value && item.value != 0) {
      return sameValueBackground;
    }

    // Highlight all items that either are it the same row, column or box of
    // currently selected item.
    if (item.isAffectedBy(sudokuGrid[selectedId!])) {
      return affectedBackground;
    }

    return defaultBackground;
  }

  /// Creates the Sudoku grid widget.
  Widget _getSudokuGrid() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(),
        ),
        child: GridView.count(
          shrinkWrap: true,
          primary: false,
          addAutomaticKeepAlives: false,
          crossAxisCount: 9,
          children: sudokuGrid.map((element) {
            final id = element.id;
            final row = element.row;
            final col = element.col;
            final isModifiable = element.isModifiable;
            final value = element.value;

            return GestureDetector(
              onTap: () {
                if (mounted) {
                  setState(() {
                    selectedId = id;
                  });
                }
              },
              child: Container(
                  decoration: BoxDecoration(
                    color: _getColor(element),
                    border: Border(
                      left: (col == 0) ? const BorderSide(width: 3.0) : BorderSide.none,
                      right: BorderSide(
                        width: (col % 3 == 2 || col == 8) ? 3.0 : 0.5,
                      ),
                      top: (row == 0) ? const BorderSide(width: 3.0) : BorderSide.none,
                      bottom: BorderSide(
                        width: (row % 3 == 2 || row == 8) ? 3.0 : 0.5,
                      ),
                    ),
                  ),
                  child: (value != 0)
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            value.toString(),
                            style: TextStyle(color: isModifiable ? Colors.blue[900] : Colors.black),
                          ),
                        )
                      : null),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Creates the number keyboard.
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
                if (selectedId != null) {
                  if (mounted) {
                    setState(() {
                      sudokuGrid[selectedId!].value = value;
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

/// Defines a Sudoku grid item.
///
/// Holds [id], [row, col] and [value].
class SudokuGridItem {
  final int _id;
  final int _row;
  final int _col;
  final bool _isModifiable;
  int _value;

  SudokuGridItem(this._id, this._row, this._col, {value = 0, isModifiable = true})
      : _value = value,
        _isModifiable = isModifiable;

  bool isAffectedBy(SudokuGridItem item) {
    bool inRow = (_row == item.row);
    bool inCol = (_col == item.col);
    bool inBox = (_col ~/ 3 == item.col ~/ 3 && _row ~/ 3 == item.row ~/ 3);

    return (inRow || inCol || inBox);
  }

  int get id {
    return _id;
  }

  int get row {
    return _row;
  }

  int get col {
    return _col;
  }

  bool get isModifiable {
    return _isModifiable;
  }

  int get value {
    return _value;
  }

  set value(int value) {
    if (isModifiable) _value = value;
  }
}
