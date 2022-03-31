import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scanner/sudoku_scanner.dart';
import 'view/camera_view.dart';

void main() async {
  // Ensure that plugin services are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Bridge.
  SudokuScanner.init();

  // Show Status and Navigation Bar.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ],
  );

  // Disable screen rotation.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: const CameraView(),
  ));
}
