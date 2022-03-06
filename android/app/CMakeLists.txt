cmake_minimum_required(VERSION 3.6.0)

# Include dirs
include_directories(../../include)

# sudoku scanner (main app)
set(CLASSES_DIR "src/main/classes")
set(SOURCES
    ${CLASSES_DIR}/native_sudoku_scanner.cpp
    ${CLASSES_DIR}/detection/grid_detector.cpp
    ${CLASSES_DIR}/extraction/grid_extractor.cpp
    ${CLASSES_DIR}/extraction/classification/number_classifier.cpp
)
add_library(native_sudoku_scanner SHARED ${SOURCES})

# OpenCV
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

# Tensorflow Lite
add_library(tensorflowlite SHARED IMPORTED)
set_target_properties(tensorflowlite PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libtensorflowlite_jni.so)

# Android Log
find_library(log-lib log)

# Build App as Library
target_link_libraries(native_sudoku_scanner lib_opencv tensorflowlite ${log-lib})
