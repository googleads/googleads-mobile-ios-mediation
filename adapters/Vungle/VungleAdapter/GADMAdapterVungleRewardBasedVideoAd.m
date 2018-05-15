#import "GADMAdapterVungleRewardBasedVideoAd.h"
#import <GoogleMobileAds/Mediation/GADMRewardBasedVideoAdNetworkConnectorProtocol.h>
#import "VungleAdNetworkExtras.h"
#import "vungleHelper.h"

@interface GADMAdapterVungleRewardBasedVideoAd ()<VungleDelegate>
@property(nonatomic, weak) id<GADMRewardBasedVideoAdNetworkConnector> connector;
@end

@implementation GADMAdapterVungleRewardBasedVideoAd

+ (NSString *)adapterVersion {
  return [vungleHelper adapterVersion];
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [VungleAdNetworkExtras class];
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
    (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
    [[vungleHelper sharedInstance] addDelegate:self];
  }
  return self;
}

- (void)dealloc {
  [self stopBeingDelegate];
}

- (void)setUp {
  [vungleHelper
      parseServerParameters:[_connector credentials]
              networkExtras:[_connector networkExtras]
                     result:^void(NSDictionary *error, NSString *appId) {
                       if (error) {
                         [_connector adapter:self
                             didFailToSetUpRewardBasedVideoAdWithError:
                                 [NSError errorWithDomain:@"GADMAdapterVungleRewardBasedVideoAd"
                                                     code:0
                                                 userInfo:error]];
                         return;
                       }
                       [vungleHelper updateConsentStatus:[_connector networkExtras]];
                       waitingInit = YES;
                       [[vungleHelper sharedInstance] initWithAppId:appId];
                     }];
}

- (void)requestRewardBasedVideoAd {
  desiredPlacement = [vungleHelper findPlacement:[_connector credentials]
                                   networkExtras:[_connector networkExtras]];
  if (!desiredPlacement) {
    [_connector adapter:self
        didFailToLoadRewardBasedVideoAdwithError:
            [NSError
                errorWithDomain:@"GADMAdapterVungleRewardBasedVideoAd"
                           code:0
                       userInfo:@{NSLocalizedDescriptionKey : @"'placementID' not specified"}]];
    return;
  }
  [[vungleHelper sharedInstance] loadAd:desiredPlacement];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  if (![[vungleHelper sharedInstance] playAd:viewController
                                    delegate:self
                                      extras:[_connector networkExtras]]) {
    [_connector adapterDidCloseRewardBasedVideoAd:self];
  }
}

- (void)stopBeingDelegate {
  _connector = nil;
  [[vungleHelper sharedInstance] removeDelegate:self];
}

#pragma mark - vungleHelper delegates

@synthesize desiredPlacement;

@synthesize waitingInit;

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  waitingInit = NO;
  if (isSuccess) {
    [_connector adapterDidSetUpRewardBasedVideoAd:self];
  } else {
    [_connector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
}

- (void)adAvailable {
  [_connector adapterDidReceiveRewardBasedVideoAd:self];
}

- (void)willShowAd {
  [_connector adapterDidOpenRewardBasedVideoAd:self];
  [_connector adapterDidStartPlayingRewardBasedVideoAd:self];
}

- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  // not used
}

- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  if (completedView) {
    GADAdReward *reward =
        [[GADAdReward alloc] initWithRewardType:@"vungle"
                                   rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
    [_connector adapter:self didRewardUserWithReward:reward];
  }
  if (didDownload) {
    [_connector adapterDidGetAdClick:self];
    [_connector adapterWillLeaveApplication:self];
  }
  [_connector adapterDidCloseRewardBasedVideoAd:self];
  desiredPlacement = nil;
}

@end
