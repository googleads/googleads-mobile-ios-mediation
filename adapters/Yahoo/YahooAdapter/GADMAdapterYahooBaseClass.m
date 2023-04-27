// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterYahooBaseClass.h"
#import "GADMAdapterYahooConstants.h"
#import "GADMAdapterYahooNativeAd.h"
#import "GADMAdapterYahooUtils.h"

@interface GADMAdapterYahooBaseClass () <YASInlineAdViewDelegate, YASInterstitialAdDelegate>
@end

@implementation GADMAdapterYahooBaseClass {
  /// Yahoo native ad mapper.
  GADMAdapterYahooNativeAd *_nativeAd;

  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
}

#pragma mark - Logger

+ (nonnull YASLogger *)logger {
  static YASLogger *_logger = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _logger = [YASLogger loggerForClass:[GADMAdapterYahooBaseClass class]];
  });
  return _logger;
}

#pragma mark - GADMAdNetworkAdapter

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

+ (NSString *)adapterVersion {
  return GADMAdapterYahooVersion;
}

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;

    NSDictionary<NSString *, id> *credentials = [connector credentials];
    if (credentials[GADMAdapterYahooPosition]) {
      self.placementID = credentials[GADMAdapterYahooPosition];
    }
    NSString *siteID = credentials[GADMAdapterYahooDCN];
    GADMAdapterYahooInitializeYASAdsWithSiteID(siteID);
  }

  return self;
}

- (void)dealloc {
  [self stopBeingDelegate];
}

#pragma mark - Banner

- (void)getBannerWithSize:(GADAdSize)gadSize {
  if (![self prepareAdapterForAdRequest]) {
    return;
  }

  id<GADMAdNetworkConnector> connector = _connector;
  CGSize adSize = GADMAdapterYahooSupportedAdSizeFromRequestedSize(gadSize);
  if (CGSizeEqualToSize(adSize, CGSizeZero)) {
    NSString *errorMessage =
        [NSString stringWithFormat:@"Invalid size for Yahoo mediation adapter. Size: %@",
                                   NSStringFromGADAdSize(gadSize)];
    NSError *error = GADMAdapterYahooErrorWithCodeAndDescription(
        GADMAdapterYahooErrorBannerSizeMismatch, errorMessage);
    [connector adapter:self didFailAd:error];
    return;
  }

  YASInlineAdSize *size = [[YASInlineAdSize alloc] initWithWidth:adSize.width height:adSize.height];
  YASInlinePlacementConfig *placementConfig =
      [[YASInlinePlacementConfig alloc] initWithPlacementId:self.placementID
                                            requestMetadata:nil
                                                    adSizes:@[ size ]];

  self.inlineAd = [[YASInlineAdView alloc] initWithPlacementId:self.placementID];
  self.inlineAd.delegate = self;

  NSLog(@"[YahooAdapter] Requesting a banner ad with placement ID: %@", _placementID);
  [self.inlineAd loadWithPlacementConfig:placementConfig];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)inlineAdDidLoad:(nonnull YASInlineAdView *)inlineAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK loaded a banner ad successfully.");
  dispatch_async(dispatch_get_main_queue(), ^{
    self.inlineAd = inlineAd;
    self.inlineAd.frame = CGRectMake(0, 0, inlineAd.adSize.width, inlineAd.adSize.height);
    [self->_connector adapter:self didReceiveAdView:self.inlineAd];
  });
}

- (void)inlineAdLoadDidFail:(nonnull YASInlineAdView *)inlineAd
                  withError:(nonnull YASErrorInfo *)errorInfo {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK failed to load a banner ad with error: %@",
        errorInfo.description);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self didFailAd:errorInfo];
  });
}

- (void)inlineAdDidFail:(nonnull YASInlineAdView *)inlineAd
              withError:(nonnull YASErrorInfo *)errorInfo {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK returned an error for banner ad: %@",
        errorInfo.description);
  // This callback is forwarded when an error occurs in the ad's lifecycle.
}

- (void)inlineAdDidExpand:(nonnull YASInlineAdView *)inlineAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK expanded a banner ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterWillPresentFullScreenModal:self];
  });
}

- (void)inlineAdDidCollapse:(nonnull YASInlineAdView *)inlineAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK collapsed a banner ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidDismissFullScreenModal:self];
  });
}

- (void)inlineAdClicked:(nonnull YASInlineAdView *)inlineAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK recorded a click on a banner ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidGetAdClick:self];
  });
}

- (void)inlineAdDidLeaveApplication:(nonnull YASInlineAdView *)inlineAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK has caused the user to leave the application from a "
        @"banner ad.");
}

- (void)inlineAdDidResize:(nonnull YASInlineAdView *)inlineAd {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)inlineAdDidRefresh:(nonnull YASInlineAdView *)inlineAd {
  // AdMob publishers use the AdMob inline refresh mechanism, so an implementation here is not
  // needed.
}

- (nullable UIViewController *)inlineAdPresentingViewController {
  return [_connector viewControllerForPresentingModalView];
}

- (void)inlineAd:(nonnull YASInlineAdView *)inlineAd
           event:(nonnull NSString *)eventId
          source:(nonnull NSString *)source
       arguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  // A generic callback that does currently need an implementation for inline placements.
}

