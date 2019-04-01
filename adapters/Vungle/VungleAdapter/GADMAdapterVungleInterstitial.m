#import "GADMAdapterVungleInterstitial.h"
#import <GoogleMobileAds/Mediation/GADMAdNetworkConnectorProtocol.h>
#import "VungleRouter.h"

@interface GADMAdapterVungleInterstitial () <VungleDelegate>
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@end

@implementation GADMAdapterVungleInterstitial

+ (NSString *)adapterVersion {
  return [VungleRouter adapterVersion];
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [VungleAdNetworkExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
    [[VungleRouter sharedInstance] addDelegate:self];
  }
  return self;
}

- (void)dealloc {
  [self stopBeingDelegate];
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *error = [NSError
      errorWithDomain:@"google"
                 code:0
             userInfo:@{NSLocalizedDescriptionKey : @"Vungle doesn't support banner ads."}];
  [_connector adapter:self didFailAd:error];
}

- (void)loadAd {
  [[VungleRouter sharedInstance] loadAd:desiredPlacement];
}

- (void)getInterstitial {
  [VungleRouter
      parseServerParameters:[_connector credentials]
              networkExtras:[_connector networkExtras]
                     result:^void(NSDictionary *error, NSString *appId) {
                       if (error) {
                         [_connector
                               adapter:self
                             didFailAd:[NSError errorWithDomain:@"GADMAdapterVungleInterstitial"
                                                           code:0
                                                       userInfo:error]];
                         return;
                       }
                       desiredPlacement = [VungleRouter findPlacement:[_connector credentials]
                                                        networkExtras:[_connector networkExtras]];
                       if (!desiredPlacement) {
                         [_connector
                               adapter:self
                             didFailAd:[NSError errorWithDomain:@"GADMAdapterVungleInterstitial"
                                                           code:0
                                                       userInfo:@{
                                                         NSLocalizedDescriptionKey :
                                                             @"'placementID' not specified"
                                                       }]];
                         return;
                       }
                       [[VungleRouter sharedInstance] initWithAppId:appId delegate:self];
                     }];
}

- (void)stopBeingDelegate {
  _connector = nil;
  [[VungleRouter sharedInstance] removeDelegate:self];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  if (![[VungleRouter sharedInstance] playAd:rootViewController
                                    delegate:self
                                      extras:[_connector networkExtras]]) {
    [_connector adapterDidDismissInterstitial:self];
  }
}

#pragma mark - VungleRouter delegates

@synthesize desiredPlacement;

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  if (isSuccess && desiredPlacement) {
    if (desiredPlacement) {
      [self loadAd];
    }
  } else {
    [_connector adapter:self didFailAd:error];
  }
}

- (void)adAvailable {
  [_connector adapterDidReceiveInterstitial:self];
}

- (void)willShowAd {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  if (didDownload) {
    [_connector adapterDidGetAdClick:self];
    [_connector adapterWillLeaveApplication:self];
  }
  [_connector adapterWillDismissInterstitial:self];
}

- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  [_connector adapterDidDismissInterstitial:self];
  desiredPlacement = nil;
}

@end
