#!/bin/bash
# Combine iOS Device and Simulator libraries for the various architectures
# into a single framework.

# Remove build directories if exist.
if [ -d "${BUILT_PRODUCTS_DIR}" ]; then
rm -rf "${BUILT_PRODUCTS_DIR}"
fi

# Remove framework if exists.
if [ -d "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.framework" ]; then
rm -rf "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.framework"
fi

# Create output directory.
mkdir -p "${OUTPUT_FOLDER}"

# Export framework at path.
export FRAMEWORK_LOCATION="${BUILT_PRODUCTS_DIR}/${FRAMEWORK_NAME}.framework"

# Create the path to the real framework headers.
mkdir -p "${FRAMEWORK_LOCATION}/Versions/A/Headers"

# Create the required symlinks.
/bin/ln -sfh A "${FRAMEWORK_LOCATION}/Versions/Current"
/bin/ln -sfh Versions/Current/Headers "${FRAMEWORK_LOCATION}/Headers"
/bin/ln -sfh "Versions/Current/${FRAMEWORK_NAME}" \
"${FRAMEWORK_LOCATION}/${FRAMEWORK_NAME}"

# Build static library for iOS Device.
xcodebuild -target Adapter ONLY_ACTIVE_ARCH=NO -configuration "${CONFIGURATION}" clean build -sdk "iphoneos" ARCHS="armv7 armv7s arm64" BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" OBJROOT="${OBJROOT}" SYMROOT="${SYMROOT}" "${ACTION}" -UseModernBuildSystem=NO

# Build static library for iOS Simulator.
xcodebuild -target Adapter ONLY_ACTIVE_ARCH=NO -configuration "${CONFIGURATION}" clean build -sdk "iphonesimulator" ARCHS="i386 x86_64" BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" OBJROOT="${OBJROOT}" SYMROOT="${SYMROOT}" "${ACTION}" -UseModernBuildSystem=NO

# Create universal framework using lipo.
lipo -create "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${LIB_NAME}.a" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${LIB_NAME}.a" -output "${FRAMEWORK_LOCATION}/Versions/A/${FRAMEWORK_NAME}"

# Copy the public headers into the framework.
/bin/cp -a "${TARGET_BUILD_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}/" \
"${FRAMEWORK_LOCATION}/Versions/A/Headers"

# Copy the framework to the library directory.
ditto "${FRAMEWORK_LOCATION}" "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.framework"

# Create Modules directory.
mkdir -p "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.framework/Modules"

# Copy the module map to modules directory.
/bin/cp -a "${MODULE_MAP_PATH}/module.modulemap" "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.framework/Modules/module.modulemap"
