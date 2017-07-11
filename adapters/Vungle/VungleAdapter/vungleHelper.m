#import "vungleHelper.h"

@implementation vungleHelper

static Adapter initializing = 0;
static Adapter waiting = 0;
static Adapter playing = 0;

+ (NSString *)adapterVersion {
    return @"2.0.0";
}

+ (vungleHelper*) sharedInstance{
    static vungleHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[vungleHelper alloc] init];
    });
    return instance;
}

-(id)init{
    self = [super init];
    if (self){
        [VungleSDK sharedSDK].delegate = self;
    }
    return self;
}

-(void)initWithAppId:(NSString *)appId placements:(NSArray<NSString *>*)placements adapter:(Adapter)adapter{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *version = [[vungleHelper adapterVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [[VungleSDK sharedSDK] performSelector:@selector(setPluginName:version:) withObject:@"admob" withObject:version];
#pragma clang diagnostic pop
    });
	VungleSDK* sdk = [VungleSDK sharedSDK];
	if ([sdk isInitialized]) {
		_isInitialised = true;
		return;
	}
	initializing |= adapter;
	if ([self isInitialising]) {
		return;
	}
	
	_isInitialising = true;
	
	NSError* err = nil;
	[sdk startWithAppId:appId placements:placements error:&err];
	if (err) {
		[self initialized:false error:err];
	}
}

-(BOOL)isAdPlayableFor:(NSString *)placement{
	return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placement];
}

-(void)loadAd:(Adapter)adapter placement:(NSString *)placement {
    waiting |= adapter;
	VungleSDK* sdk = [VungleSDK sharedSDK];
	if ([sdk isAdCachedForPlacementID:placement]) {
		[self vungleAdPlayabilityUpdate:true placementID:placement];
		return;
	}
	[sdk loadPlacementWithID:placement error:nil];
}

- (BOOL)playAd:(UIViewController *)viewController adapter:(Adapter)adapter placement:(NSString *)placement extras:(VungleAdNetworkExtras *)extras {
	if (![[VungleSDK sharedSDK] isAdCachedForPlacementID:placement]) {
		return false;
	}
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    NSError *error = nil;
    bool startPlaying = true;
    [VungleSDK sharedSDK].muted = extras.muted;
    playing |= adapter;
    if (![[VungleSDK sharedSDK] playAd:viewController options:options placementID:placement error:&error]){
        playing &= ~adapter;
        startPlaying = false;
    }
    if (error) {
        NSLog(@"Adapter failed to present reward based video ad, error %@", [error localizedDescription]);
        playing &= ~adapter;
        startPlaying = false;
    };
    return startPlaying;
}

-(void)initialized:(BOOL)isSuccess error:(NSError *)error {
	_isInitialising = false;
	if (isSuccess) {
		_isInitialised = true;
	}
	if ((initializing & InterstitialAdapter) && _interstitialDelegate && [_interstitialDelegate respondsToSelector:@selector(initialized:error:)]) {
		initializing &= ~InterstitialAdapter;
		[_interstitialDelegate initialized:isSuccess error:error];
	}
	
	if ((initializing & RewardBasedAdapter) && _rewardDelegate && [_rewardDelegate respondsToSelector:@selector(initialized:error:)]) {
		initializing &= ~RewardBasedAdapter;
		[_rewardDelegate initialized:isSuccess error:error];
	}
}

#pragma mark - VungleSDKDelegate methods

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
	if ((playing & InterstitialAdapter) && _interstitialDelegate && [_interstitialDelegate respondsToSelector:@selector(willShowAd)]){
		[_interstitialDelegate willShowAd];
	}
	if ((playing & RewardBasedAdapter) && _rewardDelegate && [_rewardDelegate respondsToSelector:@selector(willShowAd)]){
		[_rewardDelegate willShowAd];
	}
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleViewInfo *)info placementID:(nonnull NSString *)placementID {
	if (playing & InterstitialAdapter){
		playing &= ~InterstitialAdapter;
		if (_interstitialDelegate && [_interstitialDelegate respondsToSelector:@selector(willCloseAd:)]){
			[_interstitialDelegate willCloseAd:info.completedView];
		}
	}
	if (playing & RewardBasedAdapter){
		playing &= ~RewardBasedAdapter;
		if (_rewardDelegate && [_rewardDelegate respondsToSelector:@selector(willCloseAd:)]){
			[_rewardDelegate willCloseAd:info.completedView];
		}
	}
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID {
	if (isAdPlayable) {
		if (waiting & InterstitialAdapter) {
			if (_interstitialDelegate &&  [_interstitialDelegate respondsToSelector:@selector(desiredPlacement)]){
				NSString* desired = [_interstitialDelegate desiredPlacement];
				if (!desired || [desired isEqualToString:placementID]) {
					waiting &= ~InterstitialAdapter;
					if ([_interstitialDelegate respondsToSelector:@selector(adAvailable)]) {
						[_interstitialDelegate adAvailable];
					}
				}
			} else {
				waiting &= ~InterstitialAdapter;
			}
		}
		if (waiting & RewardBasedAdapter) {
			if (_rewardDelegate &&  [_rewardDelegate respondsToSelector:@selector(desiredPlacement)]){
				NSString* desired = [_rewardDelegate desiredPlacement];
				if (!desired || [desired isEqualToString:placementID]) {
					waiting &= ~RewardBasedAdapter;
					if ([_rewardDelegate respondsToSelector:@selector(adAvailable)]) {
						[_rewardDelegate adAvailable];
					}
				}
			} else {
				waiting &= ~RewardBasedAdapter;
			}
		}
	}
}

- (void)vungleSDKDidInitialize {
	[self initialized:true error:nil];
}

@end
