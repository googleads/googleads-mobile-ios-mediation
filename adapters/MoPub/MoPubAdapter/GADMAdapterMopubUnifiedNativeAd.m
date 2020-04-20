#import "GADMAdapterMopubUnifiedNativeAd.h"

#import "GADMAdapterMoPubConstants.h"
#import "MPAdDestinationDisplayAgent.h"
#import "MPCoreInstanceProvider.h"
#import "MPLogging.h"
#import "MPNativeAd.h"
#import "MPNativeAdConstants.h"

@interface GADMAdapterMopubUnifiedNativeAd () <MPAdDestinationDisplayAgentDelegate>
@end

@implementation GADMAdapterMopubUnifiedNativeAd {
  /// Main image.
  GADNativeAdImage *_mainImage;

  /// Media view.
  UIImageView *_mediaView;

  /// Icon image.
  GADNativeAdImage *_iconImage;

  /// Dictionary of extra assets which are sent to the Google Moile Ads SDK.
  NSDictionary<NSString *, id> *_extras;

  /// MoPub native ad.
  MPNativeAd *_nativeAd;

  /// A dictionary representing the MoPub native ad properties.
  NSDictionary<NSString *, id> *_nativeAdProperties;

  /// Display agent that helps presenting the destination URL when the ad choices is been clicked.
  MPAdDestinationDisplayAgent *_displayDestinationAgent;

  /// ViewController that should be used to present modal views for the ad.
  UIViewController *_baseViewController;

  /// Ad loader options for configuring the view of native ads.
  GADNativeAdViewAdOptions *_nativeAdViewOptions;

  /// Network extras set by the publisher.
  GADMoPubNetworkExtras *_networkExtras;

  /// MoPub's privacy icon image view.
  UIImageView *_privacyIconImageView;
}

- (nonnull instancetype)initWithMoPubNativeAd:(nonnull MPNativeAd *)mopubNativeAd
                                    mainImage:(nullable GADNativeAdImage *)mainImage
                                    iconImage:(nullable GADNativeAdImage *)iconImage
                          nativeAdViewOptions:
                              (nonnull GADNativeAdViewAdOptions *)nativeAdViewOptions
                                networkExtras:(nullable GADMoPubNetworkExtras *)networkExtras {
  self = [super init];
  if (self) {
    _nativeAd = mopubNativeAd;
    _nativeAdProperties = mopubNativeAd.properties;
    _nativeAdViewOptions = nativeAdViewOptions;
    _networkExtras = networkExtras;

    CGFloat defaultImageScale = 1;
    if (mainImage) {
      _mainImage = mainImage;
    } else {
      NSURL *imageURL = [NSURL URLWithString:_nativeAdProperties[kAdMainImageKey]];
      if (imageURL) {
        mainImage = [[GADNativeAdImage alloc] initWithURL:imageURL scale:defaultImageScale];
      }
    }

    _mediaView = [[UIImageView alloc] initWithImage:_mainImage.image];

    if (iconImage) {
      _iconImage = iconImage;
    } else {
      NSURL *logoImageURL = [NSURL URLWithString:_nativeAdProperties[kAdIconImageKey]];
      if (logoImageURL) {
        _iconImage = [[GADNativeAdImage alloc] initWithURL:logoImageURL scale:defaultImageScale];
      }
    }
  }
  return self;
}

#pragma mark - GADMediatedUnifiedNativeAd implementation

- (nullable NSString *)headline {
  return _nativeAdProperties[kAdTitleKey];
}

- (nullable NSString *)body {
  return _nativeAdProperties[kAdTextKey];
}

- (nullable GADNativeAdImage *)icon {
  return _iconImage;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return @[ _mainImage ];
}

- (nullable NSString *)callToAction {
  return _nativeAdProperties[kAdCTATextKey];
}

- (nullable NSString *)advertiser {
  return nil;
}

- (nullable NSDictionary *)extraAssets {
  return _extras;
}

- (nullable NSDecimalNumber *)starRating {
  return 0;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable UIView *)mediaView {
  return _mediaView;
}

- (BOOL)hasVideoContent {
  return NO;
}

- (CGFloat)mediaContentAspectRatio {
  if (_mainImage) {
    if (_mainImage.image.size.height > 0) {
      return (_mainImage.image.size.width / _mainImage.image.size.height);
    }
  }
  return 0.0f;
}

