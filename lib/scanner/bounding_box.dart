import 'dart:ui';
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

  List<Offset> asPoints(Size size) {
    final ptTopLeft = _scaleOffset(topLeft, size);
    final ptTopRight = _scaleOffset(topRight, size);
    final ptBottomLeft = _scaleOffset(bottomLeft, size);
    final ptBottomRight = _scaleOffset(bottomRight, size);

    return [
      ptTopLeft,
      ptTopRight,
      ptBottomRight,
      ptBottomLeft,
      ptTopLeft,
    ];
  }

  Offset _scaleOffset(Offset offset, Size size) {
    return Offset(offset.dx * size.width, offset.dy * size.height);
  }
}
