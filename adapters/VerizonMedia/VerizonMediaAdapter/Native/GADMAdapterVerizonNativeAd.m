//
//  GADMerizonNativeAd.m
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import "GADMAdapterVerizonNativeAd.h"

#import <VerizonAdsCore/VerizonAdsCore.h>
#import <VerizonAdsVerizonNativeController/VerizonAdsVerizonNativeController.h>

#import "GADMAdapterVerizonBaseClass.h"
#import "GADMAdapterVerizonConstants.h"
#import "GADMAdapterVerizonUtils.h"

@interface GADMAdapterVerizonNativeAd () <VASNativeAdFactoryDelegate, VASNativeAdDelegate>
@end

@implementation GADMAdapterVerizonNativeAd {
  /// Verizon media native ad.
  VASNativeAd *_nativeAd;

  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Handles loading and caching of Verizon media native ads.
  VASNativeAdFactory *_nativeAdFactory;

  /// Placement ID string used to request ads from Verizon Ads SDK.
  NSString *_placementID;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                              withGADMAdNetworkAdapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _connector = connector;
    _adapter = adapter;
    NSDictionary<NSString *, id> *credentials = [connector credentials];
    _placementID = credentials[GADMAdapterVerizonMediaPosition];
    NSString *siteID = credentials[GADMAdapterVerizonMediaDCN];
    GADMAdapterVerizonInitializeVASAdsWithSiteID(siteID);
  }

  return self;
}

- (void)loadNativeAdWithAdTypes:(nonnull NSArray<GADAdLoaderAdType> *)adTypes
                        options:(nullable NSArray<GADAdLoaderOptions *> *)options {
  if (![self prepareAdapterForAdRequest]) {
    return;
  }
  _nativeAdFactory = [[VASNativeAdFactory alloc] initWithPlacementId:_placementID
                                                             adTypes:@[ @"100", @"simpleImage" ]
                                                              vasAds:VASAds.sharedInstance
                                                            delegate:self];
  [_nativeAdFactory load:self];
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
    [strongConnector adapter:(id<GADMAdNetworkAdapter>)self didFailAd:error];
    return NO;
  }

  if (!_placementID) {
    NSError *error = GADMAdapterVerizonErrorWithCodeAndDescription(
        GADMAdapterVerizonErrorInvalidServerParameters, @"Placement ID cannot be nil.");
    [strongConnector adapter:(id<GADMAdNetworkAdapter>)self didFailAd:error];
    return NO;
  }

  [self setRequestInfoFromConnector];

  return YES;
}

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
  builder.mediator = [NSString stringWithFormat:@"AdMobVAS-%@", GADMAdapterVerizonMediaVersion];

  // Keywords.
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if ([strongConnector userKeywords] && [strongConnector userKeywords].count) {
    builder.userKeywords = [strongConnector userKeywords];
  }

  VASAds.sharedInstance.requestMetadata = [builder build];
}

- (void)setCoppaFromConnector {
  VASDataPrivacyBuilder *builder = [[VASDataPrivacyBuilder alloc] initWithDataPrivacy:VASAds.sharedInstance.dataPrivacy];
  builder.coppa.applies =  [[_connector childDirectedTreatment] boolValue];
  VASAds.sharedInstance.dataPrivacy = [builder build];
}

- (NSString *)stringForComponent:(NSString *)componentId {
  id<VASComponent> component = [_nativeAd component:componentId];
  if ([component conformsToProtocol:@protocol(VASNativeTextComponent)]) {
    return ((id<VASNativeTextComponent>)component).text;
  }
  return nil;
}

- (GADNativeAdImage *)imageForComponent:(NSString *)componentId {
  GADNativeAdImage *GADImage;
  id<VASComponent> component = [_nativeAd component:componentId];
  if ([component conformsToProtocol:@protocol(VASNativeImageComponent)]) {
    UIImageView *imageView = (UIImageView *)((id<VASNativeImageComponent>)component).view;
    if ([imageView isKindOfClass:[UIImageView class]]) {
      UIImage *image = imageView.image;
      if (image) {
        GADImage = [[GADNativeAdImage alloc] initWithImage:image];
      }
    }
  }

  return GADImage;
}

