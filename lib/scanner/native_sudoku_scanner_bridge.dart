import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

// example at https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

class Coordinate extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;
}

class DetectionResult extends Struct {
  external Coordinate topLeft;
  external Coordinate topRight;
  external Coordinate bottomLeft;
  external Coordinate bottomRight;
}

// ignore: camel_case_types
typedef detect_grid_function = DetectionResult Function(Pointer<Utf8> imagePath);

typedef DetectGridFunction = DetectionResult Function(Pointer<Utf8> imagePath);

// ignore: camel_case_types
typedef extract_grid_function = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  DetectionResult detectionResult,
);

typedef ExtractGridFunction = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  DetectionResult detectionResult,
);

// ignore: camel_case_types
typedef extract_grid_from_roi_function = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  Double roiSize,
  Double roiOffset,
  Double aspectRatio,
);

typedef ExtractGridFromRoiFunction = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  double roiSize,
  double roiOffset,
  double aspectRatio,
);

// ignore: camel_case_types
typedef debug_grid_extraction_function = Int8 Function(
  Pointer<Utf8> imagePath,
  DetectionResult detectionResult,
);

typedef DebugGridExtractionFunction = int Function(
  Pointer<Utf8> imagePath,
  DetectionResult detectionResult,
);

// ignore: camel_case_types
typedef debug_function = Int8 Function(Pointer<Utf8> imagePath);
typedef DebugFunction = int Function(Pointer<Utf8> imagePath);

// ignore: camel_case_types
typedef set_model_function = Void Function(Pointer<Utf8> path);
typedef SetModelFunction = void Function(Pointer<Utf8> path);

// ignore: camel_case_types
typedef free_pointer_function = Void Function(Pointer<Int32> pointer);
typedef FreePointerFunction = void Function(Pointer<Int32> pointer);

class NativeSudokuScannerBridge {
  static late DynamicLibrary _nativeSudokuScanner;
  static late String _tfliteModelPath;

  static void init() async {
    final extDir = await getExternalStorageDirectory();
    _tfliteModelPath = extDir!.path + "/model.tflite";

    // init native library
    _nativeSudokuScanner = DynamicLibrary.open("libnative_sudoku_scanner.so");

    if (!await File(_tfliteModelPath).exists()) {
      var tfliteModel = await rootBundle.load('assets/model.tflite');

      File(_tfliteModelPath).writeAsBytes(tfliteModel.buffer.asUint8List(
        tfliteModel.offsetInBytes,
        tfliteModel.lengthInBytes,
      ));
    }
    _setModel(_tfliteModelPath);
  }

  static Future<DetectionResult> detectGrid(String path) async {
    final nativeDetectGrid =
        _nativeSudokuScanner.lookupFunction<detect_grid_function, DetectGridFunction>("detect_grid");

    // creates a char pointer
    final pathPointer = path.toNativeUtf8();

    DetectionResult detectionResult = nativeDetectGrid(pathPointer);

    // need to free memory
    malloc.free(pathPointer);

    return detectionResult;
  }

  static Future<List<int>> extractGrid(String path, DetectionResult detectionResult) async {
    final nativeExtractGrid =
        _nativeSudokuScanner.lookupFunction<extract_grid_function, ExtractGridFunction>("extract_grid");

    // creates a char pointer
    final pathPointer = path.toNativeUtf8();

    Pointer<Int32> gridArray = nativeExtractGrid(pathPointer, detectionResult);

    List<int> gridList = gridArray.asTypedList(81);

    // free memory
    malloc.free(pathPointer);
    _freePointer(gridArray);

    return gridList;
  }

  static Future<List<int>> extractGridfromRoi(
    String path,
    double roiSize,
    double roiOffset,
    double aspectRatio,
  ) async {
    final nativeExtractGridfromRoi = _nativeSudokuScanner
        .lookupFunction<extract_grid_from_roi_function, ExtractGridFromRoiFunction>("extract_grid_from_roi");

    // creates a char pointer
    final pathPointer = path.toNativeUtf8();

    Pointer<Int32> gridArray = nativeExtractGridfromRoi(pathPointer, roiSize, roiOffset, aspectRatio);

    List<int> gridList = gridArray.asTypedList(81);

    // free memory
    malloc.free(pathPointer);
    _freePointer(gridArray);

    return gridList;
  }

  static Future<bool> debugGridDetection(String path) async {
    final nativeDebugGridDetection =
        _nativeSudokuScanner.lookupFunction<debug_function, DebugFunction>("debug_grid_detection");

    // creates a char pointer
    final pathPointer = path.toNativeUtf8();

    int debugImage = nativeDebugGridDetection(pathPointer);

    // free memory
    malloc.free(pathPointer);

    return debugImage == 1;
  }

  static Future<bool> debugGridExtraction(String path, DetectionResult detectionResult) async {
    final nativeDebugGridExtraction = _nativeSudokuScanner
        .lookupFunction<debug_grid_extraction_function, DebugGridExtractionFunction>("debug_grid_extraction");

    // creates a char pointer
    final pathPointer = path.toNativeUtf8();

    int debugImage = nativeDebugGridExtraction(pathPointer, detectionResult);

    // free memory
    malloc.free(pathPointer);

    return debugImage == 1;
  }

  static void _setModel(String path) {
    final nativeSetModel = _nativeSudokuScanner.lookupFunction<set_model_function, SetModelFunction>("set_model");

    // creates a char pointer
    final pathPointer = path.toNativeUtf8();

    nativeSetModel(pathPointer);

    // free memory
    malloc.free(pathPointer);
  }

  static void _freePointer(Pointer<Int32> pointer) {
    final nativeFreePointer =
        _nativeSudokuScanner.lookupFunction<free_pointer_function, FreePointerFunction>("free_pointer");

    nativeFreePointer(pointer);
  }
}
