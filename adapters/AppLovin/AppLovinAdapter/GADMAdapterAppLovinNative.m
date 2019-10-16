//
//  GADMAdapterAppLovinNative.m
//  SDK Network Adapters Test App
//
//  Created by Santosh Bagadi on 4/11/18.
//  Copyright © 2018 AppLovin Corp. All rights reserved.
//

#import "GADMAdapterAppLovinNative.h"

#import <AppLovinSDK/AppLovinSDK.h>
#import "GADMAdapterAppLovin.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAppLovinMediatedNativeUnifiedAd.h"

@interface GADMAdapterAppLovinNative () <ALNativeAdLoadDelegate, ALNativeAdPrecacheDelegate>

@end

@implementation GADMAdapterAppLovinNative {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Instance of the AppLovin SDK.
  ALSdk *_sdk;
}

+ (NSString *)adapterVersion {
  return GADMAdapterAppLovinAdapterVersion;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
    _sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:connector.credentials];
  }
  return self;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  if (!_sdk) {
    [GADMAdapterAppLovinUtils log:@"Failed to retrieve SDK instance"];
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, @"Failed to retrieve AppLovin SDK for native adapter.");
    [_connector adapter:self didFailAd:error];
    return;
  }
  [_sdk.nativeAdService loadNextAdAndNotify:self];
}

- (void)stopBeingDelegate {
  _connector = nil;
}

#pragma mark - AppLovin Native Load Delegate Methods

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didFailToLoadAdsWithError:(NSInteger)code {
  [self notifyFailureWithErrorCode:[GADMAdapterAppLovinUtils toAdMobErrorCode:(int)code]
                       description:@"Failed to load native ads."];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service didLoadAds:(nonnull NSArray *)ads {
  if (ads.count > 0 &&
      [GADMAdapterAppLovinNative containsRequiredUnifiedNativeAssets:[ads firstObject]]) {
    [service precacheResourcesForNativeAd:[ads firstObject] andNotify:self];
  } else {
    [self notifyFailureWithErrorCode:kGADErrorNoFill
                         description:@"Ad from AppLovin doesn't have all assets required for "
                                     @"unified native ad formats."];
  }
}

#pragma mark - AppLovin Native Ad Precache Delegate Methods

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didFailToPrecacheImagesForAd:(nonnull ALNativeAd *)ad
                       withError:(NSInteger)errorCode {
  [self notifyFailureWithErrorCode:[GADMAdapterAppLovinUtils toAdMobErrorCode:(int)errorCode]
                       description:@"Native ad failed to pre cache images."];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didFailToPrecacheVideoForAd:(nonnull ALNativeAd *)ad
                      withError:(NSInteger)errorCode {
  // Do nothing.
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didPrecacheImagesForAd:(nonnull ALNativeAd *)ad {
  dispatch_async(dispatch_get_main_queue(), ^{
    GADMAppLovinMediatedNativeUnifiedAd *unifiedNativeAd =
        [[GADMAppLovinMediatedNativeUnifiedAd alloc] initWithNativeAd:ad];
    if (unifiedNativeAd) {
      [GADMAdapterAppLovinUtils log:@"Native ad loaded."];
      [self->_connector adapter:self didReceiveMediatedUnifiedNativeAd:unifiedNativeAd];
      return;
    }

    [self notifyFailureWithErrorCode:kGADErrorNoFill description:@"Failed to create a native ad."];
  });
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didPrecacheVideoForAd:(nonnull ALNativeAd *)ad {
  // Do nothing.
}

- (void)notifyFailureWithErrorCode:(NSInteger)errorCode description:(NSString *)description {
  NSError *error =
      GADMAdapterAppLovinErrorWithCodeAndDescription(errorCode, @"Native ad failed to load.");
  [_connector adapter:self didFailAd:error];
}

#pragma mark - Private Util Methods

/// Check whether or not the AppLovin native ad has all the required assets to map to a
/// Unified native ad.
+ (BOOL)containsRequiredUnifiedNativeAssets:(ALNativeAd *)nativeAd {
  return nativeAd.title && nativeAd.descriptionText && nativeAd.ctaText && nativeAd.imageURL;
}

#pragma mark - Unused Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  [self notifyFailureWithErrorCode:kGADErrorInvalidRequest
                       description:@"Incorrect class called for banner request. Use "
                                   @"GADMAdapterAppLovin for banner ad requests."];
}

- (void)getInterstitial {
  [self notifyFailureWithErrorCode:kGADErrorInvalidRequest
                       description:@"Incorrect class called for interstitial request. Use "
                                   @"GADMAdapterAppLovin for interstitial ad requests."];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animationType {
  return YES;
}

@end
