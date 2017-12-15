#import <GoogleMobileAds/Mediation/GADMRewardBasedVideoAdNetworkConnectorProtocol.h>
#import "GADMAdapterVungleRewardBasedVideoAd.h"
#import "vungleHelper.h"
#import "VungleAdNetworkExtras.h"

@interface GADMAdapterVungleRewardBasedVideoAd () <VungleDelegate>
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
	[vungleHelper parseServerParameters:[_connector credentials]
                          networkExtras:[_connector networkExtras]
                                 result:^void(NSDictionary* error, NSString* appId, NSArray* placements) {
		if (error) {
			[_connector adapter:self didFailToSetUpRewardBasedVideoAdWithError:[NSError errorWithDomain:@"GADMAdapterVungleRewardBasedVideoAd"
                                                                                                   code:0
                                                                                               userInfo:error]];
			return;
		}
		waitingInit = YES;
		[[vungleHelper sharedInstance] initWithAppId:appId placements:placements];
	}];
}

- (void)requestRewardBasedVideoAd {
	desiredPlacement = [vungleHelper findPlacement:[_connector credentials] networkExtras:[_connector networkExtras]];
	if (!desiredPlacement) {
		desiredPlacement = [[vungleHelper sharedInstance].allPlacements firstObject];
		NSLog(@"'placementID' not specified. Used first one from 'allPlacements': %@", desiredPlacement);
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

-(void)initialized:(BOOL)isSuccess error:(NSError *)error{
	waitingInit = NO;
	if (isSuccess){
		[_connector adapterDidSetUpRewardBasedVideoAd:self];
	} else {
		[_connector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
	}
}

-(void)adAvailable{
	[_connector adapterDidReceiveRewardBasedVideoAd:self];
}

-(void)willShowAd{
	[_connector adapterDidOpenRewardBasedVideoAd:self];
	[_connector adapterDidStartPlayingRewardBasedVideoAd:self];
}

-(void)willLeaveApplication {
	[_connector adapterWillLeaveApplication:self];
}

- (void)willCloseAd:(BOOL)completedView {
	if (completedView){
		GADAdReward* reward = [[GADAdReward alloc] initWithRewardType:@"vungle"
                                                         rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
		[_connector adapter:self didRewardUserWithReward:reward];
	}
	[_connector adapterDidCloseRewardBasedVideoAd:self];
	desiredPlacement = nil;
}

@end
