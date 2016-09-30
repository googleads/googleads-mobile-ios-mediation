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
#import "SampleNativeAdRequest.h"
#import "SampleNativeAppInstallAd.h"
#import "SampleNativeContentAd.h"

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
    // If both ad types were requested, the SDK will return both in roughly 50/50 proportions
    if (request.appInstallAdsRequested && (!request.contentAdsRequested || (randomValue < 43))) {
      [self.delegate adLoader:self
          didReceiveNativeAppInstallAd:[self createFakeNativeAppInstallAdForRequest:request]];
    } else {
      [self.delegate adLoader:self
          didReceiveNativeContentAd:[self createFakeNativeContentAdForRequest:request]];
    }
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

/// Construct a simple, "dummy" content ad that the SDK can return.
- (SampleNativeContentAd *)createFakeNativeContentAdForRequest:(SampleNativeAdRequest *)request {
  SampleNativeContentAd *newContentAd = [[SampleNativeContentAd alloc] init];
  newContentAd.body = @"This is a sample ad, so there's no real content. In the event of a real "
      @"ad, though, some persuasive text would appear here.";
  newContentAd.callToAction = @"Take Action";
  newContentAd.headline = @"Sample Content!";
  newContentAd.degreeOfAwesomeness = @"Fairly Awesome!";

  // If this were a real SDK, it would check some of the other image options in the request. To keep
  // things simple, though, it'll just obey shouldDownloadImages.
  if (request.shouldDownloadImages) {
    newContentAd.logo = [self createImageFromColor:[UIColor colorWithRed:0 green:0 blue:0.8 alpha:1]
                                           andRect:CGRectMake(0, 0, 50, 50)];
    newContentAd.image =
        [self createImageFromColor:[UIColor colorWithRed:0 green:0.8 blue:0 alpha:1]
                           andRect:CGRectMake(0, 0, 300, 150)];
  } else {
    // These links aren't actually valid. If you'd like to see the Sample SDK return images as URL
    // values rather than images (you'll need to change the native ad options in the request that's
    // sent in by the custom event or adapter), replace these URLs with ones pointing to valid
    // images. There are a number of image placeholder generators online that can help with this.
    newContentAd.logoURL = @"https://www.example.com/some_image.gif";
    newContentAd.logoScale = 1;
    newContentAd.imageURL = @"https://www.example.com/some_other_image.gif";
    newContentAd.imageScale = 1;
  }

  return newContentAd;
}

/// Construct a simple, "dummy" app install ad that the SDK can return.
- (SampleNativeAppInstallAd *)createFakeNativeAppInstallAdForRequest:
        (SampleNativeAdRequest *)request {
  SampleNativeAppInstallAd *newAppInstallAd = [[SampleNativeAppInstallAd alloc] init];
  newAppInstallAd.body = @"This app doesn't actually exist.";
  newAppInstallAd.callToAction = @"Take Action";
  newAppInstallAd.headline = @"Sample App!";
  newAppInstallAd.price = @"$1.99";
  newAppInstallAd.starRating = [[NSDecimalNumber alloc] initWithDouble:4.5];
  newAppInstallAd.store = @"Sample Store";
  newAppInstallAd.degreeOfAwesomeness = @"Quite Awesome!";

  // If this were a real SDK, it would check some of the other image options in the request. To keep
  // things simple, though, it'll just obey shouldDownloadImages.
  if (request.shouldDownloadImages) {
    newAppInstallAd.icon =
        [self createImageFromColor:[UIColor colorWithRed:0 green:0 blue:0.8 alpha:1]
                           andRect:CGRectMake(0, 0, 50, 50)];
    newAppInstallAd.image =
        [self createImageFromColor:[UIColor colorWithRed:0 green:0.8 blue:0 alpha:1]
                           andRect:CGRectMake(0, 0, 200, 150)];
  } else {
    // These links aren't actually valid. If you'd like to see the Sample SDK return images as URL
    // values rather than images (you'll need to change the native ad options in the request that's
    // sent in by the custom event or adapter), replace these URLs with ones pointing to valid
    // images. There are a number of image placeholder generators online that can help with this.
    newAppInstallAd.iconURL = @"https://www.example.com/some_image.gif";
    newAppInstallAd.iconScale = 1;
    newAppInstallAd.imageURL = @"https://www.example.com/some_other_image.gif";
    newAppInstallAd.imageScale = 1;
  }

  return newAppInstallAd;
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
