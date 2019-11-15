//
//  GADMVerizonAdapterBaseClass.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMAdapterVerizonBaseClass.h"
#import "GADMAdapterVerizonConstants.h"
#import "GADMAdapterVerizonNativeAd.h"

@interface GADMAdapterVerizonBaseClass () <VASInlineAdFactoryDelegate,
                                           VASInterstitialAdFactoryDelegate,
                                           VASInterstitialAdDelegate,
                                           VASInlineAdViewDelegate>

@end

@implementation GADMAdapterVerizonBaseClass {
  /// Verizon media native ad mapper.
  GADMAdapterVerizonNativeAd *_nativeAd;
}

#pragma mark - Logger

+ (VASLogger *)logger {
  static VASLogger *_logger = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _logger = [VASLogger loggerForClass:[GADMAdapterVerizonBaseClass class]];
  });
  return _logger;
}

#pragma mark - GADMAdNetworkAdapter

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

+ (NSString *)adapterVersion {
  return kGADMAdapterVerizonMediaVersion;
}

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
  }

  return self;
}

- (void)dealloc {
  [self stopBeingDelegate];
}

- (void)getInterstitial {
  if (![self prepareAdapterForAdRequest]) {
    return;
  }

  self.interstitialAd = nil;
  self.interstitialAdFactory =
  [[VASInterstitialAdFactory alloc] initWithPlacementId:self.placementID
                                                 vasAds:self.vasAds
                                               delegate:self];
  [self.interstitialAdFactory load:self];
}

- (void)getBannerWithSize:(GADAdSize)gadSize {
  if (![self prepareAdapterForAdRequest]) {
    return;
  }

  id<GADMAdNetworkConnector> connector = _connector;
    
  CGSize adSize = [self GADSupportedAdSizeFromRequestedSize:gadSize];
  if (CGSizeEqualToSize(adSize, CGSizeZero)) {
    [connector adapter:self didFailAd:[NSError errorWithDomain:kGADErrorDomain code:kGADErrorInvalidRequest userInfo:nil]];
    return;
  }
    
  VASInlineAdSize *size = [[VASInlineAdSize alloc] initWithWidth:adSize.width height:adSize.height];
  self.inlineAdFactory = [[VASInlineAdFactory alloc] initWithPlacementId:self.placementID
                                                                 adSizes:@[ size ]
                                                                  vasAds:VASAds.sharedInstance
                                                                delegate:self];

  [self.inlineAd removeFromSuperview];
  self.inlineAd = nil;
  [self.inlineAdFactory load:self];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootVC {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.interstitialAd showFromViewController:rootVC];
  });
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes
                       options:(NSArray<GADAdLoaderOptions *> *)options {
  _nativeAd = [[GADMAdapterVerizonNativeAd alloc] initWithGADMAdNetworkConnector:_connector
                                                        withGADMAdNetworkAdapter:self];
  [_nativeAd loadNativeAdWithAdTypes:adTypes options:options];
}

#pragma mark - VASInterstitialAdFactoryDelegate

- (void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory
        didLoadInterstitialAd:(VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.interstitialAd = interstitialAd;
    [self.connector adapterDidReceiveInterstitial:self];
  });
}

- (void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory
             didFailWithError:(VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapter:self didFailAd:errorInfo];
  });
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
      cacheLoadedNumRequested:(NSInteger)numRequested
                  numReceived:(NSInteger)numReceived {
  // The cache mechanism is not used in the AdMob mediation flow.
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
    cacheUpdatedWithCacheSize:(NSInteger)cacheSize {
  // The cache mechanism is not used in the AdMob mediation flow.
}

- (void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory
      cacheLoadedNumRequested:(NSInteger)numRequested {
  // The cache mechanism is not used in the AdMob mediation flow.
}

#pragma mark - VASInterstitialAdDelegate

- (void)interstitialAdDidShow:(VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapterWillPresentInterstitial:self];
  });
}

- (void)interstitialAdDidFail:(VASInterstitialAd *)interstitialAd
                    withError:(VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapter:self didFailAd:errorInfo];
  });
}

- (void)interstitialAdDidClose:(VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapterDidDismissInterstitial:self];
  });
}

- (void)interstitialAdDidLeaveApplication:(VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapterWillLeaveApplication:self];
  });
}

- (void)interstitialAdClicked:(VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapterDidGetAdClick:self];
  });
}

- (void)interstitialAdEvent:(VASInterstitialAd *)interstitialAd
                     source:(NSString *)source
                    eventId:(NSString *)eventId
                  arguments:(NSDictionary<NSString *, id> *)arguments {
  // A generic callback that does currently need an implementation for interstitial placements.
}

