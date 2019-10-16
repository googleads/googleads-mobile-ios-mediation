#import "MoPubAdapterMediatedNativeAd.h"

#import "MPAdDestinationDisplayAgent.h"
#import "MPCoreInstanceProvider.h"
#import "MPLogging.h"
#import "MPNativeAd.h"
#import "MPNativeAdConstants.h"
#import "MoPubAdapterConstants.h"

@interface MoPubAdapterMediatedNativeAd () <MPAdDestinationDisplayAgentDelegate>
@end

@implementation MoPubAdapterMediatedNativeAd {
  NSArray<GADNativeAdImage *> *_mappedImages;
  GADNativeAdImage *_mappedLogo;
  NSDictionary<NSString *, id> *_extras;
  MPNativeAd *_nativeAd;
  NSDictionary<NSString *, id> *_nativeAdProperties;
  MPAdDestinationDisplayAgent *_displayDestinationAgent;
  UIViewController *_baseViewController;
  GADNativeAdViewAdOptions *_nativeAdViewOptions;
  GADMoPubNetworkExtras *_networkExtras;
  UIImageView *_privacyIconImageView;
}

- (instancetype)initWithMoPubNativeAd:(nonnull MPNativeAd *)moPubNativeAd
                         mappedImages:(nullable NSMutableDictionary<NSString *, GADNativeAdImage *> *)downloadedImages
                  nativeAdViewOptions:(nonnull GADNativeAdViewAdOptions *)nativeAdViewOptions
                        networkExtras:(nullable GADMoPubNetworkExtras *)networkExtras {
  if (!moPubNativeAd) {
    return nil;
  }
  self = [super init];
  if (self) {
    _nativeAd = moPubNativeAd;
    _nativeAdProperties = moPubNativeAd.properties;
    _nativeAdViewOptions = nativeAdViewOptions;
    _networkExtras = networkExtras;

    CGFloat defaultImageScale = 1;

    if (downloadedImages != nil) {
      _mappedImages =
          [[NSArray alloc] initWithObjects:[downloadedImages objectForKey:kAdMainImageKey], nil];
      if ([downloadedImages objectForKey:kAdIconImageKey]) {
        _mappedLogo = [downloadedImages objectForKey:kAdIconImageKey];
      } else {
        NSURL *logoImageURL =
            [NSURL URLWithString:[_nativeAdProperties objectForKey:kAdIconImageKey]];
        if (logoImageURL != nil) {
          _mappedLogo = [[GADNativeAdImage alloc] initWithURL:logoImageURL scale:defaultImageScale];
        }
      }
    }
  }
  return self;
}

#pragma mark - GADMediatedUnifiedNativeAd implementation

- (NSString *)headline {
  return [_nativeAdProperties objectForKey:kAdTitleKey];
}

- (NSString *)body {
  return [_nativeAdProperties objectForKey:kAdTextKey];
}

- (GADNativeAdImage *)icon {
  return _mappedLogo;
}

- (NSArray *)images {
  return _mappedImages;
}

- (NSString *)callToAction {
  return [_nativeAdProperties objectForKey:kAdCTATextKey];
}

- (NSString *)advertiser {
  return nil;
}

- (NSDictionary *)extraAssets {
  return _extras;
}

- (NSDecimalNumber *)starRating {
  return 0;
}

- (NSString *)store {
  return nil;
}

- (NSString *)price {
  return nil;
}

-(BOOL)hasVideoContent {
  return NO;
}

-(CGFloat)mediaContentAspectRatio {
  if (_mappedImages) {
    GADNativeAdImage *nativeAdImage = (GADNativeAdImage *)_mappedImages[0];
    if (nativeAdImage.image.size.height > 0) {
      return (nativeAdImage.image.size.width / nativeAdImage.image.size.height);
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

- (UIView *GAD_NULLABLE_TYPE)mediaView {
  GADNativeAdImage *nativeAdImage = (GADNativeAdImage *)_mappedImages[0];
  UIImage *image = [(UIImage *)nativeAdImage valueForKey:@"image"];
  UIImageView *mainImageView = [[UIImageView alloc] initWithImage:image];
  return mainImageView;
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
