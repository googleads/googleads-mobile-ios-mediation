#!/bin/bash
# Combine iOS Device and Simulator libraries for the various architectures
# into a single fat library.


# Create output directory if it doesn't exist.
if [ ! -d "${OUTPUT_FOLDER}" ]; then
  mkdir -p "${OUTPUT_FOLDER}"
fi

# Step 1. Build static library for iOS Device.
xcodebuild -target Adapter ONLY_ACTIVE_ARCH=NO -configuration "${CONFIGURATION}" clean build -sdk "iphoneos" ARCHS="armv7 arm64" BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" OBJROOT="${OBJROOT}" SYMROOT="${SYMROOT}" "${ACTION}" -UseModernBuildSystem=NO

# Step 2. Build static library for iOS Simulator.
xcodebuild -target Adapter ONLY_ACTIVE_ARCH=NO -configuration "${CONFIGURATION}" clean build -sdk "iphonesimulator" ARCHS="i386 x86_64" BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" OBJROOT="${OBJROOT}" SYMROOT="${SYMROOT}" "${ACTION}" -UseModernBuildSystem=NO

# Step 3. Create universal fat library using lipo.
lipo -create "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${LIB_NAME}.a" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${LIB_NAME}.a" -output "${OUTPUT_FOLDER}/${FAT_LIBRARY_NAME}.a"
