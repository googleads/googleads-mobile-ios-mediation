// Copyright 2019 Google LLC
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

#import "GADMAdapterYahooNativeAd.h"
#import <YahooAds/YahooAds.h>
#import "GADMAdapterYahooBaseClass.h"
#import "GADMAdapterYahooConstants.h"
#import "GADMAdapterYahooUtils.h"

@interface GADMAdapterYahooNativeAd () <YASNativeAdDelegate>
@end

@implementation GADMAdapterYahooNativeAd {
  /// Yahoo native ad.
  YASNativeAd *_nativeAd;

  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Placement ID string used to request ads from Verizon Ads SDK.
  NSString *_placementID;

  /// Yahoo Mobile SDK video player view object.
  YASYahooVideoPlayerView *_yahooVideoPlayerView;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                              withGADMAdNetworkAdapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _connector = connector;
    _adapter = adapter;

    NSDictionary<NSString *, id> *credentials = [connector credentials];
    if (credentials[GADMAdapterYahooPosition]) {
      _placementID = credentials[GADMAdapterYahooPosition];
    }
    NSString *siteID = credentials[GADMAdapterYahooDCN];
    GADMAdapterYahooInitializeYASAdsWithSiteID(siteID);
  }

  return self;
}

- (void)loadNativeAdWithAdTypes:(nonnull NSArray<GADAdLoaderAdType> *)adTypes
                        options:(nullable NSArray<GADAdLoaderOptions *> *)options {
  if (![self prepareAdapterForAdRequest]) {
    return;
  }

  YASNativePlacementConfig *placementConfig =
      [[YASNativePlacementConfig alloc] initWithPlacementId:_placementID
                                            requestMetadata:nil
                                              nativeAdTypes:@[ @"simpleImage", @"simpleVideo" ]];

  _nativeAd = [[YASNativeAd alloc] initWithPlacementId:_placementID];
  _nativeAd.delegate = self;

  NSLog(@"[YahooAdapter] Requesting a native ad with placement ID: %@", _placementID);
  [_nativeAd loadWithPlacementConfig:placementConfig];
}

#pragma mark - YASNativeAdDelegate

- (void)nativeAdDidLoad:(nonnull YASNativeAd *)nativeAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK loaded a native ad successfully with type: %@",
        nativeAd.adType);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self->_adapter didReceiveMediatedUnifiedNativeAd:self];
  });
}

- (void)nativeAdLoadDidFail:(nonnull YASNativeAd *)nativeAd
                  withError:(nonnull YASErrorInfo *)errorInfo {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK failed to load a native ad with error: %@",
        errorInfo.description);
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapter:self->_adapter didFailAd:errorInfo];
  });
}

- (void)nativeAdDidFail:(nonnull YASNativeAd *)nativeAd withError:(YASErrorInfo *)errorInfo {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK returned an error for native ad: %@",
        errorInfo.description);
  // This callback is forwarded when an error occurs in the ad's lifecycle.
}

- (void)nativeAdClicked:(nonnull YASNativeAd *)nativeAd
          withComponent:(nonnull id<YASComponent>)component {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK recorded a click on a native ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidGetAdClick:self->_adapter];
  });
}

- (void)nativeAdDidLeaveApplication:(nonnull YASNativeAd *)nativeAd {
  NSLog(@"[YahooAdapter] Yahoo Mobile SDK has caused the user to leave the application from a "
        @"native ad.");
}

- (nullable UIViewController *)nativeAdPresentingViewController {
  return [_connector viewControllerForPresentingModalView];
}

- (void)nativeAd:(nonnull YASNativeAd *)nativeAd
           event:(nonnull NSString *)eventId
          source:(nonnull NSString *)source
       arguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  // Google Mobile Ads SDK doesn't have a matching event.
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
    [strongConnector adapter:(id<GADMAdNetworkAdapter>)self didFailAd:error];
    return NO;
  }

  if (!_placementID) {
    NSError *error = GADMAdapterYahooErrorWithCodeAndDescription(
        GADMAdapterYahooErrorInvalidServerParameters, @"Placement ID cannot be nil.");
    [strongConnector adapter:(id<GADMAdNetworkAdapter>)self didFailAd:error];
    return NO;
  }

  [self setRequestInfoFromConnector];

  return YES;
}

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

- (nullable NSString *)stringForComponent:(NSString *)componentId {
  id<YASComponent> component = [_nativeAd component:componentId];
  if ([component conformsToProtocol:@protocol(YASNativeTextComponent)]) {
    return ((id<YASNativeTextComponent>)component).text;
  }
  return nil;
}

- (nullable GADNativeAdImage *)imageForComponent:(NSString *)componentId {
  GADNativeAdImage *GADImage;

  id<YASNativeImageComponent> imageComponent =
      (id<YASNativeImageComponent>)[_nativeAd component:componentId];
  if (imageComponent) {
    // Yahoo Mobile SDK requires a call to -prepareView: in order for images to be rendered.
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageComponent prepareView:imageView];

    UIImage *image = imageView.image;
    if (image) {
      GADImage = [[GADNativeAdImage alloc] initWithImage:image];
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

- (nullable GADNativeAdImage *)icon {
  return [self imageForComponent:@"iconImage"];
}

- (nullable UIView *)mediaView {
  if (_yahooVideoPlayerView) {
    return _yahooVideoPlayerView;
  }

  id<YASComponent> component = [_nativeAd component:@"video"];
  if (component) {
    id<YASNativeViewComponent> viewComponent = (id<YASNativeViewComponent>)component;
    if ([viewComponent conformsToProtocol:@protocol(YASNativeVideoComponent)]) {
      // Yahoo Mobile SDK requires a call to -prepareView: in order for videos to
      // be properly rendered.
      id<YASNativeVideoComponent> videoComponent = (id<YASNativeVideoComponent>)viewComponent;
      _yahooVideoPlayerView = [[YASYahooVideoPlayerView alloc] init];
      YASErrorInfo *error = [videoComponent prepareView:_yahooVideoPlayerView];
      if (error) {
        NSLog(@"[YahooAdapter]: Failed to render mediaView video: %@", error);
      }

      return _yahooVideoPlayerView;
    }
  }

  return nil;
}

- (CGFloat)mediaContentAspectRatio {
  if (self.mediaView && self.mediaView.frame.size.height != 0.0f) {
    return (self.mediaView.frame.size.width / self.mediaView.frame.size.height);
  }
  return 0.0f;
}

- (BOOL)hasVideoContent {
  return (self.mediaView != nil);
}

- (nullable NSDecimalNumber *)starRating {
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
  NSLog(@"[YahooAdapter] Yahoo adapter recorded an impression on a native ad.");
  [_nativeAd fireImpression];
}

- (void)didRecordClickOnAssetWithName:(nonnull GADNativeAssetIdentifier)assetName
                                 view:(nonnull UIView *)view
                       viewController:(nonnull UIViewController *)viewController {
  NSLog(@"[YahooAdapter] Yahoo adapter recorded a click on a native ad.");
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->_connector adapterDidGetAdClick:self->_adapter];
  });

  [_nativeAd invokeDefaultAction];
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  bool registered = [_nativeAd registerContainerView:view];
  if (!registered) {
    NSLog(@"[YahooAdapter] Yahoo Mobile SDK failed to register the container view.");
  }
}

- (void)didUntrackView:(nullable UIView *)view {
  [_nativeAd destroy];
}

- (void)dealloc {
  _nativeAd.delegate = nil;
  _nativeAd = nil;
}

@end
