#include "native_sudoku_scanner.hpp"
#include "detection/grid_detector.hpp"
#include "dictionary/dictionary.hpp"
#include "extraction/grid_extractor.hpp"
#include "extraction/structs/cell.hpp"
#include <opencv2/opencv.hpp>

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct DetectionResult detect_grid(char *path) {
    // struct DetectionResult *coordinate = (struct DetectionResult *)malloc(sizeof(struct DetectionResult));
    cv::Mat mat = cv::imread(path);

    if (mat.size().width == 0 || mat.size().height == 0) {
        return DetectionResult{
            Coordinate{0, 0},
            Coordinate{1, 0},
            Coordinate{0, 1},
            Coordinate{1, 1}};
    }

    std::vector<cv::Point> points = GridDetector::detect_grid(mat);

    return DetectionResult{
        Coordinate{(double)points[0].x / mat.size().width, (double)points[0].y / mat.size().height},
        Coordinate{(double)points[1].x / mat.size().width, (double)points[1].y / mat.size().height},
        Coordinate{(double)points[2].x / mat.size().width, (double)points[2].y / mat.size().height},
        Coordinate{(double)points[3].x / mat.size().width, (double)points[3].y / mat.size().height}};
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int *extract_grid(char *path, DetectionResult detection_result) {
    assert(detection_result.top_left.x > 0 && detection_result.top_left.y > 0
            && detection_result.top_right.x > 0 && detection_result.top_right.y > 0
            && detection_result.bottom_left.x > 0 && detection_result.bottom_left.y > 0
            && detection_result.bottom_right.x > 0 && detection_result.bottom_right.x > 0);
    assert(detection_result.top_left.x <= detection_result.top_right.x
            && detection_result.top_left.x <= detection_result.bottom_right.x
            && detection_result.bottom_left.x <= detection_result.top_right.x
            && detection_result.bottom_left.x <= detection_result.bottom_right.x
            && detection_result.top_left.y <= detection_result.bottom_left.y
            && detection_result.top_left.y <= detection_result.bottom_right.y
            && detection_result.top_right.y <= detection_result.bottom_left.y
            && detection_result.top_right.y <= detection_result.bottom_right.y);

    cv::Mat mat = cv::imread(path);

    std::vector<int> grid = GridExtractor::extract_grid(
        mat,
        detection_result.top_left.x * mat.size().width,
        detection_result.top_left.y * mat.size().height,
        detection_result.top_right.x * mat.size().width,
        detection_result.top_right.y * mat.size().height,
        detection_result.bottom_left.x * mat.size().width,
        detection_result.bottom_left.y * mat.size().height,
        detection_result.bottom_right.x * mat.size().width,
        detection_result.bottom_right.y * mat.size().height);

    int *grid_ptr = (int*)malloc(grid.size() * sizeof(int));

    // copy grid_array to pointer
    for (int i = 0; i < grid.size(); ++i) {
        grid_ptr[i] = grid[i];
    }

    return grid_ptr;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int *extract_grid_from_roi(
    char *path,
    int roi_size,
    // offset from center of image
    int roi_offset) {

    cv::Mat image = cv::imread(path);

    assert(roi_size > 0 && roi_size <= image.size().width);
    assert(abs(roi_offset) < (image.size().height - roi_size) / 2);

    // get position of top left corner
    const int offset_w = (image.size().width - roi_size) / 2;
    const int offset_h = roi_offset + (image.size().height - roi_size) / 2;
    // get roi as rectangle
    const cv::Rect roi(offset_w, offset_h, roi_size, roi_size);

    // crop image so it only contains ROI
    image = image(roi);
    cv::Mat image_copy = image.clone();

    std::vector<cv::Point> points = GridDetector::detect_grid(image);

    std::vector<int> grid = GridExtractor::extract_grid(
        image_copy,
        points[0].x,
        points[0].y,
        points[1].x,
        points[1].y,
        points[2].x,
        points[2].y,
        points[3].x,
        points[3].y);

    int *grid_ptr = (int*)malloc(grid.size() * sizeof(int));

    // copy grid_array to pointer
    for (int i = 0; i < grid.size(); ++i) {
        grid_ptr[i] = grid[i];
    }

    return grid_ptr;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
bool debug_grid_detection(char *path) {
    cv::Mat thresholded;
    cv::Mat img = cv::imread(path);

    cv::cvtColor(img, img, cv::COLOR_BGR2GRAY);
    // always check parameters with grid_detector.cpp
    cv::adaptiveThreshold(img, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, 69, 20);

    return cv::imwrite(path, thresholded);
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
bool debug_grid_extraction(char *path, DetectionResult detection_result) {
    cv::Mat transformed;
    cv::Mat thresholded;
    cv::Mat img = cv::imread(path);

    cv::cvtColor(img, img, cv::COLOR_BGR2GRAY);
    transformed = GridExtractor::crop_and_transform(
        img,
        detection_result.top_left.x * img.size().width,
        detection_result.top_left.y * img.size().height,
        detection_result.top_right.x * img.size().width,
        detection_result.top_right.y * img.size().height,
        detection_result.bottom_left.x * img.size().width,
        detection_result.bottom_left.y * img.size().height,
        detection_result.bottom_right.x * img.size().width,
        detection_result.bottom_right.y * img.size().height);
    // always check parameters with grid_extractor.cpp
    cv::adaptiveThreshold(transformed, thresholded, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 63, 10);

    std::vector<Cell> cells = GridExtractor::extract_cells(thresholded, transformed);
    cv::Mat stitched = GridExtractor::stitch_cells(cells);

    return cv::imwrite(path, stitched);
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void set_model(char *path) {
    setenv(PATH_TO_MODEL_ENV_VAR, path, 1);
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void free_pointer(int *pointer) {
    free(pointer);
}
