import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import "native_sudoku_scanner_bridge.dart" as bridge;

class SudokuScanner {
  /// Initializes and loads the tensorflow model.
  ///
  /// The neural network model - used for classifying printed digits - is
  /// encoded in the app package. Because of this native C++ Tensorflow
  /// cannot read the model straight from assets. Therefore we read and
  /// decode the model first and save it then to the app's folder. This only
  /// needs to be done once.
  static Future<void> init() async {
    final extDir = await getExternalStorageDirectory();
    final tfliteModelPath = extDir!.path + "/model.tflite";

    if (!await File(tfliteModelPath).exists()) {
      var tfliteModel = await rootBundle.load('assets/model.tflite');

      File(tfliteModelPath).writeAsBytes(tfliteModel.buffer.asUint8List(
        tfliteModel.offsetInBytes,
        tfliteModel.lengthInBytes,
      ));
    }
    return compute(bridge.setModel, tfliteModelPath);
  }

  static Future<bridge.BoundingBox> detectGrid(String path) {
    return compute(bridge.detectGrid, path);
  }

  static Future<List<int>> extractGrid(String path, bridge.BoundingBox detectionResult) {
    return compute((_) => bridge.extractGrid(path, detectionResult), null);
  }

  static Future<List<int>> extractGridfromRoi(String path, int roiSize, int roiOffset) {
    return compute((_) => bridge.extractGridfromRoi(path, roiSize, roiOffset), null);
  }
}
