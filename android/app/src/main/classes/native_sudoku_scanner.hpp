struct Coordinate {
    double x;
    double y;
};

struct DetectionResult {
    Coordinate *topLeft;
    Coordinate *topRight;
    Coordinate *bottomLeft;
    Coordinate *bottomRight;
};

extern "C" struct ProcessingInput {
    char *path;
    DetectionResult detectionResult;
};

extern "C" struct DetectionResult *detect_grid(char *path);

extern "C" int *extract_grid(
    char *path,
    double topLeftX,
    double topLeftY,
    double topRightX,
    double topRightY,
    double bottomLeftX,
    double bottomLeftY,
    double bottomRightX,
    double bottomRightY);

extern "C" int *extract_grid_from_roi(
    char *path,
    double roiSize,
    double roiOffset,
    double aspectRatio);

extern "C" bool debug_grid_detection(char *path);

extern "C" bool debug_grid_extraction(
    char *path,
    double topLeftX,
    double topLeftY,
    double topRightX,
    double topRightY,
    double bottomLeftX,
    double bottomLeftY,
    double bottomRightX,
    double bottomRightY);

extern "C" void set_model(char *path);
