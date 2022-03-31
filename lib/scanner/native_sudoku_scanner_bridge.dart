/// Bridge between Dart and native C++ code.
///
/// Defines all public functions of the SudokuScanner C++ library and
/// makes them callable through Dart's Foreign Function Interface (FFI).

// Example at https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

import 'dart:async';
import 'dart:ffi';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'native_functions.dart';

class BoundingBox {
  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;

  BoundingBox({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  factory BoundingBox.from(NativeBoundingBox nbb) {
    return BoundingBox(
      topLeft: Offset(nbb.topLeft.x, nbb.topLeft.y),
      topRight: Offset(nbb.topRight.x, nbb.topRight.y),
      bottomLeft: Offset(nbb.bottomLeft.x, nbb.bottomLeft.y),
      bottomRight: Offset(nbb.bottomRight.x, nbb.bottomRight.y),
    );
  }
}

/// Bridge for [detect_grid].
BoundingBox detectGrid(String path) {
  final nativeSudokuScanner = DynamicLibrary.open("libnative_sudoku_scanner.so");
  final nativeDetectGrid = nativeSudokuScanner.lookupFunction<detect_grid_function, DetectGridFunction>("detect_grid");

  // Creates a char pointer.
  final pathPointer = path.toNativeUtf8();

  final nativeBoundingBoxPointer = nativeDetectGrid(pathPointer);

  final boundingBox = BoundingBox.from(nativeBoundingBoxPointer.ref);

  // Need to free memory.
  malloc.free(pathPointer);
  malloc.free(nativeBoundingBoxPointer);

  return boundingBox;
}

/// Bridge for [extract_grid].
List<int> extractGrid(String path, BoundingBox boundingBox) {
  final nativeSudokuScanner = DynamicLibrary.open("libnative_sudoku_scanner.so");
  final nativeExtractGrid =
      nativeSudokuScanner.lookupFunction<extract_grid_function, ExtractGridFunction>("extract_grid");

  // Creates a char pointer and Native Bounding Box pointer.
  final pathPointer = path.toNativeUtf8();
  final nativeBoundingBoxPointer = NativeBoundingBox.from(boundingBox);

  Pointer<Int32> gridArray = nativeExtractGrid(pathPointer, nativeBoundingBoxPointer);

  // It is not clear, whether asTypeList gets handled from GC or not:
  // https://github.com/dart-lang/ffi/issues/22
  // https://github.com/dart-lang/sdk/issues/45508
  // Either way it is probably better to free c heap in native code.
  List<int> gridList = List.from(gridArray.asTypedList(81), growable: false);

  // Free memory.
  malloc.free(pathPointer);
  malloc.free(nativeBoundingBoxPointer);
  _freePointer(gridArray);

  return gridList;
}

/// Bridge for [extract_grid_from_roi].
List<int> extractGridfromRoi(String path, int roiSize, int roiOffset) {
  final nativeSudokuScanner = DynamicLibrary.open("libnative_sudoku_scanner.so");
  final nativeExtractGridfromRoi = nativeSudokuScanner
      .lookupFunction<extract_grid_from_roi_function, ExtractGridFromRoiFunction>("extract_grid_from_roi");

  // creates a char pointer
  final pathPointer = path.toNativeUtf8();

  Pointer<Int32> gridArray = nativeExtractGridfromRoi(pathPointer, roiSize, roiOffset);

  // It is not clear, whether asTypeList gets handled from GC or not:
  // https://github.com/dart-lang/ffi/issues/22
  // https://github.com/dart-lang/sdk/issues/45508
  // Either way it is probably better to free c heap in native code.
  List<int> gridList = List.from(gridArray.asTypedList(81), growable: false);

  // Free memory.
  malloc.free(pathPointer);
  _freePointer(gridArray);

  return gridList;
}

/// Bridge for [debug_grid_detection].
Future<bool> debugGridDetection(String path) async {
  final nativeSudokuScanner = DynamicLibrary.open("libnative_sudoku_scanner.so");
  final nativeDebugGridDetection =
      nativeSudokuScanner.lookupFunction<debug_function, DebugFunction>("debug_grid_detection");

  // Creates a char pointer.
  final pathPointer = path.toNativeUtf8();

  int debugImage = nativeDebugGridDetection(pathPointer);

  // Free memory.
  malloc.free(pathPointer);

  return debugImage == 1;
}

/// Bridge for [debug_grid_extraction].
Future<bool> debugGridExtraction(String path, BoundingBox boundingBox) async {
  final nativeSudokuScanner = DynamicLibrary.open("libnative_sudoku_scanner.so");
  final nativeDebugGridExtraction = nativeSudokuScanner
      .lookupFunction<debug_grid_extraction_function, DebugGridExtractionFunction>("debug_grid_extraction");

  // Creates a char pointer.
  final pathPointer = path.toNativeUtf8();
  final nativeBoundingBoxPointer = NativeBoundingBox.from(boundingBox);

  int debugImage = nativeDebugGridExtraction(pathPointer, nativeBoundingBoxPointer);

  // Free memory.
  malloc.free(pathPointer);

  return debugImage == 1;
}

/// Bridge for [set_model].
/// This function is only needed for initialization.
void setModel(String path) {
  final nativeSudokuScanner = DynamicLibrary.open("libnative_sudoku_scanner.so");
  final nativeSetModel = nativeSudokuScanner.lookupFunction<set_model_function, SetModelFunction>("set_model");

  // Creates a char pointer.
  final pathPointer = path.toNativeUtf8();

  nativeSetModel(pathPointer);

  // Free memory.
  malloc.free(pathPointer);
}

/// Bridge for [free_pointer].
/// Free a pointer on native heap.
void _freePointer(Pointer<Int32> pointer) {
  final nativeSudokuScanner = DynamicLibrary.open("libnative_sudoku_scanner.so");
  final nativeFreePointer =
      nativeSudokuScanner.lookupFunction<free_pointer_function, FreePointerFunction>("free_pointer");

  nativeFreePointer(pointer);
}
