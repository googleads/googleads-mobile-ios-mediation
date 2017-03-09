@import GoogleMobileAds;

#import "MoPubAdapterConstants.h"
#import "MoPubAdapterMediatedNativeAd.h"
#import "MPAdDestinationDisplayAgent.h"
#import "MPCoreInstanceProvider.h"
#import "MPNativeAd.h"
#import "MPNativeAdConstants.h"

@interface MoPubAdapterMediatedNativeAd () <GADMediatedNativeAdDelegate, MPAdDestinationDisplayAgentDelegate>

@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, copy) GADNativeAdImage *mappedLogo;
@property(nonatomic, copy) NSDictionary *extras;
@property(nonatomic, copy) MPNativeAd *nativeAd;
@property(nonatomic, copy) NSDictionary *nativeAdProperties;
@property(nonatomic) MPAdDestinationDisplayAgent *displayDestinationAgent;
@property(nonatomic) UIViewController *baseViewController;
@property(nonatomic) GADNativeAdViewAdOptions *nativeAdViewOptions;
@property(nonatomic) GADMoPubNetworkExtras *networkExtras;
@property(nonatomic) UIImageView *privacyIconImageView;
@end


@implementation MoPubAdapterMediatedNativeAd

- (instancetype)initWithMoPubNativeAd:
        (nonnull MPNativeAd *)moPubNativeAd mappedImages: (NSMutableDictionary *)downloadedImages nativeAdViewOptions: (nonnull GADNativeAdViewAdOptions*) nativeAdViewOptions networkExtras:(nullable GADMoPubNetworkExtras *)networkExtras {
    
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
    
      if(downloadedImages!=nil){
          _mappedImages = [[NSArray alloc] initWithObjects:[downloadedImages objectForKey:kAdMainImageKey], nil];
          _mappedLogo = [downloadedImages objectForKey:kAdIconImageKey];
          
      }
      else{
          NSURL *mainImageUrl = [[NSURL alloc] initFileURLWithPath:[self.nativeAdProperties objectForKey:kAdMainImageKey]];
          _mappedImages = @[ [[GADNativeAdImage alloc] initWithURL:mainImageUrl scale:defaultImageScale] ];

          NSURL *logoImageURL = [[NSURL alloc] initFileURLWithPath:[self.nativeAdProperties objectForKey:kAdIconImageKey]];
          _mappedLogo = [[GADNativeAdImage alloc] initWithURL:logoImageURL scale:defaultImageScale];
      }
    
  }
  return self;
}

- (NSString *)headline {
  return [self.nativeAdProperties objectForKey:kAdTitleKey];
}

- (NSString *)body {
  return [self.nativeAdProperties objectForKey:kAdTextKey];
}

- (GADNativeAdImage *)icon {
    return self.mappedLogo;
}

- (NSArray *)images {
  return self.mappedImages;
}

- (NSString *)callToAction {
  return [self.nativeAdProperties objectForKey:kAdCTATextKey];
}

- (NSString *)advertiser {
    return nil;
}

- (NSDictionary *)extraAssets {
  return self.extras;
}

- (NSDecimalNumber *)starRating{
    return 0;
}

- (NSString *)store {
    return nil;
}

- (NSString *)price {
    return nil;
}

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return self;
}

- (void)privacyIconTapped
{
    self.displayDestinationAgent = [[MPCoreInstanceProvider sharedProvider] buildMPAdDestinationDisplayAgentWithDelegate:self];
    [self.displayDestinationAgent displayDestinationForURL:[NSURL URLWithString:kDAAIconTapDestinationURL]];
}


#pragma mark - GADMediatedNativeAdDelegate implementation

#pragma GCC diagnostic ignored "-Wundeclared-selector"

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
         didRenderInView:(UIView *)view viewController:(UIViewController *)viewController;
{

    UIImage *privacyIconImage = [UIImage imageNamed:kDAAIconImageName];
    
    self.baseViewController = viewController;
    
    [_nativeAd performSelector:@selector(willAttachToView:) withObject:view];
    
    self.privacyIconImageView = [[UIImageView alloc] initWithImage:privacyIconImage];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(privacyIconTapped)];
    self.privacyIconImageView.userInteractionEnabled = YES;
    [self.privacyIconImageView addGestureRecognizer:tapRecognizer];
  
    float privacyIconSize;
    if (_networkExtras) {
      if (_networkExtras.privacyIconSize < MINIMUM_MOPUB_PRIVACY_ICON_SIZE) {
        privacyIconSize = MINIMUM_MOPUB_PRIVACY_ICON_SIZE;
      }
      else if (_networkExtras.privacyIconSize > MAXIMUM_MOPUB_PRIVACY_ICON_SIZE) {
        privacyIconSize = MAXIMUM_MOPUB_PRIVACY_ICON_SIZE;
      }
      else {
        privacyIconSize = _networkExtras.privacyIconSize;
      }
    } else {
      privacyIconSize = DEFAULT_MOPUB_PRIVACY_ICON_SIZE;
    }
  
    switch (_nativeAdViewOptions.preferredAdChoicesPosition) {
        case GADAdChoicesPositionTopLeftCorner:
            self.privacyIconImageView.frame = CGRectMake(0, 0, privacyIconSize, privacyIconSize);
            self.privacyIconImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        case GADAdChoicesPositionBottomLeftCorner:
            self.privacyIconImageView.frame = CGRectMake(0, view.bounds.size.height-privacyIconSize, privacyIconSize, privacyIconSize);
            self.privacyIconImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        case GADAdChoicesPositionBottomRightCorner:
            self.privacyIconImageView.frame = CGRectMake(view.bounds.size.width-privacyIconSize, view.bounds.size.height-privacyIconSize, privacyIconSize, privacyIconSize);
            self.privacyIconImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
            break;
        case GADAdChoicesPositionTopRightCorner:
            self.privacyIconImageView.frame = CGRectMake(view.bounds.size.width-privacyIconSize, 0, privacyIconSize, privacyIconSize);
            self.privacyIconImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
            break;
        default:
            self.privacyIconImageView.frame = CGRectMake(view.bounds.size.width-privacyIconSize, 0, privacyIconSize, privacyIconSize);
            self.privacyIconImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
            break;
    }
    
    [view addSubview:self.privacyIconImageView];
 
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
    didRecordClickOnAssetWithName:(NSString *)assetName
                             view:(UIView *)view
                   viewController:(UIViewController *)viewController {
  if (self.nativeAd) {
      [_nativeAd performSelector:@selector(adViewTapped)];
  }
    
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
    if(self.privacyIconImageView) {
        [self.privacyIconImageView removeFromSuperview];
    }
}

#pragma mark - MPAdDestinationDisplayAgentDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return self.baseViewController;
}

- (void)displayAgentDidDismissModal
{
    [GADMediatedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:self];
    [GADMediatedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:self];
}

- (void)displayAgentWillPresentModal
{
    [GADMediatedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:self];
}

- (void)displayAgentWillLeaveApplication
{
    [GADMediatedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}


@end
