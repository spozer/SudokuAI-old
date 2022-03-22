import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'camera_view.dart';

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
    // Get screen height and width (in logical pixels).
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // Define widget sizes which are scaled by the screen size.
    final topBarHeight = screenHeight * 0.06;
    final topBarWidth = screenWidth * 0.95;
    final topBarOffset = screenHeight * 0.01;
    final sudokuGridOffset = 2 * topBarOffset + topBarHeight;
    final sudokuGridSize = screenWidth * 0.95;
    final numberKeyboardSize = screenWidth * 0.5;
    final numberKeyboardOffset = screenHeight * 0.05;

    return WillPopScope(
      // Disable back button.
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            _getTopBar(topBarHeight, topBarWidth, statusBarHeight + topBarOffset),
            _getSudokuGrid(sudokuGridSize, statusBarHeight + sudokuGridOffset),
            _getNumberKeyboard(numberKeyboardSize, numberKeyboardOffset),
          ],
        ),
      ),
    );
  }

  // Creates the top bar, which contains a button to take a new image and a
  // button to solve the currently displayed Sudoku.
  Widget _getTopBar(double height, double width, double offset) {
    final buttonStyle = ElevatedButton.styleFrom(
      elevation: 5,
      primary: const Color.fromARGB(255, 102, 102, 102),
      shadowColor: Colors.black,
    );
    return Padding(
      padding: EdgeInsets.only(top: offset),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: height,
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: buttonStyle,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const CameraView(),
                  ),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text("New"),
              ),
              ElevatedButton(
                style: buttonStyle,
                // TODO: solve Sudoku grid
                onPressed: () {},
                child: const Text("Solution"),
              ),
            ],
          ),
        ),
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
  Widget _getSudokuGrid(double size, double offset) {
    return Padding(
      padding: EdgeInsets.only(top: offset),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.025),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            primary: false,
            addAutomaticKeepAlives: false,
            crossAxisCount: 9,
            // physics: const NeverScrollableScrollPhysics(),
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
                              style: TextStyle(
                                color: isModifiable ? Colors.blue[900] : Colors.black,
                                fontWeight: isModifiable ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                          )
                        : null),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Creates the number keyboard.
  Widget _getNumberKeyboard(double size, double offset) {
    return Padding(
      padding: EdgeInsets.only(bottom: offset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: size,
          height: size,
          child: GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            primary: false,
            addAutomaticKeepAlives: false,
            crossAxisCount: 3,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            children: List.generate(9, (index) {
              int value = index + 1;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  primary: const Color.fromARGB(255, 102, 102, 102),
                  shadowColor: Colors.black,
                ),
                onPressed: () {
                  if (selectedId != null) {
                    if (mounted) {
                      setState(() {
                        sudokuGrid[selectedId!].value = value;
                      });
                    }
                  }
                },
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 30.0,
                  ),
                ),
              );
            }),
          ),
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
