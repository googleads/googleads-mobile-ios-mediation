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

#import "GADFBNativeAd.h"

@import GoogleMobileAds;
@import FBAudienceNetwork;

#import "GADFBAdapterDelegate.h"
#import "GADFBError.h"
#import "GADFBExtraAssets.h"
#import "GADFBNetworkExtras.h"

static NSString *const GADNativeAdCoverImage = @"1";
static NSString *const GADNativeAdIcon = @"2";

@interface GADFBNativeAd () <GADMediatedNativeAppInstallAd,
                             GADMediatedNativeAdDelegate,
                             FBNativeAdDelegate> {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Native ad obtained from Facebook's Audience Network.
  FBNativeAd *_nativeAd;

  /// Native ad image loading options.
  GADNativeAdImageAdLoaderOptions *_nativeAdImageAdLoaderOptions;

  /// Native ad view options.
  GADNativeAdViewAdOptions *_nativeAdViewAdOptions;

  ///  A dictionary of asset names and object pairs for assets that are not handled by properties of
  ///  the GADMediatedNativeAd subclass
  NSDictionary *_extraAssets;

  /// Array of GADNativeAdImage objects related to the advertised application.
  NSArray *_images;

  /// Application icon.
  GADNativeAdImage *_icon;

  /// A set of strings representing loaded images.
  NSMutableSet *_loadedImages;

  /// A set of string representing all native ad images.
  NSSet *_nativeAdImages;

  /// Serializes ivar usage.
  dispatch_queue_t _lockQueue;

  /// Facebook AdChoices view.
  FBAdChoicesView *_adChoicesView;

  /// YES if an impression has been logged.
  BOOL _impressionLogged;

  /// Facebook media view.
  FBMediaView *_mediaView;
}

@end

@implementation GADFBNativeAd

