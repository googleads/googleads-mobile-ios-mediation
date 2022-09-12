// Copyright 2019 Google LLC
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

#import "GADMAdapterIMobileUnifiedNativeAd.h"

#import <ImobileSdkAds/ImobileSdkAds.h>

#import <stdatomic.h>

#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileUtils.h"
#import "GADMediationAdapterIMobile.h"

@interface GADMAdapterIMobileUnifiedNativeAd () <GADMediationNativeAd, IMobileSdkAdsDelegate>
@end

@implementation GADMAdapterIMobileUnifiedNativeAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationNativeAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationNativeLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  /// Intentionally keeping a reference to the delegate because this delegate is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationNativeAdEventDelegate> _delegate;

  /// View to display the i-mobile native ad.
  UIView *_iMobileNativeAdView;

  /// i-mobile native ad.
  ImobileSdkAdsNativeObject *_iMobileNativeAd;

  /// Ad image.
  GADNativeAdImage *_adImage;

  /// Ad image view.
  UIImageView *_adImageView;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationNativeAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadNativeAdWithCompletionHandler:
    (GADMediationNativeLoadCompletionHandler)completionHandler {
  __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationNativeLoadCompletionHandler originalAdLoadHandler = [completionHandler copy];

  // Ensure the original completion handler is only called once, and is deallocated once called.
  _loadCompletionHandler =
      ^id<GADMediationNativeAdEventDelegate>(id<GADMediationNativeAd> nativeAd, NSError *error) {
    if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
      return nil;
    }

    id<GADMediationNativeAdEventDelegate> delegate = nil;
    if (originalAdLoadHandler) {
      delegate = originalAdLoadHandler(nativeAd, error);
    }

    originalAdLoadHandler = nil;
    return delegate;
  };

  NSString *publisherID = _adConfiguration.credentials.settings[GADMAdapterIMobilePublisherIdKey];
  if (!publisherID.length) {
    NSString *errorMessage = @"Missing or invalid Publisher ID.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorInvalidServerParameters, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  NSString *mediaID = _adConfiguration.credentials.settings[GADMAdapterIMobileMediaIdKey];
  if (!mediaID.length) {
    NSString *errorMessage = @"Missing or invalid Media ID.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorInvalidServerParameters, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  NSString *spotID = _adConfiguration.credentials.settings[GADMAdapterIMobileSpotIdKey];
  if (!spotID.length) {
    NSString *errorMessage = @"Missing or invalid Spot ID.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorInvalidServerParameters, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  GADMAdapterIMobileLog(@"Requesting native ad with Spot ID: %@.", spotID);
  _iMobileNativeAdView = [[UIView alloc] init];

  // Call i-mobile SDK.
  [ImobileSdkAds registerWithPublisherID:publisherID MediaID:mediaID SpotID:spotID];
  [ImobileSdkAds startBySpotID:spotID];
  [ImobileSdkAds getNativeAdData:spotID
                            View:_iMobileNativeAdView
                          Params:[[ImobileSdkAdsNativeParams alloc] init]
                        Delegate:self];
}

#pragma mark - IMobileSdkAdsDelegate

- (void)onNativeAdDataReciveCompleted:(NSString *)spotId nativeArray:(NSArray<id> *)nativeArray {
  // Check ad data.
  if (nativeArray.count == 0) {
    NSString *errorMessage =
        @"i-mobile load success callback called, but with an empty array of ads.";
    GADMAdapterIMobileLog(@"%@", errorMessage);
    NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorEmptyNativeAdArray, errorMessage);
    _loadCompletionHandler(nil, error);
    return;
  }

  ImobileSdkAdsNativeObject *iMobileNativeAd = nativeArray[0];
  _iMobileNativeAd = iMobileNativeAd;

  // Get ad image.
  GADMAdapterIMobileUnifiedNativeAd *__weak weakSelf = self;
  [iMobileNativeAd getAdImageCompleteHandler:^(UIImage *_Nullable image) {
    GADMAdapterIMobileUnifiedNativeAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (!image) {
      NSString *errorMessage = @"Cannot download native ad assets.";
      GADMAdapterIMobileLog(@"%@", errorMessage);
      NSError *error = GADMAdapterIMobileErrorWithCodeAndDescription(
          GADMAdapterIMobileErrorNativeAssetsDownloadFailed, errorMessage);
      strongSelf->_loadCompletionHandler(nil, error);
      return;
    }

    strongSelf->_adImage = [[GADNativeAdImage alloc] initWithImage:image];
    strongSelf->_adImageView = [[UIImageView alloc] initWithImage:image];

    strongSelf->_delegate = strongSelf->_loadCompletionHandler(strongSelf, nil);
  }];
}

- (void)imobileSdkAdsSpot:(NSString *)spotId didFailWithValue:(ImobileSdkAdsFailResult)value {
  _iMobileNativeAdView = nil;
  NSString *errorMessage =
      [NSString stringWithFormat:@"Failed to get an ad for Spot ID: %@", spotId];
  GADMAdapterIMobileLog(@"%@", errorMessage);
  NSError *error = GADMAdapterIMobileErrorWithFailResultAndDescription(value, errorMessage);
  _loadCompletionHandler(nil, error);
}

#pragma mark - GADMediatedUnifiedNativeAd

- (NSString *)headline {
  return [_iMobileNativeAd getAdTitle];
}

- (NSArray<GADNativeAdImage *> *)images {
  return @[ _adImage ];
}

- (NSString *)body {
  return [_iMobileNativeAd getAdDescription];
}

- (GADNativeAdImage *)icon {
  // Creates a 40 x 40 transparent image which acts as a placeholder image as the I-Mobile
  // SDK does not send any image asset for the icon.
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(40, 40)];
  UIImage *image =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){
      }];
  return [[GADNativeAdImage alloc] initWithImage:image];
}

- (NSString *)callToAction {
  return GADMAdapterIMobileCallToAction;
}

- (NSDecimalNumber *)starRating {
  return nil;
}

- (NSString *)store {
  return nil;
}

- (NSString *)price {
  return nil;
}

- (NSString *)advertiser {
  return [_iMobileNativeAd getAdSponsored];
}

- (NSDictionary<NSString *, id> *)extraAssets {
  return nil;
}

- (UIView *)adChoicesView {
  // i-mobile does not render an Ad Choices view for their native ads.
  return nil;
}

- (UIView *)mediaView {
  return _adImageView;
}

- (CGFloat)mediaContentAspectRatio {
  if (_adImageView.image.size.height > 0) {
    return _adImageView.image.size.width / _adImageView.image.size.height;
  }
  return 0.0f;
}

- (void)didRecordClickOnAssetWithName:(GADNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  [_iMobileNativeAd sendClick];
  [_delegate willBackgroundApplication];
}

@end
