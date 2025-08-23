#!/bin/bash
# Combine iOS Device and Simulator libraries for the various architectures
# into a single dynamic framework.

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

# Export framework at path.
export FRAMEWORK_LOCATION="${BUILT_PRODUCTS_DIR}/${FRAMEWORK_NAME}.xcframework"

createFramework() {
  TEMP_FRAMEWORK_LOCATION="${BUILD_DIR}/${CONFIGURATION}-$1/${FRAMEWORK_NAME}.framework"
  mkdir -p "${TEMP_FRAMEWORK_LOCATION}"

  # Build the static library for the specified sdk and architecture.
  xcodebuild -target Adapter \
  -configuration "${CONFIGURATION}" \
  -sdk "${1}" \
  ARCHS="${2}" \
  BUILD_DIR="${BUILD_DIR}" \
  BUILD_ROOT="${BUILD_ROOT}" \
  OBJROOT="${OBJROOT}/${1}" \
  ONLY_ACTIVE_ARCH=NO \
  SYMROOT="${SYMROOT}" \
  "${ACTION}"

  # Create framework using lipo.
  lipo -create "${BUILD_DIR}/${CONFIGURATION}-$1/${LIB_NAME}.a" -output "${TEMP_FRAMEWORK_LOCATION}/${FRAMEWORK_NAME}"

  # Create Modules directory and copy the module map inside.
  mkdir -p "${TEMP_FRAMEWORK_LOCATION}/Modules"
  /bin/cp -a "${BUILD_DIR}/${CONFIGURATION}-$1/${FRAMEWORK_NAME}.swiftmodule" "${TEMP_FRAMEWORK_LOCATION}/Modules/"

  # Create Headers directory and copy MolocoAdapter-Swift.h file
  mkdir -p "${TEMP_FRAMEWORK_LOCATION}/Headers/"
  /bin/cp -a "${OBJROOT}/${1}/MolocoAdapter.build/${CONFIGURATION}-${1}/Adapter.build/DerivedSources/MolocoAdapter-Swift.h" "${TEMP_FRAMEWORK_LOCATION}/Headers/"

  # Static library does not automatically generate an Info.plist file. Create
  # a fake framework to generate the Info.plist and then copy it into the
  # static library. Info.plist is required to allow embedding static frameworks
  # in Xcode 15.
  TEMP_FRAMEWORK_BUILD_DIR="${BUILD_DIR}/temp_framework_build_dir"
  TEMP_FRAMEWORK_ROOT_DIR="${BUILD_DIR}/temp_framework_root_dir"
  TEMP_FRAMEWORK_OBJROOT_DIR="${BUILD_DIR}/objroot_dir"
  TEMP_FRAMEWORK_SYMROOT_DIR="${BUILD_DIR}/symroot_dir"

  mkdir -p "${TEMP_FRAMEWORK_BUILD_DIR}"
  mkdir -p "${TEMP_FRAMEWORK_ROOT_DIR}"
  mkdir -p "${TEMP_FRAMEWORK_OBJROOT_DIR}"
  mkdir -p "${TEMP_FRAMEWORK_SYMROOT_DIR}"

  xcodebuild -target MolocoAdapter \
  -configuration "${CONFIGURATION}" \
  -sdk "${1}" \
  ARCHS="${2}" \
  BUILD_DIR="${TEMP_FRAMEWORK_BUILD_DIR}" \
  BUILD_ROOT="${TEMP_FRAMEWORK_ROOT_DIR}" \
  OBJROOT="${TEMP_FRAMEWORK_OBJROOT_DIR}/${1}" \
  ONLY_ACTIVE_ARCH=NO \
  SYMROOT="${TEMP_FRAMEWORK_SYMROOT_DIR}" \
  "build"

 install -m 0444 "${TEMP_FRAMEWORK_BUILD_DIR}/${CONFIGURATION}-$1/${FRAMEWORK_NAME}.framework/Info.plist" "${TEMP_FRAMEWORK_LOCATION}/Info.plist"
}

createFramework "iphoneos" "arm64"
createFramework "iphonesimulator" "arm64 x86_64"

# Create dynamic framework using the frameworks generated above.
xcodebuild -create-xcframework \
-framework "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework" \
-framework "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework" \
-output "${FRAMEWORK_LOCATION}/${FRAMEWORK_NAME}.xcframework"

# Copy the finalized xcframework to the Library directory.
ditto "${FRAMEWORK_LOCATION}" "${OUTPUT_FOLDER}"

# Remove if swiftmodule located at wrong location.
if [ -d "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework/ios-arm64_x86_64-simulator/${FRAMEWORK_NAME}.swiftmodule" ]; then
  rm -rf "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework/ios-arm64/${FRAMEWORK_NAME}.swiftmodule"
fi

# Remove if swiftmodule located at wrong location.

if [ -d "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework/ios-arm64_x86_64-simulator/${FRAMEWORK_NAME}.swiftmodule" ]; then
  rm -rf "${OUTPUT_FOLDER}/${FRAMEWORK_NAME}.xcframework/ios-arm64_x86_64-simulator/${FRAMEWORK_NAME}.swiftmodule"
fi
