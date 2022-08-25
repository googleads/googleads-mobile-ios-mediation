//
//  GADMVerizonAdapterBaseClass.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMAdapterVerizonBaseClass.h"
#import "GADMAdapterVerizonConstants.h"
#import "GADMAdapterVerizonNativeAd.h"
#import "GADMAdapterVerizonUtils.h"

@interface GADMAdapterVerizonBaseClass () <VASInlineAdFactoryDelegate,
                                           VASInterstitialAdFactoryDelegate,
                                           VASInterstitialAdDelegate,
                                           VASInlineAdViewDelegate>

@end

@implementation GADMAdapterVerizonBaseClass {
  /// Verizon media native ad mapper.
  GADMAdapterVerizonNativeAd *_nativeAd;

  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
}

#pragma mark - Logger

+ (nonnull VASLogger *)logger {
  static VASLogger *_logger = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _logger = [VASLogger loggerForClass:[GADMAdapterVerizonBaseClass class]];
  });
  return _logger;
}

#pragma mark - GADMAdNetworkAdapter

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

+ (NSString *)adapterVersion {
  return GADMAdapterVerizonMediaVersion;
}

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
    NSDictionary<NSString *, id> *credentials = [connector credentials];
    if (credentials[GADMAdapterVerizonMediaPosition]) {
      self.placementID = credentials[GADMAdapterVerizonMediaPosition];
    }
    NSString *siteID = credentials[GADMAdapterVerizonMediaDCN];
    GADMAdapterVerizonInitializeVASAdsWithSiteID(siteID);
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
                                                     vasAds:VASAds.sharedInstance
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
    NSString *description =
        [NSString stringWithFormat:@"Invalid size for Verizon Media mediation adapter. Size: %@",
                                   NSStringFromGADAdSize(gadSize)];
    NSError *error = GADMAdapterVerizonErrorWithCodeAndDescription(
        GADMAdapterVerizonErrorBannerSizeMismatch, description);
    [connector adapter:self didFailAd:error];
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

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
        didLoadInterstitialAd:(nonnull VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.interstitialAd = interstitialAd;
    [self->_connector adapterDidReceiveInterstitial:self];
  });
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory
             didFailWithError:(nonnull VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self didFailAd:errorInfo];
  });
}

#pragma mark - VASInterstitialAdDelegate

- (void)interstitialAdDidShow:(nonnull VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterWillPresentInterstitial:self];
  });
}

- (void)interstitialAdDidFail:(nonnull VASInterstitialAd *)interstitialAd
                    withError:(nonnull VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self didFailAd:errorInfo];
  });
}

- (void)interstitialAdDidClose:(nonnull VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidDismissInterstitial:self];
  });
}

- (void)interstitialAdDidLeaveApplication:(nonnull VASInterstitialAd *)interstitialAd {
  // Do nothing.
}

- (void)interstitialAdClicked:(nonnull VASInterstitialAd *)interstitialAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidGetAdClick:self];
  });
}

- (void)interstitialAdEvent:(nonnull VASInterstitialAd *)interstitialAd
                     source:(nonnull NSString *)source
                    eventId:(nonnull NSString *)eventId
                  arguments:(nullable NSDictionary<NSString *, id> *)arguments {
  // A generic callback that does currently need an implementation for interstitial placements.
}

#pragma mark - VASInlineAdFactoryDelegate

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory
       didFailWithError:(nonnull VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self didFailAd:errorInfo];
  });
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory
        didLoadInlineAd:(nonnull VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.inlineAd = inlineAd;
    self.inlineAd.frame = CGRectMake(0, 0, inlineAd.adSize.width, inlineAd.adSize.height);
    [self->_connector adapter:self didReceiveAdView:self.inlineAd];
  });
}

#pragma mark - VASInlineAdViewDelegate

- (void)inlineAdDidFail:(nonnull VASInlineAdView *)inlineAd
              withError:(nonnull VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self didFailAd:errorInfo];
  });
}

