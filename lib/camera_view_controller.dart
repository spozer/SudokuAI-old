import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';

class CameraViewController extends StatefulWidget {
  const CameraViewController({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  _CameraViewControllerState createState() => _CameraViewControllerState();
}

class _CameraViewControllerState extends State<CameraViewController> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _takingPicture = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.max,
      // Audio not needed
      enableAudio: false,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        // mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _getCameraWidget(),
          // SizedBox(height: 15),
          _getBottomBar(),
        ],
      ),
    );
  }

  Widget _getCameraWidget() {
    // You must wait until the controller is initialized before displaying the
    // camera preview. Use a FutureBuilder to display a loading spinner until the
    // controller has finished initializing.
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // get screen height and width
          double height = MediaQuery.of(context).size.height;
          double width = MediaQuery.of(context).size.width;

          double cameraAspectRatio = _controller.value.aspectRatio;
          double screenAspectRatio = 1 / MediaQuery.of(context).size.aspectRatio;

          bool fitHeight = (screenAspectRatio > cameraAspectRatio);

          return SizedBox(
            width: width,
            height: height,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: fitHeight ? BoxFit.fitHeight : BoxFit.fitWidth,
                  child: SizedBox(
                    width: fitHeight ? height / cameraAspectRatio : width,
                    height: fitHeight ? height : width * cameraAspectRatio,
                    child: _takingPicture
                        ? Stack(children: <Widget>[
                            CameraPreview(_controller),
                            Center(child: CircularProgressIndicator()),
                          ])
                        : CameraPreview(_controller),
                  ),
                ),
              ),
            ),
          );
        } else {
          // Otherwise, display a loading indicator.
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _getBottomBar() {
    // bar height and width depending on screen dimensions
    double height = MediaQuery.of(context).size.height * 0.15;
    double width = MediaQuery.of(context).size.width * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: height,
              width: width,
              color: Colors.black.withOpacity(0.1),
              alignment: Alignment.center,
              child: _getButtonRow(height, width),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getButtonRow(double barHeight, double barWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: "ToggleFlashButton",
            elevation: 0,
            foregroundColor: _isFlashOn ? Colors.yellow : Colors.white,
            backgroundColor: Colors.transparent,
            child: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, size: 35),
            onPressed: _onToggleFlashButtonPressed,
          ),
          Container(
            height: barHeight * 0.7,
            width: barHeight * 0.7,
            child: FloatingActionButton(
              heroTag: "TakePictureButton",
              foregroundColor: Colors.grey,
              backgroundColor: Colors.white,
              child: Icon(Icons.circle, size: barHeight * 0.65),
              onPressed: _onTakePictureButtonPressed,
            ),
          ),
          FloatingActionButton(
            heroTag: "GalleryButton",
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            child: Icon(Icons.image, size: 40),
            onPressed: _onGalleryButtonPressed,
          ),
        ],
      ),
    );
  }

  void _onToggleFlashButtonPressed() async {
    _controller.setFlashMode(_isFlashOn ? FlashMode.off : FlashMode.torch);

    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _onTakePictureButtonPressed() async {
    try {
      setState(() {
        _takingPicture = true;
      });

      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      // Attempt to take a picture and get the file `image`
      // where it was saved.
      final image = await _controller.takePicture();

      // Turn off flash
      _controller.setFlashMode(FlashMode.off);

      setState(() {
        _takingPicture = false;
        _isFlashOn = false;
      });

      // If the picture was taken, display it on a new screen.
      _showPicture(image.path);
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  void _onGalleryButtonPressed() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _showPicture(image.path);
    }
  }

  void _showPicture(String imagePath) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DisplayPictureScreen(
          // Pass the automatically generated path to
          // the DisplayPictureScreen widget.
          imagePath: imagePath,
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);

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
