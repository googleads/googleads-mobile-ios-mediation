#import <GoogleMobileAds/Mediation/GADMRewardBasedVideoAdNetworkConnectorProtocol.h>
#import "GADMAdapterVungleRewardBasedVideoAd.h"
#import "vungleHelper.h"
#import "VungleAdNetworkExtras.h"

static NSString *const kGADMAdapterVungleRewardBasedVideoAdKeyApplicationID = @"application_id";

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

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:(id<GADMRewardBasedVideoAdNetworkConnector>)connector {
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
    NSDictionary *serverParameters = [_connector credentials];
    NSString *applicationID = [serverParameters objectForKey:kGADMAdapterVungleRewardBasedVideoAdKeyApplicationID];
	VungleAdNetworkExtras* extras = [_connector networkExtras];
	if (!extras || !extras.allPlacements || [extras.allPlacements count] == 0) {
		NSLog(@"Placements should be specified!");
		[_connector adapter:self didFailToSetUpRewardBasedVideoAdWithError:[NSError errorWithDomain:@"GADMAdapterVungleRewardBasedVideoAd" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Placements should be specified!"}]];
		return;
	}
	waitingInit = YES;
	[[vungleHelper sharedInstance] initWithAppId:applicationID placements:extras.allPlacements];
}

- (void)requestRewardBasedVideoAd {
	desiredPlacement = ((VungleAdNetworkExtras *)[_connector networkExtras]).playingPlacement;
	[[vungleHelper sharedInstance] loadAd:desiredPlacement];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
	if (![[vungleHelper sharedInstance] playAd:viewController delegate:self extras:[_connector networkExtras]]) {
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

-(void)willCloseAd:(bool)completedView{
	if (completedView){
		GADAdReward* reward = [[GADAdReward alloc] initWithRewardType:@"vungle" rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
		[_connector adapter:self didRewardUserWithReward:reward];
	}
	[_connector adapterDidCloseRewardBasedVideoAd:self];
	desiredPlacement = nil;
}

@end
