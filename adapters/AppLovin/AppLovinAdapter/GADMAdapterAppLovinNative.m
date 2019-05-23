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
#import "GADMAppLovinMediatedNativeAppInstallAd.h"
#import "GADMAppLovinMediatedNativeUnifiedAd.h"

@interface GADMAdapterAppLovinNative () <ALNativeAdLoadDelegate, ALNativeAdPrecacheDelegate>

@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, strong) NSArray *adTypes;

@end

@implementation GADMAdapterAppLovinNative

+ (NSString *)adapterVersion {
  return GADMAdapterAppLovinConstant.adapterVersion;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:connector.credentials];

    if (!self.sdk) {
      [GADMAdapterAppLovinUtils log:@"Failed to initialize SDK"];
    }
  }
  return self;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  if (!([adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative] ||
        [adTypes containsObject:kGADAdLoaderAdTypeNativeAppInstall])) {
    NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                         code:kGADErrorInvalidRequest
                                     userInfo:nil];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  self.adTypes = adTypes;

  [[ALSdk shared].nativeAdService loadNextAdAndNotify:self];
}

- (void)stopBeingDelegate {
  self.connector = nil;
}

#pragma mark - AppLovin Native Load Delegate Methods

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didFailToLoadAdsWithError:(NSInteger)code {
  [GADMAdapterAppLovinUtils log:@"Failed to load native ads %ld", code];
  [self notifyFailureWithErrorCode:[GADMAdapterAppLovinUtils toAdMobErrorCode:(int)code]];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service didLoadAds:(nonnull NSArray *)ads {
  if (ads.count > 0 &&
      ([GADMAdapterAppLovinNative containsRequiredUnifiesNativeAssets:[ads firstObject]] ||
       [GADMAdapterAppLovinNative containsRequiredAppInstallNativeAssets:[ads firstObject]])) {
    [service precacheResourcesForNativeAd:[ads firstObject] andNotify:self];
  } else {
    [GADMAdapterAppLovinUtils log:@"Ad from AppLovin doesn't have all assets required for "
                                  @"app install ad or unified native ad formats"];
    [self notifyFailureWithErrorCode:kGADErrorMediationNoFill];
  }
}

#pragma mark - AppLovin Native Ad Precache Delegate Methods

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didFailToPrecacheImagesForAd:(nonnull ALNativeAd *)ad
                       withError:(NSInteger)errorCode {
  [GADMAdapterAppLovinUtils log:@"Native ad failed to pre cache images %ld", errorCode];
  [self notifyFailureWithErrorCode:[GADMAdapterAppLovinUtils toAdMobErrorCode:(int)errorCode]];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didFailToPrecacheVideoForAd:(nonnull ALNativeAd *)ad
                      withError:(NSInteger)errorCode {
  // Do nothing.
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didPrecacheImagesForAd:(nonnull ALNativeAd *)ad {
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([self.adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative]) {
      GADMAppLovinMediatedNativeUnifiedAd *unifiedNativeAd =
          [[GADMAppLovinMediatedNativeUnifiedAd alloc] initWithNativeAd:ad];
      if (unifiedNativeAd) {
        [GADMAdapterAppLovinUtils log:@"Native ad loaded."];
        [self.connector adapter:self didReceiveMediatedUnifiedNativeAd:unifiedNativeAd];
        return;
      }
    } else if ([self.adTypes containsObject:kGADAdLoaderAdTypeNativeAppInstall]) {
      GADMAppLovinMediatedNativeAppInstallAd *appInstallNativeAd =
          [[GADMAppLovinMediatedNativeAppInstallAd alloc] initWithNativeAd:ad];
      if (appInstallNativeAd) {
        [GADMAdapterAppLovinUtils log:@"Native ad loaded."];
        [self.connector adapter:self didReceiveMediatedNativeAd:appInstallNativeAd];
        return;
      }
    }

    [GADMAdapterAppLovinUtils log:@"Failed to create a native ad."];
    [self notifyFailureWithErrorCode:kGADErrorNoFill];
  });
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didPrecacheVideoForAd:(nonnull ALNativeAd *)ad {
  // Do nothing.
}

- (void)notifyFailureWithErrorCode:(NSInteger)errorCode {
  [GADMAdapterAppLovinUtils log:@"Native ad failed to load &ld", errorCode];
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:errorCode
                                   userInfo:nil];
  [self.connector adapter:self didFailAd:error];
}

#pragma mark - Private Util Methods

/// Check whether or not the AppLovin native ad has all the required assets to map to a
/// Unified native ad.
+ (BOOL)containsRequiredUnifiesNativeAssets:(ALNativeAd *)nativeAd {
  return nativeAd.title && nativeAd.descriptionText && nativeAd.ctaText && nativeAd.imageURL;
}

/// Check whether or not the AppLovin native ad has all the required assets to map to a
/// App Install native ad.
+ (BOOL)containsRequiredAppInstallNativeAssets:(ALNativeAd *)nativeAd {
  return nativeAd.title && nativeAd.descriptionText && nativeAd.ctaText && nativeAd.iconURL &&
         nativeAd.imageURL;
}

#pragma mark - Unused Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  [GADMAdapterAppLovinUtils log:@"Incorrect class called for banner request. "
                                @"Use GADMAdapterAppLovin for banner ad requests."];
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:kGADErrorInvalidRequest
                                   userInfo:nil];
  [self.connector adapter:self didFailAd:error];
}

- (void)getInterstitial {
  [GADMAdapterAppLovinUtils log:@"Incorrect class called for banner request. "
                                @"Use GADMAdapterAppLovin for interstitial ad requests."];
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:kGADErrorInvalidRequest
                                   userInfo:nil];
  [self.connector adapter:self didFailAd:error];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

@end
