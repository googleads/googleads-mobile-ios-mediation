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
#import "GADMediationAdapterAppLovin.h"

/// Called by the adapter after downloading the native ad image assets or encountering an error.
typedef void (^GADMAdapterAppLovinNativeAdLoadImageCompletionHandler)(NSError *_Nullable error,
                                                                      UIImage *_Nullable mainImage,
                                                                      UIImage *_Nullable iconImage);

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
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, @"Invalid Server parameters.");
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
  NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
  [_connector adapter:self didFailAd:error];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service didLoadAds:(nonnull NSArray *)ads {
  if (ads.count <= 0) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorZeroAdsLoaded,
        @"AppLovin called nativeAdService:didLoadAds:with 0 Ads");
    [_connector adapter:self didFailAd:error];
    return;
  }
  if (![GADMAdapterAppLovinNative containsRequiredUnifiedNativeAssets:[ads firstObject]]) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorMissingNativeAssets,
        @"Ad doesn't have all assets required for unified native ad formats.");
    [_connector adapter:self didFailAd:error];
    return;
  }
  [service precacheResourcesForNativeAd:[ads firstObject] andNotify:self];
}

- (void)loadImagesForNativeAd:(nonnull ALNativeAd *)nativeAd
            completionHandler:
                (nonnull GADMAdapterAppLovinNativeAdLoadImageCompletionHandler)completionHandler {
  dispatch_group_t group = dispatch_group_create();
  __block UIImage *mainImage = nil;
  __block NSError *mainImageError = nil;
  __block NSError *iconImageError = nil;
  dispatch_group_enter(group);
  [[NSURLSession.sharedSession
        dataTaskWithURL:nativeAd.imageURL
      completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                          NSError *_Nullable error) {
        if (data) {
          mainImage = [[UIImage alloc] initWithData:data];
        }
        mainImageError = error;
        dispatch_group_leave(group);
      }] resume];
  __block UIImage *iconImage = nil;
  dispatch_group_enter(group);
  [[NSURLSession.sharedSession
        dataTaskWithURL:nativeAd.iconURL
      completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                          NSError *_Nullable error) {
        if (data) {
          iconImage = [[UIImage alloc] initWithData:data];
        }
        iconImageError = error;
        dispatch_group_leave(group);
      }] resume];

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSError *error = nil;
    if (!mainImage || !iconImage) {
      NSMutableString *description = [[NSMutableString alloc] init];

      if (mainImageError.localizedDescription) {
        [description appendFormat:@"%@ ", mainImageError.localizedDescription];
      }

      if (iconImageError.localizedDescription) {
        [description appendString:iconImageError.localizedDescription];
      }
      error = GADMAdapterAppLovinErrorWithCodeAndDescription(GADMAdapterAppLovinErrorLoadingImages,
                                                             description);
      mainImage = nil;
      iconImage = nil;
    }
    completionHandler(error, mainImage, iconImage);
  });
}

#pragma mark - AppLovin Native Ad Precache Delegate Methods

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didFailToPrecacheImagesForAd:(nonnull ALNativeAd *)ad
                       withError:(NSInteger)errorCode {
  NSError *error = GADMAdapterAppLovinSDKErrorWithCode(errorCode);
  [_connector adapter:self didFailAd:error];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didFailToPrecacheVideoForAd:(nonnull ALNativeAd *)ad
                      withError:(NSInteger)errorCode {
  // Do nothing.
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didPrecacheImagesForAd:(nonnull ALNativeAd *)ad {
  GADMAdapterAppLovinNative *__weak weakSelf = self;
  [self loadImagesForNativeAd:ad
            completionHandler:^(NSError *_Nullable error, UIImage *_Nullable mainImage,
                                UIImage *_Nullable iconImage) {
              GADMAdapterAppLovinNative *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }
              id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
              if (error) {
                [strongConnector adapter:strongSelf didFailAd:error];
                return;
              }
              GADMAppLovinMediatedNativeUnifiedAd *unifiedNativeAd =
                  [[GADMAppLovinMediatedNativeUnifiedAd alloc] initWithNativeAd:ad
                                                                      mainImage:mainImage
                                                                      iconImage:iconImage];
              [GADMAdapterAppLovinUtils log:@"Native ad loaded."];
              [strongConnector adapter:strongSelf
                  didReceiveMediatedUnifiedNativeAd:unifiedNativeAd];
            }];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
    didPrecacheVideoForAd:(nonnull ALNativeAd *)ad {
  // Do nothing.
}

#pragma mark - Private Util Methods

/// Check whether or not the AppLovin native ad has all the required assets to map to a
/// Unified native ad.
+ (BOOL)containsRequiredUnifiedNativeAssets:(ALNativeAd *)nativeAd {
  return nativeAd.title && nativeAd.descriptionText && nativeAd.ctaText && nativeAd.imageURL;
}

#pragma mark - Unused Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
      GADMAdapterAppLovinErrorUnsupportedAdFormat,
      @"Incorrect class called for banner request. Use "
      @"GADMAdapterAppLovin for banner ad requests.");
  [_connector adapter:self didFailAd:error];
}

- (void)getInterstitial {
  NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
      GADMAdapterAppLovinErrorUnsupportedAdFormat,
      @"Incorrect class called for interstitial request. UseGADMAdapterAppLovin for interstitial "
      @"ad requests.");
  [_connector adapter:self didFailAd:error];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animationType {
  return YES;
}

@end
