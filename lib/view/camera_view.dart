import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'picture_view.dart';
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
  late double _roiOffset; // offset percentage from center to top
  late Size _cropSize; // positioned at center of resulting picture
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
      ResolutionPreset.veryHigh,
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
    // get screen height and width
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    final bottomBarHeight = screenHeight * 0.15;
    final bottomBarWidth = screenWidth * 0.9;
    final bottomBarOffset = screenHeight * 0.03;
    final overlaySize = screenWidth * 0.7;
    final overlayOffset = bottomBarOffset + bottomBarHeight;

    _roiOffset = overlayOffset / screenHeight; // 0.18;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _getCameraWidget(screenHeight, screenWidth),
          _getCameraOverlay(overlaySize, overlayOffset),
          _getBottomBar(bottomBarHeight, bottomBarWidth, bottomBarOffset),
        ],
      ),
    );
  }

  Widget _getCameraWidget(double height, double width) {
    // You must wait until the controller is initialized before displaying the
    // camera preview. Use a FutureBuilder to display a loading spinner until the
    // controller has finished initializing.
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final cameraSize = _controller.value.previewSize!;
          // camera size is in landscape mode but we want aspect ratio from portrait mode
          final cameraAspectRatio = cameraSize.width / cameraSize.height;
          double widgetAspectRatio = height / width;

          bool fitHeight = (widgetAspectRatio > cameraAspectRatio);

          _cropSize = Size(
            fitHeight ? cameraSize.width : cameraSize.height * widgetAspectRatio,
            fitHeight ? cameraSize.width / widgetAspectRatio : cameraSize.height,
          );

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
                    child: CameraPreview(_controller),
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

  Widget _getCameraOverlay(double size, double vPosition) {
    final defaultLine = BorderSide(color: Colors.white, width: 3);
    final lineLength = size * 0.1;
    return Center(
      // heightFactor: 0.5,
      child: Container(
        margin: EdgeInsets.only(bottom: vPosition),
        height: size,
        width: size,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: _takingPicture ? CircularProgressIndicator() : Container(),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: _makeOverlayCorner(
                lineLength,
                top: defaultLine,
                left: defaultLine,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _makeOverlayCorner(
                lineLength,
                top: defaultLine,
                right: defaultLine,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: _makeOverlayCorner(
                lineLength,
                bottom: defaultLine,
                left: defaultLine,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: _makeOverlayCorner(
                lineLength,
                bottom: defaultLine,
                right: defaultLine,
              ),
            )
          ],
        ),
      ),
    );
  }

  Container _makeOverlayCorner(
    double size, {
    BorderSide top = BorderSide.none,
    BorderSide bottom = BorderSide.none,
    BorderSide left = BorderSide.none,
    BorderSide right = BorderSide.none,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        border: Border(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
        ),
      ),
    );
  }

  Widget _getBottomBar(double height, double width, double offset) {
    return Padding(
      padding: EdgeInsets.only(bottom: offset),
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
      padding: EdgeInsets.symmetric(horizontal: barWidth * 0.07),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: "ToggleFlashButton",
            elevation: 0,
            foregroundColor: _isFlashOn ? Colors.yellow : Colors.white,
            backgroundColor: Colors.transparent,
            child: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              size: barHeight * 0.32,
            ),
            onPressed: _onToggleFlashButtonPressed,
          ),
          Container(
            height: barHeight * 0.7,
            width: barHeight * 0.7,
            child: FloatingActionButton(
              heroTag: "TakePictureButton",
              foregroundColor: Colors.grey,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.circle,
                size: barHeight * 0.65,
              ),
              onPressed: _onTakePictureButtonPressed,
            ),
          ),
          FloatingActionButton(
            heroTag: "GalleryButton",
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            child: Icon(
              Icons.image,
              size: barHeight * 0.4,
            ),
            onPressed: _onGalleryButtonPressed,
          ),
        ],
      ),
    );
  }

  void _turnFlashOff() {
    if (!_isFlashOn) return;

    _controller.setFlashMode(FlashMode.off);

    setState(() {
      _isFlashOn = false;
    });
  }

  void _turnFlashOn() {
    if (_isFlashOn) return;

    _controller.setFlashMode(FlashMode.torch);

    setState(() {
      _isFlashOn = true;
    });
  }

  void _onToggleFlashButtonPressed() async {
    _isFlashOn ? _turnFlashOff() : _turnFlashOn();
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

      // In case flash was turned on before
      _turnFlashOff();

      setState(() {
        _takingPicture = false;
      });

      // If the picture was taken, display it on a new screen.
      _showPicture(image.path);
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  void _onGalleryButtonPressed() async {
    // In case flash was turned on before
    _turnFlashOff();

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
