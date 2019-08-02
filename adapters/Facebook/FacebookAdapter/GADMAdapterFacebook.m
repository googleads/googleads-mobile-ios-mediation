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
#import "GADFBError.h"
#import "GADFBInterstitialAd.h"
#import "GADFBNativeAd.h"
#import "GADFBNetworkExtras.h"
#import "GADFBUnifiedNativeAd.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADMAdapterFacebook () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Facebook Audience Network banner ad wrapper.
  GADFBBannerAd *_bannerAd;

  /// Facebook Audience Network interstitial ad wrapper.
  GADFBInterstitialAd *_interstitialAd;

  /// Facebook Audience Network native ad wrapper.
  GADFBNativeAd *_nativeAd;

  /// Facebook Audience Network native ad wrapper.
  GADFBUnifiedNativeAd *_unifiedNativeAd;
}
@end

@implementation GADMAdapterFacebook

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
  if (![[GADMobileAds sharedInstance] isSDKVersionAtLeastMajor:7 minor:12 patch:0]) {
    NSLog(@"Unsupported SDK. GoogleMobileAds SDK version 7.12.0 or higher is required.");
    return nil;
  }
  self = [self init];
  if (self) {
    _bannerAd = [[GADFBBannerAd alloc] initWithGADMAdNetworkConnector:connector adapter:self];
    _interstitialAd = [[GADFBInterstitialAd alloc] initWithGADMAdNetworkConnector:connector
                                                                          adapter:self];
    _nativeAd = [[GADFBNativeAd alloc] initWithGADMAdNetworkConnector:connector adapter:self];
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
  [_bannerAd getBannerWithSize:adSize];
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if ([strongConnector respondsToSelector:@selector(childDirectedTreatment)] &&
      [strongConnector childDirectedTreatment]) {
    [FBAdSettings setIsChildDirected:[[strongConnector childDirectedTreatment] boolValue]];
  }
  [_interstitialAd getInterstitial];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_interstitialAd presentInterstitialFromRootViewController:rootViewController];
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if ([strongConnector respondsToSelector:@selector(childDirectedTreatment)] &&
      [strongConnector childDirectedTreatment]) {
    [FBAdSettings setIsChildDirected:[strongConnector childDirectedTreatment].boolValue];
  }
  if ([adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative]) {
    _unifiedNativeAd = [[GADFBUnifiedNativeAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                            adapter:self];
    [_unifiedNativeAd getNativeAdWithAdTypes:adTypes options:options];
  } else {
    _nativeAd = [[GADFBNativeAd alloc] initWithGADMAdNetworkConnector:strongConnector adapter:self];
    [_nativeAd getNativeAdWithAdTypes:adTypes options:options];
  }
}

- (void)stopBeingDelegate {
  [_bannerAd stopBeingDelegate];
  [_interstitialAd stopBeingDelegate];
  [_nativeAd stopBeingDelegate];
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
