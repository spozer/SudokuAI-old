import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class Coordinate extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  factory Coordinate.allocate(double x, double y) => malloc<Coordinate>().ref
    ..x = x
    ..y = y;
}

class NativeDetectionResult extends Struct {
  external Pointer<Coordinate> topLeft;
  external Pointer<Coordinate> topRight;
  external Pointer<Coordinate> bottomLeft;
  external Pointer<Coordinate> bottomRight;

  factory NativeDetectionResult.allocate(
    Pointer<Coordinate> topLeft,
    Pointer<Coordinate> topRight,
    Pointer<Coordinate> bottomLeft,
    Pointer<Coordinate> bottomRight,
  ) =>
      malloc<NativeDetectionResult>().ref
        ..topLeft = topLeft
        ..topRight = topRight
        ..bottomLeft = bottomLeft
        ..bottomRight = bottomRight;
}

class GridDetectionResult {
  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;

  GridDetectionResult({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });
}

// asTypedList for Array Type will be available eventually (see https://github.com/dart-lang/sdk/issues/45508)
// class GridArray extends Struct {
//   @Array(81)
//   Array<Int32> array;
// }

// ignore: camel_case_types
typedef detect_grid_function = Pointer<NativeDetectionResult> Function(
    Pointer<Utf8> imagePath, Double roiSize, Double roiOffset, Double aspectRatio);

typedef DetectGridFunction = Pointer<NativeDetectionResult> Function(
    Pointer<Utf8> imagePath, double roiSize, double roiOffset, double aspectRatio);

// ignore: camel_case_types
typedef extract_grid_function = Pointer<Int32> Function(
    Pointer<Utf8> imagePath,
    Double topLeftX,
    Double topLeftY,
    Double topRightX,
    Double topRightY,
    Double bottomLeftX,
    Double bottomLeftY,
    Double bottomRightX,
    Double bottomRightY);

typedef ExtractGridFunction = Pointer<Int32> Function(
    Pointer<Utf8> imagePath,
    double topLeftX,
    double topLeftY,
    double topRightX,
    double topRightY,
    double bottomLeftX,
    double bottomLeftY,
    double bottomRightX,
    double bottomRightY);

// ignore: camel_case_types
typedef debug_grid_extraction_function = Int8 Function(
    Pointer<Utf8> imagePath,
    Double topLeftX,
    Double topLeftY,
    Double topRightX,
    Double topRightY,
    Double bottomLeftX,
    Double bottomLeftY,
    Double bottomRightX,
    Double bottomRightY);

typedef DebugGridExtractionFunction = int Function(
    Pointer<Utf8> imagePath,
    double topLeftX,
    double topLeftY,
    double topRightX,
    double topRightY,
    double bottomLeftX,
    double bottomLeftY,
    double bottomRightX,
    double bottomRightY);

// ignore: camel_case_types
typedef debug_function = Int8 Function(Pointer<Utf8> imagePath);
typedef DebugFunction = int Function(Pointer<Utf8> imagePath);

// ignore: camel_case_types
typedef set_model_function = Void Function(Pointer<Utf8> path);
typedef SetModelFunction = void Function(Pointer<Utf8> path);

// https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart

class NativeSudokuScannerBridge {
  static String tfliteModelPath = "";

  static void init() async {
    final extDir = await getExternalStorageDirectory();
    tfliteModelPath = extDir!.path + "/model.tflite";
    if (!await File(tfliteModelPath).exists()) {
      var tfliteModel = await rootBundle.load('assets/model.tflite');
      File(tfliteModelPath).writeAsBytes(
        tfliteModel.buffer.asUint8List(
          tfliteModel.offsetInBytes,
          tfliteModel.lengthInBytes,
        ),
      );
    }
    _setModel(tfliteModelPath);
  }

  static Future<GridDetectionResult> detectGrid(String path,
      {double roiSize = 0.0, double roiOffset = 0.0, double aspectRatio = 0.0}) async {
    DynamicLibrary nativeSudokuScanner = _getDynamicLibrary();

    final detectGrid = nativeSudokuScanner
        .lookup<NativeFunction<detect_grid_function>>("detect_grid")
        .asFunction<DetectGridFunction>();

    NativeDetectionResult detectionResult = detectGrid(path.toNativeUtf8(), roiSize, roiOffset, aspectRatio).ref;

    return GridDetectionResult(
        topLeft: Offset(detectionResult.topLeft.ref.x, detectionResult.topLeft.ref.y),
        topRight: Offset(detectionResult.topRight.ref.x, detectionResult.topRight.ref.y),
        bottomLeft: Offset(detectionResult.bottomLeft.ref.x, detectionResult.bottomLeft.ref.y),
        bottomRight: Offset(detectionResult.bottomRight.ref.x, detectionResult.bottomRight.ref.y));
  }

  static Future<List<int>> extractGrid(String path, GridDetectionResult result) async {
    DynamicLibrary nativeSudokuScanner = _getDynamicLibrary();

    final extractGrid = nativeSudokuScanner
        .lookup<NativeFunction<extract_grid_function>>("extract_grid")
        .asFunction<ExtractGridFunction>();

    Pointer<Int32> gridArray = extractGrid(
        path.toNativeUtf8(),
        result.topLeft.dx,
        result.topLeft.dy,
        result.topRight.dx,
        result.topRight.dy,
        result.bottomLeft.dx,
        result.bottomLeft.dy,
        result.bottomRight.dx,
        result.bottomRight.dy);

    List<int> gridList = gridArray.asTypedList(81);

    gridList.forEach((elem) {
      if (elem != 0) print("array: $elem");
    });

    return gridList;
  }

  static Future<bool> debugGridDetection(String path) async {
    DynamicLibrary nativeSudokuScanner = _getDynamicLibrary();

    final debugGridDetection =
        nativeSudokuScanner.lookup<NativeFunction<debug_function>>("debug_grid_detection").asFunction<DebugFunction>();

    int debugImage = debugGridDetection(path.toNativeUtf8());

    return debugImage == 1;
  }

  static Future<bool> debugGridExtraction(String path, GridDetectionResult result) async {
    DynamicLibrary nativeSudokuScanner = _getDynamicLibrary();

    final debugGridExtraction = nativeSudokuScanner
        .lookup<NativeFunction<debug_grid_extraction_function>>("debug_grid_extraction")
        .asFunction<DebugGridExtractionFunction>();

    int debugImage = debugGridExtraction(path.toNativeUtf8(), result.topLeft.dx, result.topLeft.dy, result.topRight.dx,
        result.topRight.dy, result.bottomLeft.dx, result.bottomLeft.dy, result.bottomRight.dx, result.bottomRight.dy);

    return debugImage == 1;
  }

  static void _setModel(String path) async {
    DynamicLibrary nativeSudokuScanner = _getDynamicLibrary();

    final setModel =
        nativeSudokuScanner.lookup<NativeFunction<set_model_function>>("set_model").asFunction<SetModelFunction>();

    setModel(path.toNativeUtf8());
  }

  static DynamicLibrary _getDynamicLibrary() {
    final DynamicLibrary nativeSudokuScanner =
        Platform.isAndroid ? DynamicLibrary.open("libnative_sudoku_scanner.so") : DynamicLibrary.process();
    return nativeSudokuScanner;
  }
}
