import 'dart:io';
import 'package:flutter/material.dart';

/// A widget that displays the picture taken by the user.
class PictureView extends StatelessWidget {
  final String imagePath;

  const PictureView({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
        child: Image.file(
          File(imagePath),
        ),
      ),
    );
  }
}
