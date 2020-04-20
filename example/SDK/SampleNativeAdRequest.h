//
// Copyright (C) 2015 Google, Inc.
//
// SampleNativeAdRequest.h
// Sample Ad Network SDK
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

#import "SampleAdRequest.h"

/// Native ad image orientation preference.
typedef NS_ENUM(NSInteger, NativeAdImageOrientation) {
  NativeAdImageOrientationAny,       ///< No orientation preference.
  NativeAdImageOrientationPortrait,  ///< Prefer portrait images.
  NativeAdImageOrientationLandscape  ///< Prefer landscape images.
};

@interface SampleNativeAdRequest : SampleAdRequest

/// Indicates whether images should be downloaded automatically or returned as URL/scale values
/// instead.
@property(nonatomic, assign) BOOL shouldDownloadImages;

// For the sake of simplicity, the following two values are ignored by the Sample SDK's
// SampleNativeAdLoader class. They're included so that the custom event and adapter classes
// can demonstrate how to take a request from the Google Mobile Ads SDK and translate it
// into one for the Sample SDK.

/// Indicates the preferred image orientation.
@property(nonatomic, assign) NativeAdImageOrientation preferredImageOrientation;

/// Indicates whether multiple images should be returned for assets that offer them.
@property(nonatomic, assign) BOOL shouldRequestMultipleImages;

@end
