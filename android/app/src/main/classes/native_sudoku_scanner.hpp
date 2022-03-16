struct Coordinate {
    double x;
    double y;
};

struct DetectionResult {
    Coordinate top_left;
    Coordinate top_right;
    Coordinate bottom_left;
    Coordinate bottom_right;
};

extern "C" struct DetectionResult detect_grid(char *path);

extern "C" int *extract_grid(
    char *path,
    DetectionResult detection_result);

extern "C" int *extract_grid_from_roi(
    char *path,
    int roi_size,
    int roi_offset);

extern "C" bool debug_grid_detection(char *path);

extern "C" bool debug_grid_extraction(char *path, DetectionResult detection_result);

extern "C" void set_model(char *path);

extern "C" void free_pointer(int *pointer);
