import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class SudokuGrid extends ChangeNotifier {
  final List<SudokuGridCell> _cellList;
  late List<List<int>> _unitList;

  int? _selectedId;

  SudokuGrid(List<int> valueList)
      :
        // Create Sudoku grid.
        _cellList = valueList.mapIndexed((index, element) {
          int colNum = index % 9;
          int rowNum = index ~/ 9;

          return SudokuGridCell(
            index,
            rowNum,
            colNum,
            element,
          );
        }).toList();

  SudokuGridCell getCell(int row, int col) {
    final id = row * 9 + col;
    return _cellList[id];
  }

  void select(SudokuGridCell cell) {
    int? oldSelectedId = _selectedId;

    _selectedId = cell.id;

    if (cell.id == oldSelectedId) return;

    cell.status = Status.selected;

    // Notify old cell and its unit of unselect.
    if (oldSelectedId != null) {
      _cellList[oldSelectedId].status = Status.none;
      _notifyUnit(oldSelectedId, Status.none);
    }
    _selectedId = cell.id;
    // Notify new cell's unit of select.
    _notifyUnit(cell.id, Status.inUnit);

    notifyListeners();
  }

  void writeSelected(int value) {
    if (_selectedId == null) return;
    _cellList[_selectedId!].value = value;
    notifyListeners();
  }

  void deleteSelected() {
    writeSelected(0);
  }

  void _notifyUnit(int cellId, Status status) {
    _cellList[5].status = status;
    // for (int id in _unitList[cellId]) {
    //   if (id == cellId) break;
    //   _cellList[id].status = status;
    // }
  }
}

enum Status {
  none,
  selected,
  inUnit,
  sameValue,
}

/// Defines a Sudoku grid cell.
///
/// Holds [id], [row, col] and [value].
class SudokuGridCell {
  final int _id;
  final int _row;
  final int _col;
  final int _blockId;
  final bool _isModifiable;
  int _value;
  Status _status = Status.none;

  SudokuGridCell(this._id, this._row, this._col, this._value)
      : _isModifiable = (_value == 0),
        _blockId = (_row ~/ 3) * 3 + _col ~/ 3;

  bool inUnitOf(SudokuGridCell cell) {
    return (_row == cell.row || _col == cell.col || _blockId == cell.blockId);
  }

  int get id => _id;
  int get row => _row;
  int get col => _col;
  int get blockId => _blockId;
  bool get isModifiable => _isModifiable;
  int get value => _value;
  Status get status => _status;

  set value(int value) {
    assert(0 <= value && value < 10);
    if (!isModifiable || value == _value) return;
    _value = value;
  }

  set status(Status status) {
    if (status == _status) return;

    _status = status;
  }
}
