import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:sudokuai/solver/sudoku_solver.dart';
import 'package:provider/provider.dart';
import '../grid/sudoku_grid.dart';
import 'camera_view.dart';

class SudokuView extends StatefulWidget {
  final List<int> sudokuGrid;

  const SudokuView({Key? key, required this.sudokuGrid}) : super(key: key);

  @override
  State<SudokuView> createState() => _SudokuViewState();
}

/// A widget that only displays the extracted sudoku grid (not interactable).
class _SudokuViewState extends State<SudokuView> {
  final _buttonPrimaryColor = const Color.fromARGB(255, 102, 102, 102);
  late SudokuGrid sudokuGrid;
  int? selectedId;

  @override
  void initState() {
    super.initState();

    // Create Sudoku grid.
    sudokuGrid = SudokuGrid(widget.sudokuGrid);
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
    var numberKeyboardSize = screenWidth * 0.5;
    var numberKeyboardOffset = screenHeight * 0.05;

    // Check for overflow of number keyboard.
    if (statusBarHeight + sudokuGridOffset + sudokuGridSize + numberKeyboardSize + numberKeyboardOffset >
        screenHeight) {
      numberKeyboardSize = screenWidth * 0.45;
      numberKeyboardOffset = screenHeight * 0.02;
    }

    final deleteButtonYOffset = numberKeyboardOffset + numberKeyboardSize * 0.05;
    final deleteButtonXOffset = numberKeyboardSize + screenWidth * 0.2;

    return WillPopScope(
      // Disable back button.
      onWillPop: () async => false,
      child: Scaffold(
        body: ChangeNotifierProvider.value(
          value: sudokuGrid,
          child: Stack(
            children: <Widget>[
              _getTopBar(topBarHeight, topBarWidth, statusBarHeight + topBarOffset),
              _getSudokuGrid(sudokuGridSize, statusBarHeight + sudokuGridOffset),
              _getNumberKeyboard(numberKeyboardSize, numberKeyboardOffset),
              _getDeleteButton(deleteButtonYOffset, deleteButtonXOffset),
            ],
          ),
        ),
      ),
    );
  }

  // Creates the top bar, which contains a button to take a new image and a
  // button to solve the currently displayed Sudoku.
  Widget _getTopBar(double height, double width, double offset) {
    final buttonStyle = ElevatedButton.styleFrom(
      elevation: 5,
      primary: _buttonPrimaryColor,
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
          child: const SudokuGridWidget(),
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
        child: SizedBox(
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
              return Consumer<SudokuGrid>(
                builder: (_, sudokuGrid, __) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      primary: _buttonPrimaryColor,
                      shadowColor: Colors.black,
                    ),
                    onPressed: () => sudokuGrid.writeSelected(value),
                    child: Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 30.0,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Creates a delete button.
  Widget _getDeleteButton(double yOffset, double xOffset) {
    return Padding(
      padding: EdgeInsets.only(bottom: yOffset, left: xOffset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Consumer<SudokuGrid>(
          builder: (_, sudokuGrid, __) {
            return InkResponse(
              onTap: () => sudokuGrid.deleteSelected(),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: const Icon(
                Icons.backspace,
                size: 35.0,
              ),
            );
          },
        ),
      ),
    );
  }
}

class SudokuGridWidget extends StatelessWidget {
  const SudokuGridWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("rebuild whole sudoku");
    return FittedBox(
      fit: BoxFit.contain,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(40.0),
        border: const TableBorder(
          left: BorderSide(width: 3.0, color: Colors.black),
          top: BorderSide(width: 3.0, color: Colors.black),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: _getTableRows(),
      ),
    );
  }

  List<TableRow> _getTableRows() {
    return List.generate(9, (int rowNumber) {
      return TableRow(children: _getRow(rowNumber));
    });
  }

  List<Widget> _getRow(int rowNumber) {
    return List.generate(9, (int colNumber) {
      return Container(
        height: 40.0,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              width: (colNumber % 3 == 2) ? 3.0 : 1.0,
              color: Colors.black,
            ),
            bottom: BorderSide(
              width: (rowNumber % 3 == 2) ? 3.0 : 1.0,
              color: Colors.black,
            ),
          ),
        ),
        child: SudokuCellWidget(rowNumber, colNumber),
      );
    });
  }
}

class SudokuCellWidget extends StatelessWidget {
  final int row;
  final int col;

  const SudokuCellWidget(this.row, this.col, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sudokuGrid = context.read<SudokuGrid>();
    final sudokuCell = sudokuGrid.getCell(row, col);
    const fontSize = 20.0;
    print("whole rebuild of ($row, $col)");
    return InkResponse(
      onTap: () => sudokuGrid.select(sudokuCell),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Selector<SudokuGrid, Status>(
        selector: (_, sudokuGrid) => sudokuGrid.getCell(row, col).status,
        builder: (_, status, child) {
          print('$row, $col');
          return Container(
            color: _getColor(status),
            padding: const EdgeInsets.all(5),
            child: child,
          );
        },
        child: (!sudokuCell.isModifiable)
            ? Center(
                child: Text(
                  sudokuCell.value.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : Selector<SudokuGrid, int>(
                selector: (_, sudokuGrid) => sudokuGrid.getCell(row, col).value,
                builder: (_, value, __) {
                  print("rebuild Text");
                  return (value != 0)
                      ? Center(
                          child: Text(
                            value.toString(),
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: fontSize,
                            ),
                          ),
                        )
                      : const SizedBox();
                },
              ),
      ),
    );
  }

  /// Get background color of grid cell based on the currently selected
  /// grid cell.
  Color _getColor(Status status) {
    const defaultBackground = Colors.transparent;
    const selectedBackground = Color.fromARGB(100, 43, 188, 255);
    const unitBackground = Color.fromARGB(100, 150, 150, 150);
    const sameValueBackground = Color.fromARGB(100, 200, 0, 0);

    switch (status) {
      case Status.none:
        return defaultBackground;
      case Status.selected:
        return selectedBackground;
      case Status.inUnit:
        return unitBackground;
      case Status.sameValue:
        return sameValueBackground;
      default:
        return defaultBackground;
    }
  }
}
