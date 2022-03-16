import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

// Example at https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

// Structs don't have to be allocated to be passed as value from dart to native c code:
// https://medium.com/dartlang/implementing-structs-by-value-in-dart-ffi-1cb1829d11a9
// Futhermore structs returned from native c code to dart are backed in c heap

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

// The following typedefs are function layouts needed for bridging between
// native code and dart.

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
  Int32 roiSize,
  Int32 roiOffset,
);

typedef ExtractGridFromRoiFunction = Pointer<Int32> Function(
  Pointer<Utf8> imagePath,
  int roiSize,
  int roiOffset,
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

/// Bridge between Dart and native C++ code.
///
/// Defines all public functions of the SudokuScanner C++ library and
/// makes them callable through Dart's Foreign Function Interface (FFI).
class NativeSudokuScannerBridge {
  static late DynamicLibrary _nativeSudokuScanner;
  static late String _tfliteModelPath;

  /// Initializes native SudokuScanner library and loads the tensorflow model.
  ///
  /// The neural network model - used for classifying printed digits - is
  /// encoded in the app package. Because of this native C++ Tensorflow
  /// cannot read the model straight from assets. Therefore we read and
  /// decode the model first and save it then to the app's folder. This only
  /// needs to be done once.
  static Future<void> init() async {
    final extDir = await getExternalStorageDirectory();
    _tfliteModelPath = extDir!.path + "/model.tflite";

    // Initialize native SudokuScanner library.
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

  /// Bridge for [detect_grid].
  static Future<DetectionResult> detectGrid(String path) async {
    final nativeDetectGrid =
        _nativeSudokuScanner.lookupFunction<detect_grid_function, DetectGridFunction>("detect_grid");

    // Creates a char pointer.
    final pathPointer = path.toNativeUtf8();

    DetectionResult detectionResult = nativeDetectGrid(pathPointer);

    // Need to free memory.
    malloc.free(pathPointer);

    return detectionResult;
  }

  /// Bridge for [extract_grid].
  static Future<List<int>> extractGrid(String path, DetectionResult detectionResult) async {
    final nativeExtractGrid =
        _nativeSudokuScanner.lookupFunction<extract_grid_function, ExtractGridFunction>("extract_grid");

    // Creates a char pointer.
    final pathPointer = path.toNativeUtf8();

    Pointer<Int32> gridArray = nativeExtractGrid(pathPointer, detectionResult);

    // It is not clear, whether asTypeList gets handled from GC or not:
    // https://github.com/dart-lang/ffi/issues/22
    // https://github.com/dart-lang/sdk/issues/45508
    // Either way it is probably better to free c heap in native code.
    List<int> gridList = List.from(gridArray.asTypedList(81));

    // Free memory.
    malloc.free(pathPointer);
    _freePointer(gridArray);

    return gridList;
  }

  /// Bridge for [extract_grid_from_roi].
  static Future<List<int>> extractGridfromRoi(
    String path,
    int roiSize,
    int roiOffset,
  ) async {
    final nativeExtractGridfromRoi = _nativeSudokuScanner
        .lookupFunction<extract_grid_from_roi_function, ExtractGridFromRoiFunction>("extract_grid_from_roi");

    // creates a char pointer
    final pathPointer = path.toNativeUtf8();

    Pointer<Int32> gridArray = nativeExtractGridfromRoi(pathPointer, roiSize, roiOffset);

    // It is not clear, whether asTypeList gets handled from GC or not:
    // https://github.com/dart-lang/ffi/issues/22
    // https://github.com/dart-lang/sdk/issues/45508
    // Either way it is probably better to free c heap in native code.
    List<int> gridList = List.from(gridArray.asTypedList(81));

    // Free memory.
    malloc.free(pathPointer);
    _freePointer(gridArray);

    return gridList;
  }

  /// Bridge for [debug_grid_detection].
  static Future<bool> debugGridDetection(String path) async {
    final nativeDebugGridDetection =
        _nativeSudokuScanner.lookupFunction<debug_function, DebugFunction>("debug_grid_detection");

    // Creates a char pointer.
    final pathPointer = path.toNativeUtf8();

    int debugImage = nativeDebugGridDetection(pathPointer);

    // Free memory.
    malloc.free(pathPointer);

    return debugImage == 1;
  }

  /// Bridge for [debug_grid_extraction].
  static Future<bool> debugGridExtraction(String path, DetectionResult detectionResult) async {
    final nativeDebugGridExtraction = _nativeSudokuScanner
        .lookupFunction<debug_grid_extraction_function, DebugGridExtractionFunction>("debug_grid_extraction");

    // Creates a char pointer.
    final pathPointer = path.toNativeUtf8();

    int debugImage = nativeDebugGridExtraction(pathPointer, detectionResult);

    // Free memory.
    malloc.free(pathPointer);

    return debugImage == 1;
  }

  /// Bridge for [set_model].
  /// This function is only needed for initialization.
  static Future<void> _setModel(String path) async {
    final nativeSetModel = _nativeSudokuScanner.lookupFunction<set_model_function, SetModelFunction>("set_model");

    // Creates a char pointer.
    final pathPointer = path.toNativeUtf8();

    nativeSetModel(pathPointer);

    // Free memory.
    malloc.free(pathPointer);
  }

  /// Bridge for [free_pointer].
  /// Free a pointer on native heap.
  static Future<void> _freePointer(Pointer<Int32> pointer) async {
    final nativeFreePointer =
        _nativeSudokuScanner.lookupFunction<free_pointer_function, FreePointerFunction>("free_pointer");

    nativeFreePointer(pointer);
  }
}
