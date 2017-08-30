
//
//  GADMAdapterAppLovinRewardBasedVideoAd.m
//
//
//  Created by Thomas So on 5/20/17.
//
//

#import "GADMAdapterAppLovinRewardBasedVideoAd.h"
#import "GADMAdapterAppLovinConstants.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinExtras.h"

#if __has_include(<AppLovinSDK/AppLovinSDK.h>)
    #import <AppLovinSDK/AppLovinSDK.h>
#else
    #import "ALSdk.h"
    #import "ALIncentivizedInterstitialAd.h"
#endif

@interface GADMAdapterAppLovinRewardBasedVideoAd() <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate, ALAdRewardDelegate>

@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic, strong) ALIncentivizedInterstitialAd *incent;

@property (nonatomic, assign) BOOL fullyWatched;
@property (nonatomic, strong) GADAdReward *reward;
@property (nonatomic, strong) NSString *placement;

@property (nonatomic,   weak) id<GADMRewardBasedVideoAdNetworkConnector> connector;
@property (nonatomic, strong) GADMAdapterAppLovinExtras *extras;

@end

@implementation GADMAdapterAppLovinRewardBasedVideoAd

#pragma mark - GADMRewardBasedVideoAdNetworkAdapter Protocol

+ (NSString *)adapterVersion
{
    return kGADMAdapterAppLovinVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass
{
    return [GADMAdapterAppLovinExtras class];
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:(id<GADMRewardBasedVideoAdNetworkConnector>)connector
{
    if ( !connector )
    {
        return nil;
    }
    
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

    self.sdk = [GADMAdapterAppLovinUtils sdkForCredentials: _connector.credentials];
    
    if ( self.sdk )
    {
        [self log: @"Successfully initialized SDK"];
        [self.connector adapterDidSetUpRewardBasedVideoAd: self];
    }
    else
    {
        [self log: @"Failed to initialize SDK"];
        NSError *error = [NSError errorWithDomain: kGADMAdapterAppLovinErrorDomain
                                             code: kGADErrorMediationAdapterError
                                         userInfo: @{NSLocalizedFailureReasonErrorKey : @"AppLovin rewarded adapter unable to initialize."}];
        [self.connector adapter: self didFailToSetUpRewardBasedVideoAdWithError: error];
    }
}

- (void)requestRewardBasedVideoAd
{
    [self log: @"Requesting AppLovin rewarded video"];
    
    self.placement = [GADMAdapterAppLovinUtils placementFromCredentials: _connector.credentials];
    
    if ( self.incent.readyForDisplay )
    {
        [_connector adapterDidReceiveRewardBasedVideoAd: self];
    }
    else
    {
        [self.incent preloadAndNotify: self];
    }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController
{
    if ( self.incent.readyForDisplay )
    {
        self.reward = nil;
        self.fullyWatched = NO;
        
        GADMAdapterAppLovinExtras *extras = _connector.networkExtras;
        
        if ( extras && extras.muteAudio )
        {
            self.sdk.settings.muted = YES;
        }
        
        if ( self.placement )
        {
            [self.incent showOver: [UIApplication sharedApplication].keyWindow placement: self.placement andNotify: self];
        }
        else
        {
            [self.incent showAndNotify: self];
        }
    }
    else
    {
        [self log: @"No ad available or attempted to show rewarded video before one was loaded"];
        
        NSError *error = [NSError errorWithDomain: kGADMAdapterAppLovinErrorDomain
                                             code: [GADMAdapterAppLovinUtils toAdMobErrorCode: kALErrorCodeUnableToRenderAd]
                                         userInfo: @{NSLocalizedFailureReasonErrorKey : @"Adaptor requested to display a rewarded video before one was loaded"}];
        
        [_connector adapter: self didFailToSetUpRewardBasedVideoAdWithError: error];
        [_connector adapterDidOpenRewardBasedVideoAd: self];
        [_connector adapterDidCloseRewardBasedVideoAd: self];
    }
}

- (void)stopBeingDelegate
{
    self.connector = nil;
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
    
    NSError *error = [NSError errorWithDomain: kGADMAdapterAppLovinErrorDomain
                                         code: [GADMAdapterAppLovinUtils toAdMobErrorCode: code]
                                     userInfo: @{NSLocalizedFailureReasonErrorKey : @"Adaptor requested to display a rewarded video before one was loaded"}];
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
    
    self.sdk.settings.muted = NO;
    
    if ( self.fullyWatched && self.reward )
    {
        [_connector adapter: self didRewardUserWithReward: self.reward];
    }
    
    [_connector adapterDidCloseRewardBasedVideoAd: self];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view
{
    [self log: @"Rewarded video clicked"];
    
    [_connector adapterDidGetAdClick: self];
    [_connector adapterWillLeaveApplication: self];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad
{
    [self log: @"Interstitial video playback began"];
    [_connector adapterDidStartPlayingRewardBasedVideoAd: self];
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad atPlaybackPercent:(NSNumber *)percentPlayed fullyWatched:(BOOL)wasFullyWatched
{
    [self log: @"Interstitial video playback ended at playback percent: %lu", percentPlayed.unsignedIntegerValue];
    
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

#pragma mark - Utility Methods

- (void)log:(NSString *)format, ...
{
    va_list valist;
    va_start(valist, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
    va_end(valist);
    
    NSLog(@"AppLovinRewardedAdapter: %@", message);
}

@end
