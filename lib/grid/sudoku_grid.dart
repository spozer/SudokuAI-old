import 'package:flutter/material.dart';

enum BoardStatus {
  inProgress,
  solved,
  hasErrors,
}

class SudokuGrid extends ChangeNotifier {
  final List<List<SudokuGridCell>> _cellList;
  final List<SudokuGridBlock> _blockList;

  SudokuGridCell? _selectedCell;
  static int _emptyCount = 0;
  BoardStatus _status = BoardStatus.inProgress;

  SudokuGrid(List<int> valueList)
      :
        // Create Sudoku grid.
        _cellList = List.generate(9, (index) {
          final row = index;
          return List.generate(9, (index) {
            final col = index;
            final id = row * 9 + col;
            final value = valueList[id];
            if (value == 0) _emptyCount++;
            return SudokuGridCell(id, row, col, value);
          }, growable: false);
        }),
        _blockList = List.generate(9, (index) => SudokuGridBlock(index), growable: false);

  int getValue(int row, int col) {
    return _cellList[row][col].value;
  }

  CellStatus getCellStatus(int row, int col) {
    return _cellList[row][col].status;
  }

  bool isModifiable(int row, int col) {
    return _cellList[row][col].isModifiable;
  }

  BoardStatus getBoardStatus() {
    return _status;
  }

  void setValue(int row, int col, int value) {
    _cellList[row][col].value = value;
    notifyListeners();
  }

  void clearBoard() {
    for (final row in _cellList) {
      for (final cell in row) {
        cell.value = 0;
      }
    }
    notifyListeners();
  }

  void select(int row, int col) {
    if (_cellList[row][col].id == _selectedCell?.id) return;

    final cell = _cellList[row][col];
    final oldSelectedCell = _selectedCell;

    // Notify old cell and its unit of unselect.
    if (oldSelectedCell != null) {
      oldSelectedCell.status = CellStatus.none;
      _updateUnit(
        oldSelectedCell.row,
        oldSelectedCell.col,
        oldSelectedCell.blockId,
        (uCell) => uCell.status = CellStatus.none,
      );
    }
    // Notify new cell and its unit of select.
    cell.status = CellStatus.selected;
    _updateUnit(
        row,
        col,
        cell.blockId,
        (uCell) =>
            uCell.status = (uCell.value != 0 && uCell.value == cell.value) ? CellStatus.sameValue : CellStatus.inUnit);

    _selectedCell = cell;
    notifyListeners();
  }

  void writeSelected(int value) {
    if (_selectedCell == null || !_selectedCell!.isModifiable || _selectedCell!.value == value) return;

    if (_selectedCell!.value == 0) {
      _emptyCount--;
    } else if (value == 0) {
      if (_emptyCount == 0) _status = BoardStatus.inProgress;
      _emptyCount++;
    }

    _selectedCell!.value = value;
    _updateUnit(_selectedCell!.row, _selectedCell!.col, _selectedCell!.blockId, (uCell) {
      uCell.status = (value != 0 && uCell.value == value) ? CellStatus.sameValue : CellStatus.inUnit;
    });

    if (_emptyCount == 0) _status = _checkWinCondition() ? BoardStatus.solved : BoardStatus.hasErrors;

    notifyListeners();
  }

  void _updateUnit(int row, int col, int blockId, void Function(SudokuGridCell) update) {
    // Update row.
    for (int uCol = 0; uCol < 9; ++uCol) {
      if (uCol == col) continue;
      update(_cellList[row][uCol]);
    }

    // Update column.
    for (int uRow = 0; uRow < 9; ++uRow) {
      if (uRow == row) continue;
      update(_cellList[uRow][col]);
    }

    // Update block.
    final block = _blockList[blockId];
    for (final bRow in block.rows) {
      for (final bCol in block.cols) {
        if (bRow == row || bCol == col) continue;
        update(_cellList[bRow][bCol]);
      }
    }
  }

  bool _checkWinCondition() {
    Set digits;

    // Check rows.
    for (int row = 0; row < 9; ++row) {
      digits = <int>{};
      for (int col = 0; col < 9; ++col) {
        if (!digits.add(_cellList[row][col].value)) {
          debugPrint('Duplicate in: $row, $col');
          return false;
        }
      }
    }

    // Check columns.
    for (int col = 0; col < 9; ++col) {
      digits = <int>{};
      for (int row = 0; row < 9; ++row) {
        if (!digits.add(_cellList[row][col].value)) {
          debugPrint('Duplicate in: $row, $col');
          return false;
        }
      }
    }

    // Check blocks.
    for (final block in _blockList) {
      digits = <int>{};
      for (final bRow in block.rows) {
        for (final bCol in block.cols) {
          if (!digits.add(_cellList[bRow][bCol].value)) {
            debugPrint('Duplicate in: $bRow, $bCol');
            return false;
          }
        }
      }
    }

    return true;
  }
}

class SudokuGridBlock {
  final int _id;
  final List<int> _rows;
  final List<int> _cols;

  SudokuGridBlock(this._id)
      : _rows = List.generate(3, (index) => (_id ~/ 3) * 3 + index),
        _cols = List.generate(3, (index) => (_id % 3) * 3 + index);

  int get id => _id;
  List<int> get rows => _rows;
  List<int> get cols => _cols;
}

enum CellStatus {
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
  CellStatus _status = CellStatus.none;

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
  CellStatus get status => _status;

  set value(int value) {
    assert(0 <= value && value < 10);
    if (!isModifiable || value == _value) return;
    _value = value;
  }

  set status(CellStatus status) {
    if (status == _status) return;
    _status = status;
  }
}