- (nullable NSString *)headline {
  return [self stringForComponent:@"title"];
}

- (nullable NSString *)body {
  return [self stringForComponent:@"body"];
}

- (nullable NSString *)callToAction {
  return [self stringForComponent:@"callToAction"];
}

- (nullable NSString *)advertiser {
  return [self stringForComponent:@"disclaimer"];
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  GADNativeAdImage *mainImage = [self imageForComponent:@"mainImage"];
  return mainImage ? @[ mainImage ] : nil;
}

- (GADNativeAdImage *)icon {
  return [self imageForComponent:@"iconImage"];
}

- (nullable UIView *)mediaView {
  id<VASViewComponent> videoComponent = (id<VASViewComponent>)[_nativeAd component:@"video"];
  if ([videoComponent conformsToProtocol:@protocol(VASViewComponent)]) {
    return videoComponent.view;
  }
  return nil;
}

- (BOOL)hasVideoContent {
  return self.mediaView != nil;
}

- (NSDecimalNumber *)starRating {
  NSString *ratingString = [self stringForComponent:@"rating"];
  if (ratingString.length > 0) {
    NSInteger stars = 0;
    NSInteger total = 0;
    NSScanner *scanner = [NSScanner scannerWithString:ratingString];

    NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
    [set formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
    [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [scanner setCharactersToBeSkipped:set];

    if ([scanner scanInteger:&stars] && [scanner scanInteger:&total]) {
      return [NSDecimalNumber
          decimalNumberWithString:[NSString stringWithFormat:@"%ld.%ld", (long)stars, (long)total]];
    }
  }
  return nil;
}

- (nullable NSDictionary *)extraAssets {
  return nil;
}

- (void)didRecordImpression {
  [_nativeAd fireImpression];
}

- (void)didRecordClickOnAssetWithName:(GADNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  [_nativeAd invokeDefaultAction];
}

- (void)didUntrackView:(nullable UIView *)view {
  [_nativeAd destroy];
}

- (void)dealloc {
  if ([_nativeAd respondsToSelector:@selector(destroy)]) {
    [_nativeAd performSelector:@selector(destroy)];
  }

  _nativeAdFactory.delegate = nil;
  _nativeAd.delegate = nil;
  _nativeAd = nil;
}

#pragma mark - VASNativeAd Delegate

- (void)nativeAdDidClose:(nonnull VASNativeAd *)nativeAd {
  // The `onAdClosed()` has a different meaning than Google's `onAdClosed()` and is therefore not
  // mapped.
}

- (void)nativeAdDidFail:(nonnull VASNativeAd *)nativeAd
              withError:(nonnull VASErrorInfo *)errorInfo {
  [GADMAdapterVerizonBaseClass.logger
      error:@"Native Ad did fail with error: %@", [errorInfo localizedDescription]];
}

- (void)nativeAdDidLeaveApplication:(nonnull VASNativeAd *)nativeAd {
    // Do nothing.
}

- (void)nativeAd:(nonnull VASNativeAd *)nativeAd
           event:(nonnull NSString *)eventId
          source:(nonnull NSString *)source
       arguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  // Do nothing.
}

- (nullable UIViewController *)nativeAdPresentingViewController {
  return [_connector viewControllerForPresentingModalView];
}

- (void)nativeAdClicked:(nonnull VASNativeAd *)nativeAd
          withComponent:(nonnull id<VASComponent>)component {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidGetAdClick:self->_adapter];
  });
}

#pragma mark - VASNativeAdFactory Delegate

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory
       didFailWithError:(nullable VASErrorInfo *)errorInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self->_adapter didFailAd:errorInfo];
  });
}

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory
        didLoadNativeAd:(nonnull VASNativeAd *)nativeAd {
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_nativeAd = nativeAd;
    [self->_connector adapter:self->_adapter didReceiveMediatedUnifiedNativeAd:self];
  });
}

@end
