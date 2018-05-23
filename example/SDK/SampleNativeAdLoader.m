//
// Copyright (C) 2015 Google, Inc.
//
// SampleNativeAdLoader.m
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

#import "SampleNativeAdLoader.h"

#import "SampleMediaView.h"
#import "SampleNativeAd.h"

@interface SampleNativeAdLoader ()

@property(nonatomic, strong) NSArray *adTypes;
@property(nonatomic, strong) NSArray *options;

@end

@implementation SampleNativeAdLoader

/// Initialize
- (instancetype)initWithAdUnitID:(NSString *)adUnitID
                         adTypes:(NSArray *)adTypes
                         options:(NSArray *)options {
  self = [super init];
  if (self) {
    _adUnitID = [adUnitID copy];
    _adTypes = [adTypes copy];
    _options = [options copy];
  }
  return self;
}

/// Request a native ad.
- (void)fetchAd:(SampleNativeAdRequest *)request {
  // If the publisher didn't set an ad unit, return a bad request.
  if (!self.adUnitID) {
    [self.delegate adLoader:self didFailToLoadAdWithErrorCode:SampleErrorCodeBadRequest];
    return;
  }

  // Calculate a random value, so the SDK can occasionally fake bad results as well as good ones.
  int randomValue = arc4random_uniform(100);

  if (randomValue < 85) {
    // The SDK will return two types of ads in roughly 50/50 proportions
    [self.delegate adLoader:self didReceiveNativeAd:[self createFakeNativeAdForRequest:request]];
  } else if (randomValue < 90) {
    NSLog(@"Sample SDK is pretending to fail with an unknown error!");
    [self.delegate adLoader:self didFailToLoadAdWithErrorCode:SampleErrorCodeUnknown];
  } else if (randomValue < 95) {
    NSLog(@"Sample SDK is pretending to fail with a network error!");
    [self.delegate adLoader:self didFailToLoadAdWithErrorCode:SampleErrorCodeNetworkError];
  } else {
    NSLog(@"Sample SDK is pretending to fail with no fill!");
    [self.delegate adLoader:self didFailToLoadAdWithErrorCode:SampleErrorCodeNoInventory];
  }
}

/// Construct a simple, "dummy" ad that the SDK can return.
- (SampleNativeAd *)createFakeNativeAdForRequest:(SampleNativeAdRequest *)request {
  SampleNativeAd *newAd = [[SampleNativeAd alloc] init];
  int randomValue = arc4random_uniform(100);

  if (randomValue > 50) {
    // Create a fake ad by an advertiser with generic content.
    newAd.body =
        @"This is a sample ad, so there's no real content. In the event of a real "
        @"ad, though, some persuasive text would appear here.";
    newAd.callToAction = @"Take Action";
    newAd.headline = @"Sample Content!";
    newAd.advertiser = @"An advertiser";
    newAd.degreeOfAwesomeness = @"Fairly Awesome!";
    newAd.mediaView = [[SampleMediaView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [newAd.mediaView createMediaContent];
  } else {
    // Create a fake ad for an App.
    newAd.body = @"This app doesn't actually exist.";
    newAd.callToAction = @"Take Action";
    newAd.headline = @"Sample App!";
    newAd.price = @"$1.99";
    newAd.starRating = [[NSDecimalNumber alloc] initWithDouble:4.5];
    newAd.store = @"Sample Store";
    newAd.degreeOfAwesomeness = @"Quite Awesome!";
    newAd.mediaView = [[SampleMediaView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [newAd.mediaView createMediaContent];
  }

  // If this were a real SDK, it would check some of the other image options in the request. To keep
  // things simple, though, it'll just obey shouldDownloadImages.
  if (request.shouldDownloadImages) {
    newAd.icon = [self createImageFromColor:[UIColor colorWithRed:0 green:0 blue:0.8 alpha:1]
                                    andRect:CGRectMake(0, 0, 50, 50)];
    newAd.image = [self createImageFromColor:[UIColor colorWithRed:0 green:0.8 blue:0 alpha:1]
                                     andRect:CGRectMake(0, 0, 300, 150)];
  } else {
    // These links aren't actually valid. If you'd like to see the Sample SDK return images as URL
    // values rather than images (you'll need to change the native ad options in the request that's
    // sent in by the custom event or adapter), replace these URLs with ones pointing to valid
    // images. There are a number of image placeholder generators online that can help with this.
    newAd.iconURL = @"https://www.example.com/some_image.gif";
    newAd.iconScale = 1;
    newAd.imageURL = @"https://www.example.com/some_other_image.gif";
    newAd.imageScale = 1;
  }

  return newAd;
}

/// Create a UIImage object with the given color and dimensions.
- (UIImage *)createImageFromColor:(UIColor *)color andRect:(CGRect)rect {
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextFillRect(context, rect);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

@end
