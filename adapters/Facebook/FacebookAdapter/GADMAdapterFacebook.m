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

#import "GADMAdapterFacebook.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>

#import "GADFBAdapterDelegate.h"
#import "GADFBBannerAd.h"
#import "GADFBInterstitialAd.h"
#import "GADFBNativeAdBase.h"
#import "GADFBNativeBannerAd.h"
#import "GADFBNetworkExtras.h"
#import "GADFBUnifiedNativeAd.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@implementation GADMAdapterFacebook {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Facebook Audience Network banner ad wrapper.
  GADFBBannerAd *_bannerAd;

  /// Facebook Audience Network interstitial ad wrapper.
  GADFBInterstitialAd *_interstitialAd;

  /// Facebook Audience Network native ad wrapper.
  GADFBUnifiedNativeAd *_nativeAd;

  /// Facebook Audience Network native banner ad wrapper.
  GADFBNativeBannerAd *_nativeBannerAd;
}

+ (NSString *)adapterVersion {
  return kGADMAdapterFacebookVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADFBNetworkExtras class];
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterFacebook class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (![[GADMobileAds sharedInstance] isSDKVersionAtLeastMajor:7 minor:46 patch:0]) {
    NSLog(@"This version of the Facebook adapter requires a newer version of the Google Mobile Ads SDK.");
    return nil;
  }
  self = [self init];
  if (self) {
    _connector = connector;
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if ([strongConnector respondsToSelector:@selector(childDirectedTreatment)] &&
      [strongConnector childDirectedTreatment]) {
    [FBAdSettings setIsChildDirected:[[strongConnector childDirectedTreatment] boolValue]];
  }

  _bannerAd = [[GADFBBannerAd alloc] initWithGADMAdNetworkConnector:strongConnector adapter:self];
  [_bannerAd getBannerWithSize:adSize];
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if ([strongConnector respondsToSelector:@selector(childDirectedTreatment)] &&
      [strongConnector childDirectedTreatment]) {
    [FBAdSettings setIsChildDirected:[[strongConnector childDirectedTreatment] boolValue]];
  }

  _interstitialAd = [[GADFBInterstitialAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                        adapter:self];
  [_interstitialAd getInterstitial];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_interstitialAd presentInterstitialFromRootViewController:rootViewController];
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSNumber *childDirectedTreatmentValue = [strongConnector childDirectedTreatment];
  if (childDirectedTreatmentValue) {
    [FBAdSettings setIsChildDirected:childDirectedTreatmentValue.boolValue];
  }

  GADFBNetworkExtras *extras = strongConnector.networkExtras;
  if (extras.nativeAdFormat == GADFBAdFormatNativeBanner) {
    _nativeBannerAd = [[GADFBNativeBannerAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                          adapter:self];
    [_nativeBannerAd requestNativeBannerAd];
  } else {
    _nativeAd = [[GADFBUnifiedNativeAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                     adapter:self];
    [_nativeAd requestNativeAd];
  }
}

- (void)stopBeingDelegate {
  [_bannerAd stopBeingDelegate];
  [_interstitialAd stopBeingDelegate];
  [_nativeAd stopBeingDelegate];
  [_nativeBannerAd stopBeingDelegate];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

@end
