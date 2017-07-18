#import <GoogleMobileAds/Mediation/GADMAdNetworkConnectorProtocol.h>
#import "GADMAdapterVungleInterstitial.h"
#import "vungleHelper.h"

static NSString *const kGADMAdapterVungleInterstitialKeyApplicationID = @"application_id";

@interface GADMAdapterVungleInterstitial () <VungleDelegate>
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@end

@implementation GADMAdapterVungleInterstitial

+ (NSString *)adapterVersion {
    return [vungleHelper adapterVersion];
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
	return [VungleAdNetworkExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
	self = [super init];
	if (self) {
		self.connector = connector;
		[vungleHelper sharedInstance].interstitialDelegate = self;
	}
	return self;
}


- (void)dealloc {
	[vungleHelper sharedInstance].interstitialDelegate = nil;
}

- (void)getBannerWithSize:(GADAdSize)adSize{
	NSError *error = [NSError errorWithDomain:@"google"
										 code:0
									 userInfo:@{
												NSLocalizedDescriptionKey : @"Vungle doesn't support banner ads."
												}];
	[_connector adapter:self didFailAd:error];
}

- (void) loadAd {
	if ([[vungleHelper sharedInstance] isAdPlayableFor:desiredPlacement]) {
		[_connector adapterDidReceiveInterstitial:self];
	} else {
		[[vungleHelper sharedInstance] loadAd:InterstitialAdapter placement:desiredPlacement];
	}
}


- (void)getInterstitial {
	VungleAdNetworkExtras* extras = [_connector networkExtras];
	desiredPlacement = extras.playingPlacement;
	if (!extras || !extras.allPlacements || [extras.allPlacements count] == 0) {
		NSLog(@"Placements should be specified!");
		[_connector adapter:self didFailAd:[NSError errorWithDomain:@"GADMAdapterVungleInterstitial" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Placements should be specified!"}]];
		return;
	}
	
	if ([[vungleHelper sharedInstance] isInitialised]) {
		[self loadAd];
	} else {
		NSDictionary *serverParameters = [_connector credentials];
		NSString *applicationID = [serverParameters objectForKey:kGADMAdapterVungleInterstitialKeyApplicationID];
		[[vungleHelper sharedInstance] initWithAppId:applicationID placements:extras.allPlacements adapter:InterstitialAdapter];
	}
}

- (void)stopBeingDelegate {
	_connector = nil;
	[vungleHelper sharedInstance].interstitialDelegate = nil;
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType{
	return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController{
    if (![[vungleHelper sharedInstance] playAd:rootViewController adapter:InterstitialAdapter placement:desiredPlacement extras:[_connector networkExtras]]) {
        [_connector adapterDidDismissInterstitial:self];
    }
}

#pragma mark - vungleHelper delegates


@synthesize desiredPlacement;

-(void)initialized:(BOOL)isSuccess error:(NSError *)error {
	if (isSuccess) {
		if (desiredPlacement) {
			[self loadAd];
		}
	} else {
		[_connector adapter:self didFailAd:error];
	}
}

-(void)adAvailable{
	[_connector adapterDidReceiveInterstitial:self];
}

-(void)willShowAd{
	[_connector adapterWillPresentInterstitial:self];
}

-(void)willLeaveApplication {
	[_connector adapterWillLeaveApplication:self];
}

-(void)willCloseAd:(bool)completedView{
	[_connector adapterWillDismissInterstitial:self];
	[_connector adapterDidDismissInterstitial:self];
}

@end
