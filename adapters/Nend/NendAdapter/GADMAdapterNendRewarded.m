//
//  GADMAdapterNendRewarded.m
//
//  Copyright © 2017 F@N Communications. All rights reserved.
//

#import "GADMAdapterNendRewarded.h"
#import "GADNendRewardedNetworkExtras.h"
@import NendAd;

static NSString *const kNendRewardedAdapterVersion = @"1.0.0";
static NSString *const kAdMobMediationName = @"AdMob";
static NSString *const kDictionaryKeySpotId = @"spotId";
static NSString *const kDictionaryKeyApiKey = @"apiKey";

@interface GADMAdapterNendRewarded() <NADRewardedVideoDelegate>

@property (nonatomic, weak) id<GADMRewardBasedVideoAdNetworkConnector> connector;
@property (nonatomic) NADRewardedVideo *rewardedVideo;

@end

@implementation GADMAdapterNendRewarded

+ (NSString *)adapterVersion
{
    return kNendRewardedAdapterVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass
{
    return [GADNendRewardedNetworkExtras class];
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
(id<GADMRewardBasedVideoAdNetworkConnector>)connector
{
    if (!connector) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _connector = connector;
        _rewardedVideo = nil;
    }
    return self;
}

- (void)setUp
{
    NSString *spotId = [self getNendAdParam:kDictionaryKeySpotId];
    NSString *apiKey = [self getNendAdParam:kDictionaryKeyApiKey];
    
    if (spotId.length != 0 && apiKey.length != 0) {
        self.rewardedVideo = [[NADRewardedVideo alloc] initWithSpotId:spotId apiKey:apiKey];
        self.rewardedVideo.mediationName = kAdMobMediationName;
        
        GADNendRewardedNetworkExtras *extras = [self.connector networkExtras];
        if (extras) {
            self.rewardedVideo.userId = extras.userId;
        }
        
        self.rewardedVideo.delegate = self;
        [self.connector adapterDidSetUpRewardBasedVideoAd:self];
    } else {
        NSLog (@"SpotId and apiKey can not be nil.");
        [self.connector adapter:self didFailToSetUpRewardBasedVideoAdWithError:[NSError errorWithDomain:@"com.google.mediation.nend.rewarded" code:kGADErrorInternalError userInfo:nil]];
    }
}

- (void)requestRewardBasedVideoAd
{
    [self.rewardedVideo loadAd];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController
{
    if (self.rewardedVideo.isReady) {
        [self.rewardedVideo showAdFromViewController:viewController];
    }
}

- (void)stopBeingDelegate
{
    self.rewardedVideo.delegate = nil;
    [self.rewardedVideo releaseVideoAd];
}

#pragma mark - NADRewardedVideoDelegate
- (void)nadRewardVideoAdDidReceiveAd:(NADRewardedVideo *)nadRewardedVideoAd {
    [self.connector adapterDidReceiveRewardBasedVideoAd:self];
}

- (void)nadRewardVideoAd:(NADRewardedVideo *)nadRewardedVideoAd didFailToLoadWithError:(NSError *)error {
    [self.connector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
}

- (void)nadRewardVideoAdDidOpen:(NADRewardedVideo *)nadRewardedVideoAd {
    [self.connector adapterDidOpenRewardBasedVideoAd:self];
}

- (void)nadRewardVideoAdDidClose:(NADRewardedVideo *)nadRewardedVideoAd {
    [self.connector adapterDidCloseRewardBasedVideoAd:self];
}

- (void)nadRewardVideoAdDidStartPlaying:(NADRewardedVideo *)nadRewardedVideoAd {
    [self.connector adapterDidStartPlayingRewardBasedVideoAd:self];
}

- (void)nadRewardVideoAdDidClickAd:(NADRewardedVideo *)nadRewardedVideoAd {
    [self.connector adapterDidGetAdClick:self];
    [self.connector adapterWillLeaveApplication:self];
}

- (void)nadRewardVideoAdDidClickInformation:(NADRewardedVideo *)nadRewardedVideoAd {
    [self.connector adapterWillLeaveApplication:self];
}

- (void)nadRewardVideoAd:(NADRewardedVideo *)nadRewardedVideoAd didReward:(NADReward *)reward {
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInteger:reward.amount] decimalValue]];
    GADAdReward *gadReward = [[GADAdReward alloc] initWithRewardType:reward.name rewardAmount:amount];
    [self.connector adapter:self didRewardUserWithReward:gadReward];
}

- (void)nadRewardVideoAdDidFailedToPlay:(NADRewardedVideo *)nadRewardedVideoAd {
    NSLog (@"No ads to show.");
}

#pragma mark - Internal

- (NSString *)getNendAdParam:(NSString *)paramKey
{
    return [self.connector credentials][paramKey];
}

@end