/// Empty method to bypass Apple's private method checking since
/// GADMediatedNativeAdNotificationSource's mediatedNativeAdDidRecordImpression method is
/// dynamically called by this class's instances.
+ (void)mediatedNativeAdDidRecordImpression:(id<GADMediatedNativeAd>)mediatedNativeAd {
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
    _loadedImages = [[NSMutableSet alloc] init];
    _nativeAdImages = [[NSSet alloc] initWithObjects:GADNativeAdCoverImage, GADNativeAdIcon, nil];
    _lockQueue = dispatch_queue_create("fb-native-ad", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  // Facebook only supports app install ads.
  if (![adTypes containsObject:kGADAdLoaderAdTypeNativeAppInstall] ||
      ![adTypes containsObject:kGADAdLoaderAdTypeNativeContent]) {
    NSError *error = GADFBErrorWithDescription(
        @"Ad types must include kGADAdLoaderAdTypeNativeAppInstall and "
        @"kGADAdLoaderAdTypeNativeContent.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  for (GADAdLoaderOptions *option in options) {
    if ([option isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      _nativeAdImageAdLoaderOptions = (GADNativeAdImageAdLoaderOptions *)option;
    } else if ([option isKindOfClass:[GADNativeAdViewAdOptions class]]) {
      _nativeAdViewAdOptions = (GADNativeAdViewAdOptions *)option;
    }
  }

  if (!strongConnector || !strongAdapter) {
    return;
  }

  // -[FBNativeAd initWithPlacementID:] throws an NSInvalidArgumentException if the placement ID is
  // nil.
  NSString *placementID = [strongConnector publisherId];
  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _nativeAd = [[FBNativeAd alloc] initWithPlacementID:placementID];
  if (!_nativeAd) {
    NSString *description = [[NSString alloc]
        initWithFormat:@"Failed to initialize %@.", NSStringFromClass([FBNativeAd class])];
    NSError *error = GADFBErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }
  _mediaView = [[FBMediaView alloc] initWithNativeAd:_nativeAd];
  _mediaView.delegate = self;
  _nativeAd.delegate = self;
  [FBAdSettings setMediationService:[NSString stringWithFormat:@"ADMOB_%@", [GADRequest sdkVersion]]];
  [_nativeAd loadAd];
}

- (void)stopBeingDelegate {
  _nativeAd.delegate = nil;
  _mediaView.delegate = nil;
}

- (void)loadNativeAdImages {
  [_loadedImages removeAllObjects];
  if (_nativeAdImageAdLoaderOptions.disableImageLoading) {
    // Set scale as 1 since Facebook does not provide image scale.
    GADNativeAdImage *nativeAdImage =
        [[GADNativeAdImage alloc] initWithURL:_nativeAd.coverImage.url scale:1];
    if (nativeAdImage) {
      _images = @[ nativeAdImage ];
    }
    _icon = [[GADNativeAdImage alloc] initWithURL:self->_nativeAd.icon.url scale:1];
    [self nativeAdImagesReady];
  } else {
    // Load icon and cover image, and notify the connector when completed.
    [self loadCoverImage];
    [self loadIcon];
  }
}

- (void)loadCoverImage {
  [_nativeAd.coverImage loadImageAsyncWithBlock:^(UIImage *_Nullable image) {
    if (image) {
      GADNativeAdImage *nativeAdImage = [[GADNativeAdImage alloc] initWithImage:image];
      if (nativeAdImage) {
        self->_images = @[ nativeAdImage ];
      }
    }
    [self completedLoadingNativeAdImage:GADNativeAdCoverImage];
  }];
}

- (void)loadIcon {
  [_nativeAd.icon loadImageAsyncWithBlock:^(UIImage *_Nullable image) {
    if (image) {
      self->_icon = [[GADNativeAdImage alloc] initWithImage:image];
    }
    [self completedLoadingNativeAdImage:GADNativeAdIcon];
  }];
}

- (void)completedLoadingNativeAdImage:(NSString *)image {
  __block BOOL loadedAllImages = NO;
  dispatch_sync(_lockQueue, ^{
    [self->_loadedImages addObject:image];
    loadedAllImages = [self->_loadedImages isEqual:self->_nativeAdImages];
  });

  if (!loadedAllImages) {
    return;
  }

  if (_images && _icon) {
    [self nativeAdImagesReady];
    return;
  }

  id<GADMAdNetworkAdapter> strongAdapter = self->_adapter;
  id<GADMAdNetworkConnector> strongConnector = self->_connector;
  NSString *errorMessage = [[NSString alloc] initWithFormat:@"Unable to load native ad image."];
  [strongConnector adapter:strongAdapter didFailAd:GADFBErrorWithDescription(errorMessage)];
}

- (void)nativeAdImagesReady {
  id<GADMAdNetworkAdapter> strongAdapter = self->_adapter;
  id<GADMAdNetworkConnector> strongConnector = self->_connector;
  [strongConnector adapter:strongAdapter didReceiveMediatedNativeAd:self];
}

#pragma mark - GADMediatedNativeAd

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return self;
}

- (NSDictionary *)extraAssets {
  NSDictionary *__block extraAssets = nil;
  dispatch_sync(_lockQueue, ^{
    if (self->_extraAssets) {
      extraAssets = [self->_extraAssets copy];
    } else {
      NSMutableDictionary *mutableExtraAssets = [[NSMutableDictionary alloc] init];
      NSString *subtitle = [self->_nativeAd.subtitle copy];
      if (subtitle) {
        mutableExtraAssets[GADFBSubtitle] = subtitle;
      }
      NSString *socialContext = [self->_nativeAd.socialContext copy];
      if (socialContext) {
        mutableExtraAssets[GADFBSocialContext] = socialContext;
      }

      extraAssets = mutableExtraAssets;
      self->_extraAssets = mutableExtraAssets;
    }
  });
  return extraAssets;
}

#pragma mark - GADMediatedNativeAppInstallAd

- (NSString *)headline {
  NSString *__block headline = nil;
  dispatch_sync(_lockQueue, ^{
    headline = [self->_nativeAd.title copy];
  });
  return headline;
}

- (NSArray *)images {
  NSArray *__block images = nil;
  dispatch_sync(_lockQueue, ^{
    images = [self->_images copy];
  });
  return images;
}

- (NSString *)body {
  NSString *__block body = nil;
  dispatch_sync(_lockQueue, ^{
    body = [self->_nativeAd.body copy];
  });
  return body;
}

- (GADNativeAdImage *)icon {
  GADNativeAdImage *__block icon = nil;
  dispatch_sync(_lockQueue, ^{
    icon = self->_icon;
  });
  return icon;
}

- (NSString *)callToAction {
  NSString *__block callToAction = nil;
  dispatch_sync(_lockQueue, ^{
    callToAction = [self->_nativeAd.callToAction copy];
  });
  return callToAction;
}

- (NSDecimalNumber *)starRating {
  return nil;
}

- (NSString *)store {
  return nil;
}

- (NSString *)price {
  return nil;
}

/// Media view.
- (UIView *GAD_NULLABLE_TYPE)mediaView {
  return _mediaView;
}

/// Returns YES if the ad has video content.
/// Because the FAN SDK doesn't offer a way to determine whether a native ad contains a
/// video asset or not, the adapter always returns a MediaView and claims to have video content.
- (BOOL)hasVideoContent {
  return YES;
}

#pragma mark - GADMediatedNativeAdDelegate

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
         didRenderInView:(UIView *)view
          viewController:(UIViewController *)viewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id obj = [strongConnector networkExtras];
  GADFBNetworkExtras *networkExtras = [obj isKindOfClass:[GADFBNetworkExtras class]] ? obj : nil;
  if (!_adChoicesView) {
    if (networkExtras) {
      _adChoicesView = [[FBAdChoicesView alloc] initWithNativeAd:_nativeAd
                                                      expandable:networkExtras.adChoicesExpandable];
      _adChoicesView.backgroundShown = networkExtras.adChoicesBackgroundShown;
    } else {
      _adChoicesView = [[FBAdChoicesView alloc] initWithNativeAd:_nativeAd];
    }
  }

  UIView *renderedView = view;
  [renderedView addSubview:_adChoicesView];
  CGSize size = CGRectStandardize(_adChoicesView.frame).size;
  NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(_adChoicesView);

  NSString *horizontalFormat, *verticalFormat;
  UIRectCorner corner;
  switch (_nativeAdViewAdOptions.preferredAdChoicesPosition) {
    case GADAdChoicesPositionTopLeftCorner:
      corner = UIRectCornerTopLeft;
      verticalFormat = [[NSString alloc] initWithFormat:@"V:|[_adChoicesView(%f)]", size.height];
      horizontalFormat = [[NSString alloc] initWithFormat:@"H:|[_adChoicesView(%f)]", size.width];
      break;
    case GADAdChoicesPositionBottomLeftCorner:
      corner = UIRectCornerBottomLeft;
      verticalFormat = [[NSString alloc] initWithFormat:@"V:[_adChoicesView(%f)]|", size.height];
      horizontalFormat = [[NSString alloc] initWithFormat:@"H:|[_adChoicesView(%f)]", size.width];
      break;
    case GADAdChoicesPositionBottomRightCorner:
      corner = UIRectCornerBottomRight;
      verticalFormat = [[NSString alloc] initWithFormat:@"V:[_adChoicesView(%f)]|", size.height];
      horizontalFormat = [[NSString alloc] initWithFormat:@"H:[_adChoicesView(%f)]|", size.width];
      break;
    case GADAdChoicesPositionTopRightCorner:
    // Fall through.
    default:
      // Default placement of AdChoices icon is the top right corner.
      corner = UIRectCornerTopRight;
      verticalFormat = [[NSString alloc] initWithFormat:@"V:|[_adChoicesView(%f)]", size.height];
      horizontalFormat = [[NSString alloc] initWithFormat:@"H:[_adChoicesView(%f)]|", size.width];
      break;
  }
  // FBAdChoicesView's updateFrameFromSuperview: method doesn't add any layout constraints on the
  // view. It only places the view in the specified corner.
  [_adChoicesView updateFrameFromSuperview:corner];
  _adChoicesView.translatesAutoresizingMaskIntoConstraints = NO;

  // Adding vertical layout constraints.
  [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalFormat
                                                               options:0
                                                               metrics:nil
                                                                 views:viewDictionary]];
  // Adding horizontal layout constraints.
  [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontalFormat
                                                               options:0
                                                               metrics:nil
                                                                 views:viewDictionary]];

  // Checking whether the view is instance of GADNativeAppInstallAdView, and if so adding its  asset
  // views to the array that will be registered with Facebook.
  NSMutableArray *assets = [[NSMutableArray alloc] init];
  if ([view isKindOfClass:[GADNativeAppInstallAdView class]]) {
    GADNativeAppInstallAdView *adView = (GADNativeAppInstallAdView *)view;
    if (adView.headlineView != nil) {
      [assets addObject:adView.headlineView];
    }
    if (adView.imageView != nil) {
      [assets addObject:adView.imageView];
    }
    if (adView.iconView != nil) {
      [assets addObject:adView.iconView];
    }
    if (adView.adChoicesView != nil) {
      [assets addObject:adView.adChoicesView];
    }
    if (adView.bodyView != nil) {
      [assets addObject:adView.bodyView];
    }
    if (adView.callToActionView != nil) {
      [assets addObject:adView.callToActionView];
    }
    if (adView.priceView != nil) {
      [assets addObject:adView.priceView];
    }
    if (adView.starRatingView != nil) {
      [assets addObject:adView.starRatingView];
    }
    if (adView.storeView != nil) {
      [assets addObject:adView.storeView];
    }
    if (adView.mediaView != nil) {
      [assets addObject:adView.mediaView];
    }
    // Checking whether the view is an instance of GADUnifiedNativeAdView, and if so adding its
    // asset views to the array that will be registered with Facebook.
  } else if ([view isKindOfClass:[GADUnifiedNativeAdView class]]) {
    GADUnifiedNativeAdView *adView = (GADUnifiedNativeAdView *)view;
    if (adView.headlineView != nil) {
      [assets addObject:adView.headlineView];
    }
    if (adView.imageView != nil) {
      [assets addObject:adView.imageView];
    }
    if (adView.iconView != nil) {
      [assets addObject:adView.iconView];
    }
    if (adView.adChoicesView != nil) {
      [assets addObject:adView.adChoicesView];
    }
    if (adView.bodyView != nil) {
      [assets addObject:adView.bodyView];
    }
    if (adView.callToActionView != nil) {
      [assets addObject:adView.callToActionView];
    }
    if (adView.priceView != nil) {
      [assets addObject:adView.priceView];
    }
    if (adView.starRatingView != nil) {
      [assets addObject:adView.starRatingView];
    }
    if (adView.storeView != nil) {
      [assets addObject:adView.storeView];
    }
    if (adView.mediaView != nil) {
      [assets addObject:adView.mediaView];
    }
    if (adView.advertiserView != nil) {
      [assets addObject:adView.advertiserView];
    }
  } else {
    NSLog(
        @"View is not an instance of GADNativeAppInstallAdView or GADUnifiedNativeAdView, Failed"
        @"to register view for user interaction");
  }

  if (assets.count > 0) {
    [_nativeAd registerViewForInteraction:view
                       withViewController:viewController
                       withClickableViews:assets];
  } else {
    [_nativeAd registerViewForInteraction:view withViewController:viewController];
  }
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
  [_adChoicesView removeFromSuperview];
  [_nativeAd unregisterView];
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd {
  [self loadNativeAdImages];
}

- (void)nativeAdWillLogImpression:(FBNativeAd *)nativeAd {
  if (_impressionLogged) {
    GADFB_LOG(
        @"FBNativeAd is trying to log an impression again. Adapter will ignore duplicate "
         "impression pings.");
    return;
  }

  _impressionLogged = YES;
  [GADMediatedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  [strongConnector adapter:strongAdapter didFailAd:error];
}

- (void)nativeAdDidClick:(FBNativeAd *)nativeAd {
  [GADMediatedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];
}

- (void)nativeAdDidFinishHandlingClick:(FBNativeAd *)nativeAd {
  // Do nothing.
}

#pragma mark - FBMediaViewDelegate

- (void)mediaViewVideoDidComplete:(FBMediaView *)mediaView {
  [GADMediatedNativeAdNotificationSource mediatedNativeAdDidEndVideoPlayback:self];
}

- (void)mediaViewVideoDidPlay:(FBMediaView *)mediaView {
  [GADMediatedNativeAdNotificationSource mediatedNativeAdDidPlayVideo:self];
}

- (void)mediaViewVideoDidPause:(FBMediaView *)mediaView {
  [GADMediatedNativeAdNotificationSource mediatedNativeAdDidPauseVideo:self];
}

@end
