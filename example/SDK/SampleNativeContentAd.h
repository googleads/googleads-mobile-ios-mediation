//
// Copyright (C) 2015 Google, Inc.
//
// SampleNativeContentAd.h
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

@import Foundation;
@import GoogleMobileAds;

@interface SampleNativeContentAd : NSObject

/// The name of an advertiser.
@property(nonatomic, copy) NSString *advertiser;

/// The body text of the ad.
@property(nonatomic, copy) NSString *body;

/// The ad's call to action, such as "click here."
@property(nonatomic, copy) NSString *callToAction;

/// The ad's headline.
@property(nonatomic, copy) NSString *headline;

/// The main image associated with the ad.
@property(nonatomic, strong) UIImage *image;

/// The URL from which the ad's main image can be downloaded.
@property(nonatomic, copy) NSString *imageURL;

/// The scale of the image file (pixels/pts) that can be downloaded from imageURL.
@property(nonatomic, assign) CGFloat imageScale;

/// The logo image associated with the ad.
@property(nonatomic, strong) UIImage *logo;

/// The URL from which the logo image can be downloaded.
@property(nonatomic, copy) NSString *logoURL;

/// The scale of the image file (pixels/pts) that can be downloaded from logoURL.
@property(nonatomic, assign) CGFloat logoScale;

/// The ad's degree of awesomeness. This is a simple string field designed to show how
/// custom events and adapters can handle extra assets.
@property(nonatomic, copy) NSString *degreeOfAwesomeness;

/// Handles clicks on the native ad's assets (it just NSLogs them).
- (void)handleClickOnView:(UIView *)view;

/// Records impressions for the native ad (it just NSLogs them).
- (void)recordImpression;

@end