#pragma mark - VASInlineAdFactoryDelegate

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory
       didFailWithError:(nonnull VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapter:self didFailAd:errorInfo];
  });
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory
        didLoadInlineAd:(nonnull VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.inlineAd = inlineAd;
    self.inlineAd.frame = CGRectMake(0, 0, inlineAd.adSize.width, inlineAd.adSize.height);
    [self.connector adapter:self didReceiveAdView:self.inlineAd];
  });
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory
cacheLoadedNumRequested:(NSInteger)numRequested
            numReceived:(NSInteger)numReceived {
  // The cache mechanism is not used in the AdMob mediation flow.
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory
cacheUpdatedWithCacheSize:(NSInteger)cacheSize {
  // The cache mechanism is not used in the AdMob mediation flow.
}

#pragma mark - VASInlineAdViewDelegate

- (void)inlineAdDidFail:(VASInlineAdView *)inlineAd withError:(VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapter:self didFailAd:errorInfo];
  });
}

- (void)inlineAdDidExpand:(VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapterWillPresentFullScreenModal:self];
  });
}

- (void)inlineAdDidCollapse:(VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapterDidDismissFullScreenModal:self];
  });
}

- (void)inlineAdClicked:(VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapterDidGetAdClick:self];
  });
}

- (void)inlineAdDidLeaveApplication:(VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.connector adapterWillLeaveApplication:self];
  });
}

- (nullable UIViewController *)adPresentingViewController {
  return [self.connector viewControllerForPresentingModalView];
}

- (void)inlineAdDidRefresh:(nonnull VASInlineAdView *)inlineAd {
  // AdMob publishers use the AdMob inline refresh mechanism, so an implementation here is not
  // needed.
}

- (void)inlineAdDidResize:(nonnull VASInlineAdView *)inlineAd {
  // AdMob does not expose a resize callback to map to this.
}

- (void)inlineAdEvent:(nonnull VASInlineAdView *)inlineAd
               source:(nonnull NSString *)source
              eventId:(nonnull NSString *)eventId
            arguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  // A generic callback that does currently need an implementation for inline placements.
}

#pragma mark - common

- (BOOL)prepareAdapterForAdRequest {
  if (!self.placementID || ![self.vasAds isInitialized]) {
    NSError *error = [NSError
                      errorWithDomain:kGADMAdapterVerizonMediaErrorDomain
                      code:kGADErrorMediationAdapterError
                      userInfo:@{NSLocalizedDescriptionKey : @"Verizon adapter not properly intialized."}];
    [_connector adapter:self didFailAd:error];
    return NO;
  }

  [self setRequestInfoFromConnector];

  return YES;
}

- (void)stopBeingDelegate {
  if (self.inlineAd) {
    if ([self.inlineAd respondsToSelector:@selector(destroy)]) {
      [self.inlineAd performSelector:@selector(destroy)];
    } else {
      NSLog(@"GADMAdapterVerizon: The adapter is intended to work with Verizon Ads SDK version "
            @"1.0.4 or higher.  Please update the Verizon Ads SDK.");
    }
  }

  if (self.interstitialAd) {
    if ([self.interstitialAd respondsToSelector:@selector(destroy)]) {
      [self.interstitialAd performSelector:@selector(destroy)];
    } else {
      NSLog(@"GADMAdapterVerizon: The adapter is intended to work with Verizon Ads SDK version "
            @"1.0.4 or higher.  Please update the Verizon Ads SDK.");
    }
  }

  self.inlineAdFactory.delegate = nil;
  self.inlineAd.delegate = nil;
  self.interstitialAdFactory.delegate = nil;
  self.interstitialAd.delegate = nil;
  self.inlineAd = nil;
  self.interstitialAd = nil;
}

#pragma mark - private

- (void)setRequestInfoFromConnector {
  // User Settings
  [self setUserSettingsFromConnector];

  // COPPA
  [self setCoppaFromConnector];

  // Location
  if (_connector.userHasLocation) {
    self.vasAds.locationEnabled = YES;
  }
}

- (void)setUserSettingsFromConnector {
  VASRequestMetadataBuilder *builder = [[VASRequestMetadataBuilder alloc] init];

  // Mediator
  builder.appMediator =
  [NSString stringWithFormat:@"AdMobVAS-%@", [GADMAdapterVerizonBaseClass adapterVersion]];
  id<GADMAdNetworkConnector> strongConnector = _connector;
  // Keywords
  if ([strongConnector userKeywords] != nil && [[strongConnector userKeywords] count] > 0) {
    builder.userKeywords = [strongConnector userKeywords];
    ;
  }

  self.vasAds.requestMetadata = [builder build];
}

- (void)setCoppaFromConnector {
  self.vasAds.COPPA = [_connector childDirectedTreatment];
}

- (CGSize)GADSupportedAdSizeFromRequestedSize:(GADAdSize)gadAdSize {
  NSArray *potentials = @[
                          NSValueFromGADAdSize(kGADAdSizeBanner),
                          NSValueFromGADAdSize(kGADAdSizeMediumRectangle),
                          NSValueFromGADAdSize(kGADAdSizeLeaderboard)
                          ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  if (IsGADAdSizeValid(closestSize)) {
    return CGSizeFromGADAdSize(closestSize);
  }
    
  return CGSizeZero;
}

@end
