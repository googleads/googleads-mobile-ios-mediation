#!/bin/bash
# Combine iOS Device and Simulator libraries for the various architectures
# into a single framework.

# Remove build directories if exist.
if [ -d "${BUILT_PRODUCTS_DIR}" ]; then
rm -rf "${BUILT_PRODUCTS_DIR}"
fi

# Remove framework if exists.
if [ -d "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework" ]; then
rm -rf "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework"
fi

# Create output directory.
mkdir -p "${OUTPUT_FOLDER}"

{
    BUILD_DIR_IPHONE=${BUILD_DIR}/iphone
    FRAMEWORK_LOCATION_IPHONE="${BUILD_DIR_IPHONE}/${FRAMEWORK_NAME}.framework"
    mkdir -p ${BUILD_DIR_IPHONE}

    xcodebuild archive -scheme Adapter -configuration "${CONFIGURATION}" -destination="generic/platform=iOS" -sdk iphoneos -archivePath $BUILD_DIR_IPHONE/archive ARCHS="armv7 arm64" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

    # Create the path to the real framework headers.
    mkdir -p "${FRAMEWORK_LOCATION_IPHONE}/Versions/A/Headers"

    # Create the required symlinks.
    /bin/ln -sfh A "${FRAMEWORK_LOCATION_IPHONE}/Versions/Current"
    /bin/ln -sfh Versions/Current/Headers "${FRAMEWORK_LOCATION_IPHONE}/Headers"
    /bin/ln -sfh "Versions/Current/${FRAMEWORK_NAME}" \
    "${FRAMEWORK_LOCATION_IPHONE}/${FRAMEWORK_NAME}"

    # Copy Static Library
    /bin/cp "${BUILD_DIR_IPHONE}/archive.xcarchive/Products/usr/local/lib/${LIB_NAME}.a" "${FRAMEWORK_LOCATION_IPHONE}/Versions/A/${FRAMEWORK_NAME}"
    # Copy Headers
    /bin/cp "${BUILD_DIR_IPHONE}/archive.xcarchive/Products/usr/local/lib/${PUBLIC_HEADERS_FOLDER_PATH}/"* "${FRAMEWORK_LOCATION_IPHONE}/Versions/A/Headers"

    # Create Modules directory.
    mkdir -p "${FRAMEWORK_LOCATION_IPHONE}/Modules"

    # Copy the module map to modules directory.
    /bin/cp -a "${MODULE_MAP_PATH}/module.modulemap" "${FRAMEWORK_LOCATION_IPHONE}/Modules/module.modulemap"
}

{
    BUILD_DIR_SIMULATOR=${BUILD_DIR}/iphonesimulator
    FRAMEWORK_LOCATION_SIMULATOR="${BUILD_DIR_SIMULATOR}/${FRAMEWORK_NAME}.framework"
    mkdir -p ${BUILD_DIR_SIMULATOR}

    xcodebuild archive -scheme Adapter -configuration "${CONFIGURATION}" -destination="generic/platform=iOS Simulator" -sdk iphonesimulator -archivePath $BUILD_DIR_SIMULATOR/archive ARCHS="arm64 i386 x86_64" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

    # Create the path to the real framework headers.
    mkdir -p "${FRAMEWORK_LOCATION_SIMULATOR}/Versions/A/Headers"

    # Create the required symlinks.
    /bin/ln -sfh A "${FRAMEWORK_LOCATION_SIMULATOR}/Versions/Current"
    /bin/ln -sfh Versions/Current/Headers "${FRAMEWORK_LOCATION_SIMULATOR}/Headers"
    /bin/ln -sfh "Versions/Current/${FRAMEWORK_NAME}" \
    "${FRAMEWORK_LOCATION_SIMULATOR}/${FRAMEWORK_NAME}"

    # Copy Static Library
    /bin/cp "${BUILD_DIR_SIMULATOR}/archive.xcarchive/Products/usr/local/lib/${LIB_NAME}.a" "${FRAMEWORK_LOCATION_SIMULATOR}/Versions/A/${FRAMEWORK_NAME}"
    /bin/cp "${BUILD_DIR_SIMULATOR}/archive.xcarchive/Products/usr/local/lib/${PUBLIC_HEADERS_FOLDER_PATH}/"* "${FRAMEWORK_LOCATION_SIMULATOR}/Versions/A/Headers"

    # Create Modules directory.
    mkdir -p "${FRAMEWORK_LOCATION_SIMULATOR}/Modules"

    # Copy the module map to modules directory.
    /bin/cp -a "${MODULE_MAP_PATH}/module.modulemap" "${FRAMEWORK_LOCATION_SIMULATOR}/Modules/module.modulemap"
}

xcodebuild -create-xcframework -framework ${FRAMEWORK_LOCATION_IPHONE} -framework ${FRAMEWORK_LOCATION_SIMULATOR} -output "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework"

open "${OUTPUT_FOLDER}"

