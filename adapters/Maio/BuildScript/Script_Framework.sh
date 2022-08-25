#!/bin/bash
# Combine iOS Device and Simulator libraries for the various architectures
# into a single dynamic framework.

# Required for new build system
OBJROOT="${OBJROOT}/DependentBuilds"

# Remove build directories if exist.
if [ -d "${BUILT_PRODUCTS_DIR}" ]; then
  rm -rf "${BUILT_PRODUCTS_DIR}"
fi

# Remove framework if exists.
if [ -d "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework" ]; then
  rm -rf "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework"
fi

# Public headers directory.
export PUBLIC_HEADERS_FOLDER_PATH="${SRCROOT}/Public/Headers"

# Create output directory.
mkdir -p "${OUTPUT_FOLDER}"

# Export framework at path.
export FRAMEWORK_LOCATION="${BUILT_PRODUCTS_DIR}/${FRAMEWORK_NAME}.xcframework"

createFramework() {
  TEMP_FRAMEWORK_LOCATION="${BUILD_DIR}/${CONFIGURATION}-$1/${FRAMEWORK_NAME}.framework"

  # Create the path to the framework headers and copy the public headers inside.
  mkdir -p "${TEMP_FRAMEWORK_LOCATION}/Headers"
  ditto "${PUBLIC_HEADERS_FOLDER_PATH}" "${TEMP_FRAMEWORK_LOCATION}/Headers"

  # Build the static library for the specified sdk and architecture.
  xcodebuild -target Adapter \
  -configuration "${CONFIGURATION}" \
  -sdk "$1" \
  -UseModernBuildSystem=YES \
  ARCHS="$2" \
  BUILD_DIR="${BUILD_DIR}" \
  BUILD_ROOT="${BUILD_ROOT}" \
  OBJROOT="${OBJROOT}" \
  ONLY_ACTIVE_ARCH=NO \
  SYMROOT="${SYMROOT}" \
  "${ACTION}" \
  build

  # Create framework using lipo.
  lipo -create "${BUILD_DIR}/${CONFIGURATION}-$1/${LIB_NAME}.a" -output "${TEMP_FRAMEWORK_LOCATION}/${FRAMEWORK_NAME}"

  # Create Modules directory and copy the module map inside.
  mkdir -p "${TEMP_FRAMEWORK_LOCATION}/Modules"
  /bin/cp -a "${MODULE_MAP_PATH}/module.modulemap" "${TEMP_FRAMEWORK_LOCATION}/Modules/module.modulemap"
}

createFramework "iphoneos" "armv7 arm64"
createFramework "iphonesimulator" "arm64 x86_64"

# Create dynamic framework using the frameworks generated above.
xcodebuild -create-xcframework \
-framework "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework" \
-framework "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework" \
-output "${FRAMEWORK_LOCATION}/${FRAMEWORK_NAME}.xcframework"

# Copy the finalized xcframework to the Library directory.
ditto "${FRAMEWORK_LOCATION}" "${OUTPUT_FOLDER}"
