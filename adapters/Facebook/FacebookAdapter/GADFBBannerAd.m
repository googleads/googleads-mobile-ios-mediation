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

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADFBAdapterDelegate.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

/// Converts ad size from Google Mobile Ads SDK to ad size interpreted by Facebook Audience Network.
static FBAdSize GADFBAdSizeFromAdSize(GADAdSize gadAdSize, NSError *__autoreleasing *error) {
  CGSize gadAdCGSize = CGSizeFromGADAdSize(gadAdSize);
  GADAdSize banner50 =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight50Banner.size.height));
  GADAdSize banner90 =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight90Banner.size.height));
  GADAdSize mRect =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight250Rectangle.size.height));
  NSArray *potentials = @[
    NSValueFromGADAdSize(banner50), NSValueFromGADAdSize(banner90), NSValueFromGADAdSize(mRect)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == kFBAdSizeHeight50Banner.size.height) {
    return kFBAdSizeHeight50Banner;
  } else if (size.height == kFBAdSizeHeight90Banner.size.height) {
    return kFBAdSizeHeight90Banner;
  } else if (size.height == kFBAdSizeHeight250Rectangle.size.height) {
    return kFBAdSizeHeight250Rectangle;
  }

  if (error) {
    NSString *description =
        [NSString stringWithFormat:@"Invalid size for Facebook mediation adapter. Size: %@",
                                   NSStringFromGADAdSize(gadAdSize)];
    *error = GADFBErrorWithCodeAndDescription(GADFBErrorBannerSizeMismatch, description);
  }

  FBAdSize fbSize = {0};
  return fbSize;
}

@implementation GADFBBannerAd {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Banner ad obtained from Facebook's Audience Network.
  FBAdView *_bannerAd;

  /// Handles delegate notifications from bannerAd.
  GADFBAdapterDelegate *_adapterDelegate;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;

    _adapterDelegate = [[GADFBAdapterDelegate alloc] initWithAdapter:adapter connector:connector];
  }
  return self;
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
    error = GADFBErrorWithCodeAndDescription(GADFBErrorRootViewControllerNil,
                                             @"Root view controller cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  // -[FBAdView initWithPlacementID:adSize:rootViewController:] throws an NSInvalidArgumentException
  // if the placement ID is nil.
  NSString *placementID = [strongConnector publisherId];
  if (!placementID) {
    error =
        GADFBErrorWithCodeAndDescription(GADFBErrorInvalidRequest, @"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _bannerAd = [[FBAdView alloc] initWithPlacementID:placementID
                                             adSize:size
                                 rootViewController:rootViewController];
  if (!_bannerAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBAdView class])];
    NSError *error = GADFBErrorWithCodeAndDescription(GADFBErrorAdObjectNil, description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _bannerAd.delegate = _adapterDelegate;

  if (size.size.width < 0) {
    _adapterDelegate.finalBannerSize = adSize.size;
  }
  GADFBConfigureMediationService();
  [_bannerAd loadAd];
}

- (void)stopBeingDelegate {
  _adapterDelegate = nil;
}

@end
