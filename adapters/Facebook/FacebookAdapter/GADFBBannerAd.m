// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADFBBannerAd.h"

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#import "GADFBAdapterDelegate.h"
#import "GADFBError.h"
#import "GADMAdapterFacebookConstants.h"

@interface GADFBBannerAd () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Banner ad obtained from Facebook's Audience Network.
  FBAdView *_bannerAd;

  /// Handles delegate notifications from bannerAd.
  GADFBAdapterDelegate *_adapterDelegate;
}
@end

/// Converts ad size from Google Mobile Ads SDK to ad size interpreted by Facebook Audience Network.
static FBAdSize GADFBAdSizeFromAdSize(GADAdSize gadAdSize, NSError *__autoreleasing *error) {
  CGSize gadAdCGSize = CGSizeFromGADAdSize(gadAdSize);
  GADAdSize banner50 =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight50Banner.size.height));
  GADAdSize banner90 =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight90Banner.size.height));
  GADAdSize mRect =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight250Rectangle.size.height));
  GADAdSize interstitial = GADAdSizeFromCGSize(kFBAdSizeInterstitial.size);
  NSArray *potentials = @[
    NSValueFromGADAdSize(banner50), NSValueFromGADAdSize(banner90), NSValueFromGADAdSize(mRect),
    NSValueFromGADAdSize(interstitial)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == kFBAdSizeHeight50Banner.size.height) {
    return kFBAdSizeHeight50Banner;
  } else if (size.height == kFBAdSizeHeight90Banner.size.height) {
    return kFBAdSizeHeight90Banner;
  } else if (size.height == kFBAdSizeHeight250Rectangle.size.height) {
    return kFBAdSizeHeight250Rectangle;
  } else if (CGSizeEqualToSize(size, kFBAdSizeInterstitial.size)) {
    return kFBAdSizeInterstitial;
  }

  if (error) {
    NSDictionary *params = @{
      NSLocalizedDescriptionKey :
          [NSString stringWithFormat:@"Invalid size (%@) for Facebook mediation adapter.",
                                     NSStringFromGADAdSize(gadAdSize)]
    };
    *error = [NSError errorWithDomain:kGADErrorDomain
                                 code:kGADErrorMediationInvalidAdSize
                             userInfo:params];
  }

  FBAdSize fbSize;
  fbSize.size = CGSizeZero;
  return fbSize;
}

@implementation GADFBBannerAd

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;

    _adapterDelegate = [[GADFBAdapterDelegate alloc] initWithAdapter:adapter connector:connector];
  }
  return self;
}

- (instancetype)init {
  return nil;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector || !strongAdapter) {
    return;
  }

  NSError *error = nil;
  FBAdSize size = GADFBAdSizeFromAdSize(adSize, &error);
  if (error) {
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  // -[FBAdView initWithPlacementID:adSize:rootViewController:] throws an NSInvalidArgumentException
  // if the root view controller is nil.
  UIViewController *rootViewController = [strongConnector viewControllerForPresentingModalView];
  if (!rootViewController) {
    error = GADFBErrorWithDescription(@"Root view controller cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  // -[FBAdView initWithPlacementID:adSize:rootViewController:] throws an NSInvalidArgumentException
  // if the placement ID is nil.
  NSString *placementID = [strongConnector publisherId];
  if (!placementID) {
    error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _bannerAd = [[FBAdView alloc] initWithPlacementID:placementID
                                             adSize:size
                                 rootViewController:rootViewController];
  if (!_bannerAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBAdView class])];
    NSError *error = GADFBErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _bannerAd.delegate = _adapterDelegate;

  if (size.size.width < 0) {
    _adapterDelegate.finalBannerSize = adSize.size;
  }
  [FBAdSettings setMediationService:[NSString
      stringWithFormat:@"GOOGLE_%@:%@", [GADRequest sdkVersion], kGADMAdapterFacebookVersion]];
  [_bannerAd loadAd];
}

- (void)stopBeingDelegate {
  _adapterDelegate = nil;
}

@end
