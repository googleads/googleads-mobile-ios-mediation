//
// Copyright (C) 2015 Google, Inc.
//
// sampleNativeAd.m
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

#import "SampleNativeAd.h"

@implementation SampleNativeAd

- (void)handleClickOnView:(UIView *)view {
  NSLog(@"A click occurred on a sampleNativeAd!");
  // In a real SDK, some type of click action (such as the opening of the App Store)
  // would likely be initiated here.
}

- (void)recordImpression {
  NSLog(@"An impression was recorded for a sampleNativeAd!");
  // In a real SDK, some work would be done here to record the impression.
}

- (void)playVideo {
  [_mediaView playMedia];
}

@end
