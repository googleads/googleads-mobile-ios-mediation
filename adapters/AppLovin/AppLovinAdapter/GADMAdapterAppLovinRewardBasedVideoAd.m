//
//  GADMAdapterAppLovinRewardBasedVideoAd.m
//
//
//  Created by Thomas So on 5/20/17.
//
//

#import "GADMAdapterAppLovinRewardBasedVideoAd.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinExtras.h"
#import <AppLovinSDK/AppLovinSDK.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface GADMAdapterAppLovinRewardBasedVideoAd () <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate, ALAdRewardDelegate>

@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic, strong) ALIncentivizedInterstitialAd *incent;

@property (nonatomic, assign) BOOL fullyWatched;
@property (nonatomic, strong) GADAdReward *reward;
@property (nonatomic,   copy) NSString *placement;

@property (nonatomic,   weak) id<GADMRewardBasedVideoAdNetworkConnector> connector;
@property (nonatomic, strong) GADMAdapterAppLovinExtras *extras;

@end

@implementation GADMAdapterAppLovinRewardBasedVideoAd

#pragma mark - GADMRewardBasedVideoAdNetworkAdapter Methods

+ (NSString *)adapterVersion
{
    return GADMAdapterAppLovinConstant.adapterVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass
{
    return [GADMAdapterAppLovinExtras class];
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:(id<GADMRewardBasedVideoAdNetworkConnector>)connector
{
    self = [super init];
    if ( self )
    {
        self.connector = connector;
    }
    return self;
}

- (void)setUp
{
    [self log: @"Attempting to initialize SDK"];
    
    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials: self.connector.credentials];
    
    if ( self.sdk )
    {
        [self log: @"Successfully initialized SDK"];
        [self.connector adapterDidSetUpRewardBasedVideoAd: self];
    }
    else
    {
        [self log: @"Failed to initialize SDK"];
        NSError *error = [NSError errorWithDomain: GADMAdapterAppLovinConstant.errorDomain
                                             code: kGADErrorMediationAdapterError
                                         userInfo: @{NSLocalizedFailureReasonErrorKey : @"Failed to initialize AppLovin rewarded video adapter"}];
        [self.connector adapter: self didFailToSetUpRewardBasedVideoAdWithError: error];
    }
}

- (void)requestRewardBasedVideoAd
{
    [self log: @"Requesting rewarded video"];
    
    self.placement = self.connector.credentials[GADMAdapterAppLovinConstant.placementKey];
    
    if ( [self.incent isReadyForDisplay] )
    {
        [self.connector adapterDidReceiveRewardBasedVideoAd: self];
    }
    else
    {
        [self.incent preloadAndNotify: self];
    }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController
{
    if ( [self.incent isReadyForDisplay] )
    {
        // Reset reward states
        self.reward = nil;
        self.fullyWatched = NO;
        
        // Update mute state
        GADMAdapterAppLovinExtras *networkExtras = self.connector.networkExtras;
        self.sdk.settings.muted = networkExtras.muteAudio;
        
        [self.incent showOver: [UIApplication sharedApplication].keyWindow
                    placement: self.placement
                    andNotify: self];
    }
    else
    {
        [self log: @"Adapter requested to display a rewarded video before one was loaded"];
        [self.connector adapterDidOpenRewardBasedVideoAd: self];
        [self.connector adapterDidCloseRewardBasedVideoAd: self];
    }
}

- (void)stopBeingDelegate
{
    self.connector = nil;
    
    self.incent.adVideoPlaybackDelegate = nil;
    self.incent.adDisplayDelegate = nil;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    [self log: @"Rewarded video did load ad: %@", ad.adIdNumber];
    [self.connector adapterDidReceiveRewardBasedVideoAd: self];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    [self log: @"Rewarded video failed to load with error: %d", code];
    
    NSError *error = [NSError errorWithDomain: GADMAdapterAppLovinConstant.errorDomain
                                         code: [GADMAdapterAppLovinUtils toAdMobErrorCode: code]
                                     userInfo: @{NSLocalizedFailureReasonErrorKey : @"Adapter requested to display a rewarded video before one was loaded"}];
    [self.connector adapter: self didFailToLoadRewardBasedVideoAdwithError: error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view
{
    [self log: @"Rewarded video displayed"];
    [self.connector adapterDidOpenRewardBasedVideoAd: self];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view
{
    [self log: @"Rewarded video dismissed"];
    
    if ( self.fullyWatched && self.reward )
    {
        [self.connector adapter: self didRewardUserWithReward: self.reward];
    }
    
    [self.connector adapterDidCloseRewardBasedVideoAd: self];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view
{
    [self log: @"Rewarded video clicked"];
    
    [self.connector adapterDidGetAdClick: self];
    [self.connector adapterWillLeaveApplication: self];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad
{
    [self log: @"Rewarded video playback began"];
    [self.connector adapterDidStartPlayingRewardBasedVideoAd: self];
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad atPlaybackPercent:(NSNumber *)percentPlayed fullyWatched:(BOOL)wasFullyWatched
{
    [self log: @"Rewarded video playback ended at playback percent: %lu%%", percentPlayed.unsignedIntegerValue];
    
    self.fullyWatched = wasFullyWatched;
}

#pragma mark - Reward Delegate

- (void)rewardValidationRequestForAd:(ALAd *)ad didExceedQuotaWithResponse:(NSDictionary *)response
{
    [self log: @"Rewarded video validation request for ad did exceed quota with response: %@", response];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad didFailWithError:(NSInteger)responseCode
{
    [self log: @"Rewarded video validation request for ad failed with error code: %ld", responseCode];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad wasRejectedWithResponse:(NSDictionary *)response
{
    [self log: @"Rewarded video validation request was rejected with response: %@", response];
}

- (void)userDeclinedToViewAd:(ALAd *)ad
{
    [self log: @"User declined to view rewarded video"];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad didSucceedWithResponse:(NSDictionary *)response
{
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString: response[@"amount"]];
    NSString *currency = response[@"currency"];
    
    [self log: @"Rewarded %@ %@", amount, currency];
    
    self.reward = [[GADAdReward alloc] initWithRewardType: currency rewardAmount: amount];
}

#pragma mark - Incentivized Interstitial

- (ALIncentivizedInterstitialAd *)incent
{
    if ( !_incent )
    {
        _incent = [[ALIncentivizedInterstitialAd alloc] initWithSdk: self.sdk];
        _incent.adVideoPlaybackDelegate = self;
        _incent.adDisplayDelegate = self;
    }
    
    return _incent;
}

#pragma mark - Logging

- (void)log:(NSString *)format, ...
{
    if ( GADMAdapterAppLovinConstant.loggingEnabled )
    {
        va_list valist;
        va_start(valist, format);
        NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
        va_end(valist);
        
        NSLog(@"AppLovinRewardedAdapter: %@", message);
    }
}

@end

#pragma clang diagnostic pop
