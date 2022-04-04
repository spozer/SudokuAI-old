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
}
