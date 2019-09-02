#import "GADMAdapterVungleInterstitial.h"
#import <GoogleMobileAds/Mediation/GADMAdNetworkConnectorProtocol.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"
#import "VungleRouter.h"

@interface GADMAdapterVungleInterstitial () <VungleDelegate>
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@end

@implementation GADMAdapterVungleInterstitial

// To check if the ad is presenting so that we don't call 'adapterDidReceiveInterstitial:' twice.
BOOL _isAdPresenting;

+ (NSString *)adapterVersion {
  return kGADMAdapterVungleVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [VungleAdNetworkExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
  }
  return self;
}

- (void)dealloc {
  [self stopBeingDelegate];
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *error = [NSError
      errorWithDomain:kGADMAdapterVungleErrorDomain
                 code:0
             userInfo:@{NSLocalizedDescriptionKey : @"Vungle doesn't support banner ads."}];
  [_connector adapter:self didFailAd:error];
}

- (void)loadInterstitialAd {
  NSError *error = [[VungleRouter sharedInstance] loadAd:desiredPlacement withDelegate:self];
  if (error) {
    [_connector adapter:self didFailAd:error];
  }
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                             networkExtras:[strongConnector networkExtras]];
  if (!desiredPlacement) {
    [strongConnector
          adapter:self
        didFailAd:[NSError errorWithDomain:kGADMAdapterVungleErrorDomain
                                      code:0
                                  userInfo:@{
                                    NSLocalizedDescriptionKey : @"'placementID' not specified"
                                  }]];
    return;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];

  if (![sdk isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
    if (appID) {
      GADMAdapterVungleInterstitial *__weak weakSelf = self;
      [[VungleRouter sharedInstance] initWithAppId:appID delegate:weakSelf];
    } else {
      NSError *error = [NSError
          errorWithDomain:kGADMAdapterVungleErrorDomain
                     code:0
                 userInfo:@{NSLocalizedDescriptionKey : @"Vungle app ID not specified!"}];
      [strongConnector adapter:self didFailAd:error];
    }
  } else {
    [self loadInterstitialAd];
  }
}

- (void)stopBeingDelegate {
  _connector = nil;
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (![[VungleRouter sharedInstance] playAd:rootViewController
                                    delegate:self
                                      extras:[strongConnector networkExtras]]) {
    [strongConnector adapterDidDismissInterstitial:self];
  }
  _isAdPresenting = YES;
}

#pragma mark - VungleRouter delegates

@synthesize desiredPlacement;

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  if (isSuccess && desiredPlacement) {
    [self loadInterstitialAd];
  } else {
    [_connector adapter:self didFailAd:error];
  }
}

- (void)adAvailable {
  if (!_isAdPresenting) {
    [_connector adapterDidReceiveInterstitial:self];
  }
}

- (void)adNotAvailable:(NSError *)error {
  [_connector adapter:self didFailAd:error];
}

- (void)willShowAd {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (didDownload) {
    [strongConnector adapterDidGetAdClick:self];
    [strongConnector adapterWillLeaveApplication:self];
  }
  [strongConnector adapterWillDismissInterstitial:self];
  _isAdPresenting = NO;
}

- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  [_connector adapterDidDismissInterstitial:self];
  desiredPlacement = nil;
}

@end
