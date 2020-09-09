//
// Copyright (C) 2017 Google, Inc.
//
// sampleNativeAd.h
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
#import <UIKit/UIKit.h>

#import "SampleMediaView.h"

@interface SampleNativeAd : NSObject

/// The name of an advertiser.
@property(nonatomic, copy) NSString *advertiser;

/// The body text of the ad.
@property(nonatomic, copy) NSString *body;

/// The ad's call to action, such as "click here."
@property(nonatomic, copy) NSString *callToAction;

/// The ad's headline.
@property(nonatomic, copy) NSString *headline;

/// The icon image associated with the ad.
@property(nonatomic, strong) UIImage *icon;

/// The URL from which the icon image can be downloaded.
@property(nonatomic, copy) NSString *iconURL;

/// The scale of the image file (pixels/pts) that can be downloaded from iconURL.
@property(nonatomic, assign) CGFloat iconScale;

/// The main image associated with the ad.
@property(nonatomic, strong) UIImage *image;

/// The URL from which the ad's main image can be downloaded.
@property(nonatomic, copy) NSString *imageURL;

/// The scale of the image file (pixels/pts) that can be downloaded from imageURL.
@property(nonatomic, assign) CGFloat imageScale;

/// The main video associated with the ad.
@property(nonatomic, strong) SampleMediaView *mediaView;

/// The price of the app being advertised.
@property(nonatomic, copy) NSString *price;

/// The star rating of the advertised app.
@property(nonatomic, copy) NSDecimalNumber *starRating;

/// The store from which the app can be purchased.
@property(nonatomic, copy) NSString *store;

/// The ad's degree of awesomeness. This is a simple string field designed to show how
/// custom events and adapters can handle extra assets.
@property(nonatomic, copy) NSString *degreeOfAwesomeness;

/// Handles clicks on the native ad's assets (it just NSLogs them).
- (void)handleClickOnView:(UIView *)view;

/// Records impressions for the native ad (it just NSLogs them).
- (void)recordImpression;

/// Starts playing the video after the view is rendered
- (void)playVideo;

@end
