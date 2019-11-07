// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterIMobile.h"
#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileUtils.h"

/// Ad type.
typedef NS_ENUM(NSUInteger, GADMAdapterImobileAdType) {
  GADMAdapterImobileAdTypeUnKnown,     ///< Unknown adapter type.
  GADMAdapterImobileAdTypeBanner,      ///< Banner adapter type.
  GADMAdapterImobileAdTypeInterstitial ///< Interstitial adapter type.
};

/// Adapter for banner and interstitial ads.
@interface IMobileAdapter ()

@end

@implementation IMobileAdapter {
  /// Connector for AdMob.
  __weak id<GADMAdNetworkConnector> _connector;

  /// View to display ads.
  UIView *_imobileAdView;

  /// Ad type.
  GADMAdapterImobileAdType _adType;

  /// i-mobile spot id.
  NSString *_spotID;
}

#pragma mark - GADMAdNetworkAdapter

+ (NSString *)adapterVersion {
  return kGADMAdapterIMobileVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    // Initialize.
    _connector = connector;
    _adType = GADMAdapterImobileAdTypeUnKnown;

    // Get parameters for i-mobile SDK.
    NSDictionary<NSString *, NSString *> *params = connector.credentials;
    NSString *publisherId = params[kGADMAdapterIMobilePublisherIdKey];
    NSString *mediaId = params[kGADMAdapterIMobileMediaIdKey];
    _spotID = params[kGADMAdapterIMobileSpotIdKey];

    // Call i-mobile SDK.
    [ImobileSdkAds registerWithPublisherID:publisherId MediaID:mediaId SpotID:_spotID];
    [ImobileSdkAds setSpotDelegate:_spotID delegate:self];
    [ImobileSdkAds startBySpotID:_spotID];
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  // Ad type is banner.
  _adType = GADMAdapterImobileAdTypeBanner;

  // Create view to display ads.
  GADAdSize imobileAdSize = GADMAdapterIMobileAdSizeFromGADAdSize(adSize);
  if (!IsGADAdSizeValid(imobileAdSize)) {
    NSString *errorString =
        [NSString stringWithFormat:@"Invalid size for i-mobile adapter. Size: %@",
                                   NSStringFromGADAdSize(adSize)];
    GADMAdapterIMobileLog(@"%@", errorString);
    NSError *error =
        GADMAdapterIMobileErrorWithCodeAndDescription(kGADErrorMediationInvalidAdSize, errorString);
    [_connector adapter:self didFailAd:error];
    return;
  }

  GADMAdapterIMobileLog(@"Requesting banner ad of size %@ for spotID %@",
                        NSStringFromGADAdSize(adSize), _spotID);

  _imobileAdView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, imobileAdSize.size.width, imobileAdSize.size.height)];

  // Call i-mobile SDK.
  [ImobileSdkAds showBySpotIDForAdMobMediation:_spotID View:_imobileAdView];
}

- (void)getInterstitial {
  // Ad type is interstitial.
  _adType = GADMAdapterImobileAdTypeInterstitial;

  // Call i-mobile SDK.
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if ([ImobileSdkAds getStatusBySpotID:_spotID] == IMOBILESDKADS_STATUS_READY) {
    [strongConnector adapterDidReceiveInterstitial:self];
  }
}

- (void)stopBeingDelegate {
  _imobileAdView = nil;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterWillPresentInterstitial:self];
  [ImobileSdkAds showBySpotID:_spotID];
}

#pragma mark - IMobileSdkAdsDelegate

- (void)imobileSdkAdsSpot:(NSString *)spotId
        didReadyWithValue:(ImobileSdkAdsReadyResult)value {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  switch (_adType) {
    case GADMAdapterImobileAdTypeUnKnown:
      GADMAdapterIMobileLog(@"Unknown adapter type.");
      break;
    case GADMAdapterImobileAdTypeBanner:
      [strongConnector adapter:self didReceiveAdView:_imobileAdView];
      break;
    case GADMAdapterImobileAdTypeInterstitial:
      [strongConnector adapterDidReceiveInterstitial:self];
      break;
  }
}

- (void)imobileSdkAdsSpot:(NSString *)spotId
         didFailWithValue:(ImobileSdkAdsFailResult)value {
  [self stopBeingDelegate];
  NSInteger errorCode = GADMAdapterIMobileAdMobErrorFromIMobileResult(value);
  NSString *errorString = [NSString stringWithFormat:@"Failed to get an ad for spotID: %@", spotId];
  GADMAdapterIMobileLog(@"%@", errorString);
  NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(errorCode, errorString);

  [_connector adapter:self didFailAd:error];
}

- (void)imobileSdkAdsSpotDidClick:(NSString *)spotId {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
}

// This only gets called for interstitial ads.
- (void)imobileSdkAdsSpotDidClose:(NSString *)spotId {
  [_connector adapterDidDismissInterstitial:self];
}

@end