- (void)inlineAdDidExpand:(nonnull VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterWillPresentFullScreenModal:self];
  });
}

- (void)inlineAdDidCollapse:(nonnull VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidDismissFullScreenModal:self];
  });
}

- (void)inlineAdClicked:(nonnull VASInlineAdView *)inlineAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidGetAdClick:self];
  });
}

- (void)inlineAdDidLeaveApplication:(nonnull VASInlineAdView *)inlineAd {
    // Do nothing.
}

- (nullable UIViewController *)inlineAdPresentingViewController {
  return [_connector viewControllerForPresentingModalView];
}

- (void)inlineAdDidRefresh:(nonnull VASInlineAdView *)inlineAd {
  // AdMob publishers use the AdMob inline refresh mechanism, so an implementation here is not
  // needed.
}

- (void)inlineAdDidResize:(nonnull VASInlineAdView *)inlineAd {
  // AdMob does not expose a resize callback to map to this.
}

- (void)inlineAd:(nonnull VASInlineAdView *)inlineAd
           event:(nonnull NSString *)eventId
          source:(nonnull NSString *)source
       arguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  // A generic callback that does currently need an implementation for inline placements.
}

#pragma mark - common

- (BOOL)prepareAdapterForAdRequest {
  id<GADMAdNetworkConnector> strongConnector = _connector;

  if (!strongConnector) {
    NSLog(@"Verizon Adapter Error: No GADMAdNetworkConnector found.");
    return NO;
  }

  NSDictionary<NSString *, id> *credentials = [strongConnector credentials];
  NSString *siteID = credentials[GADMAdapterVerizonMediaDCN];

  BOOL isInitialized = GADMAdapterVerizonInitializeVASAdsWithSiteID(siteID);
  if (!isInitialized) {
    NSError *error = GADMAdapterVerizonErrorWithCodeAndDescription(
        GADMAdapterVerizonErrorInitialization, @"Verizon SDK failed to initialize.");
    [strongConnector adapter:self didFailAd:error];
    return NO;
  }

  if (!self.placementID) {
    NSError *error =
        [NSError errorWithDomain:GADMAdapterVerizonMediaErrorDomain
                            code:GADErrorMediationAdapterError
                        userInfo:@{NSLocalizedDescriptionKey : @"Placement ID cannot be nil."}];
    [strongConnector adapter:self didFailAd:error];
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
    VASAds.sharedInstance.locationEnabled = YES;
  }
}

- (void)setUserSettingsFromConnector {
  VASRequestMetadataBuilder *builder = [[VASRequestMetadataBuilder alloc] init];

  // Mediator
  builder.mediator =
      [NSString stringWithFormat:@"AdMobVAS-%@", [GADMAdapterVerizonBaseClass adapterVersion]];
  id<GADMAdNetworkConnector> strongConnector = _connector;
  // Keywords
  if ([strongConnector userKeywords] != nil && [[strongConnector userKeywords] count] > 0) {
    builder.userKeywords = [strongConnector userKeywords];
    ;
  }

  VASAds.sharedInstance.requestMetadata = [builder build];
}

- (void)setCoppaFromConnector {
  VASDataPrivacyBuilder *builder = [[VASDataPrivacyBuilder alloc] initWithDataPrivacy:VASAds.sharedInstance.dataPrivacy];
  builder.coppa.applies =  [[_connector childDirectedTreatment] boolValue];
  VASAds.sharedInstance.dataPrivacy = [builder build];
}

- (CGSize)GADSupportedAdSizeFromRequestedSize:(GADAdSize)gadAdSize {
  NSArray *potentials = @[
    NSValueFromGADAdSize(GADAdSizeBanner), NSValueFromGADAdSize(GADAdSizeMediumRectangle),
    NSValueFromGADAdSize(GADAdSizeLeaderboard)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  if (IsGADAdSizeValid(closestSize)) {
    return CGSizeFromGADAdSize(closestSize);
  }

  return CGSizeZero;
}

@end