#pragma mark - Interstital

- (void)getInterstitial {
  if (![self prepareAdapterForAdRequest]) {
    return;
  }

  YASInterstitialPlacementConfig *placementConfig =
      [[YASInterstitialPlacementConfig alloc] initWithPlacementId:self.placementID
                                                  requestMetadata:nil];

  self.interstitialAd = [[YASInterstitialAd alloc] initWithPlacementId:self.placementID];
  self.interstitialAd.delegate = self;

  NSLog(@"[YahooAdapter] Requesting an interstitial ad with placement ID: %@", _placementID);
  [self.interstitialAd loadWithPlacementConfig:placementConfig];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootVC {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.interstitialAd showFromViewController:rootVC];
  });
}

- (void)interstitialAdDidLoad:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK loaded an interstitial ad successfully.");
  dispatch_async(dispatch_get_main_queue(), ^{
    self.interstitialAd = interstitialAd;
    [self->_connector adapterDidReceiveInterstitial:self];
  });
}

- (void)interstitialAdLoadDidFail:(nonnull YASInterstitialAd *)interstitialAd
                        withError:(nonnull YASErrorInfo *)errorInfo {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK failed to load an interstitial ad with error: %@",
        errorInfo.description);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self didFailAd:errorInfo];
  });
}

- (void)interstitialAdDidFail:(nonnull YASInterstitialAd *)interstitialAd
                    withError:(nonnull YASErrorInfo *)errorInfo {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK returned an error for interstitial ad: %@",
        errorInfo.description);
  // This callback is forwarded when an error occurs in the ad's lifecycle.
}

- (void)interstitialAdDidShow:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK showed an interstitial ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterWillPresentInterstitial:self];
  });
}

- (void)interstitialAdDidClose:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK closed an interstitial ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidDismissInterstitial:self];
  });
}

- (void)interstitialAdClicked:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK recorded a click on an interstitial ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidGetAdClick:self];
  });
}

- (void)interstitialAdDidLeaveApplication:(nonnull YASInterstitialAd *)interstitialAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK has caused the user to leave the application from an "
        @"interstitial ad.");
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)interstitialAdEvent:(nonnull YASInterstitialAd *)interstitialAd
                     source:(nonnull NSString *)source
                    eventId:(nonnull NSString *)eventId
                  arguments:(nullable NSDictionary<NSString *, id> *)arguments {
  // A generic callback that does currently need an implementation for interstitial placements.
}

#pragma mark - Native

- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes
                       options:(NSArray<GADAdLoaderOptions *> *)options {
  _nativeAd = [[GADMAdapterYahooNativeAd alloc] initWithGADMAdNetworkConnector:_connector
                                                      withGADMAdNetworkAdapter:self];
  [_nativeAd loadNativeAdWithAdTypes:adTypes options:options];
}

#pragma mark - Common

- (BOOL)prepareAdapterForAdRequest {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    NSLog(@"[YahooAdapter] No GADMAdNetworkConnector found.");
    return NO;
  }

  NSDictionary<NSString *, id> *credentials = [strongConnector credentials];
  NSString *siteID = credentials[GADMAdapterYahooDCN];

  BOOL isInitialized = GADMAdapterYahooInitializeYASAdsWithSiteID(siteID);
  if (!isInitialized) {
    NSError *error = GADMAdapterYahooErrorWithCodeAndDescription(
        GADMAdapterYahooErrorInitialization, @"Yahoo Mobile SDK failed to initialize.");
    [strongConnector adapter:self didFailAd:error];
    return NO;
  }

  if (!self.placementID) {
    NSError *error = GADMAdapterYahooErrorWithCodeAndDescription(
        GADMAdapterYahooErrorInvalidServerParameters, @"Placement ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return NO;
  }

  [self setRequestInfoFromConnector];

  return YES;
}

- (void)stopBeingDelegate {
  self.inlineAd.delegate = nil;
  self.interstitialAd.delegate = nil;
  self.inlineAd = nil;
  self.interstitialAd = nil;
}

#pragma mark - private

- (void)setRequestInfoFromConnector {
  YASRequestMetadataBuilder *builder = [[YASRequestMetadataBuilder alloc] init];
  builder.mediator = [NSString stringWithFormat:@"AdMobYAS-%@", GADMAdapterYahooVersion];

  // Forward keywords to Yahoo Mobile SDK.
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if ([strongConnector userKeywords] != nil && [[strongConnector userKeywords] count] > 0) {
    builder.userKeywords = [strongConnector userKeywords];
  }
  YASAds.sharedInstance.requestMetadata = [builder build];

  // Set debug mode in Yahoo Mobile SDK.
  if ([strongConnector testMode]) {
    YASAds.logLevel = YASLogLevelDebug;
  } else {
    YASAds.logLevel = YASLogLevelError;
  }

  // Forward COPPA value to Yahoo Mobile SDK.
  if ([strongConnector childDirectedTreatment].boolValue) {
    NSLog(@"[YahooAdapter] Applying COPPA.");
    [YASAds.sharedInstance applyCoppa];
  }
}

@end