- (void)privacyIconTapped {
  _displayDestinationAgent = [MPAdDestinationDisplayAgent agentWithDelegate:self];
  [_displayDestinationAgent
      displayDestinationForURL:[NSURL URLWithString:kPrivacyIconTapDestinationURL]];
}

#pragma GCC diagnostic ignored "-Wundeclared-selector"

- (void)didRenderInView:(UIView *)view
       clickableAssetViews:
           (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  _baseViewController = viewController;
  if ([_nativeAd respondsToSelector:@selector(willAttachToView:withAdContentViews:)]) {
    [_nativeAd performSelector:@selector(willAttachToView:withAdContentViews:)
                    withObject:view
                    withObject:nil];
  } else {
    MPLogWarn(@"Could not add impression trackers.");
  }

  UITapGestureRecognizer *tapRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(privacyIconTapped)];

  // Loading the MoPub privacy icon either from the Main or the MoPub bundle.
  NSString *privacyIconImagePath = MPResourcePathForResource(kPrivacyIconImageName);
  UIImage *privacyIconImage = [UIImage imageWithContentsOfFile:privacyIconImagePath];
  _privacyIconImageView = [[UIImageView alloc] initWithImage:privacyIconImage];
  _privacyIconImageView.userInteractionEnabled = YES;
  [_privacyIconImageView addGestureRecognizer:tapRecognizer];

  float privacyIconSize;
  if (_networkExtras) {
    if (_networkExtras.privacyIconSize < MINIMUM_MOPUB_PRIVACY_ICON_SIZE) {
      privacyIconSize = MINIMUM_MOPUB_PRIVACY_ICON_SIZE;
    } else if (_networkExtras.privacyIconSize > MAXIMUM_MOPUB_PRIVACY_ICON_SIZE) {
      privacyIconSize = MAXIMUM_MOPUB_PRIVACY_ICON_SIZE;
    } else {
      privacyIconSize = _networkExtras.privacyIconSize;
    }
  } else {
    privacyIconSize = DEFAULT_MOPUB_PRIVACY_ICON_SIZE;
  }

  switch (_nativeAdViewOptions.preferredAdChoicesPosition) {
    case GADAdChoicesPositionTopLeftCorner:
      _privacyIconImageView.frame = CGRectMake(0, 0, privacyIconSize, privacyIconSize);
      _privacyIconImageView.autoresizingMask =
          UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
      break;
    case GADAdChoicesPositionBottomLeftCorner:
      _privacyIconImageView.frame = CGRectMake(0, view.bounds.size.height - privacyIconSize,
                                               privacyIconSize, privacyIconSize);
      _privacyIconImageView.autoresizingMask =
          UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
      break;
    case GADAdChoicesPositionBottomRightCorner:
      _privacyIconImageView.frame =
          CGRectMake(view.bounds.size.width - privacyIconSize,
                     view.bounds.size.height - privacyIconSize, privacyIconSize, privacyIconSize);
      _privacyIconImageView.autoresizingMask =
          UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
      break;
    case GADAdChoicesPositionTopRightCorner:
      _privacyIconImageView.frame =
          CGRectMake(view.bounds.size.width - privacyIconSize, 0, privacyIconSize, privacyIconSize);
      _privacyIconImageView.autoresizingMask =
          UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
      break;
    default:
      _privacyIconImageView.frame =
          CGRectMake(view.bounds.size.width - privacyIconSize, 0, privacyIconSize, privacyIconSize);
      _privacyIconImageView.autoresizingMask =
          UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
      break;
  }

  [view addSubview:_privacyIconImageView];
}

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  if (_nativeAd) {
    [_nativeAd performSelector:@selector(adViewTapped)];
  }
}

- (void)didUntrackView:(UIView *)view {
  if (_privacyIconImageView) {
    [_privacyIconImageView removeFromSuperview];
  }
}

#pragma mark - MPAdDestinationDisplayAgentDelegate

- (UIViewController *)viewControllerForPresentingModalView {
  return _baseViewController;
}

- (void)displayAgentDidDismissModal {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:self];
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:self];
}

- (void)displayAgentWillPresentModal {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:self];
}

- (void)displayAgentWillLeaveApplication {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

@end
