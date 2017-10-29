//
//  GADMAdapterAppLovin.m
//  AdMobAdapterDev
//
//  Created by Josh Gleeson on 8/15/17.
//  Copyright © 2017 AppLovin. All rights reserved.
//

#import "GADMAdapterAppLovin.h"
#import "GADMAdapterAppLovinConstants.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinExtras.h"
#import "ALGADQueue.h"

#if __has_include(<AppLovinSDK/AppLovinSDK.h>)
    #import <AppLovinSDK/AppLovinSDK.h>
#else
    #import "ALSdk.h"
    #import "ALInterstitialAd.h"
#endif

@interface GADMAdapterAppLovin () <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate>

@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, strong) ALInterstitialAd *interstitial;
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@property(nonatomic, copy) NSString *placement;

// Banner properties
@property (nonatomic, strong) ALAdView *adView;

@end

@interface AppLovinAdMobBannerDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>
@property (nonatomic, weak) GADMAdapterAppLovin *parentAdapter;
- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter;
@end

@implementation GADMAdapterAppLovin

// Failsafe for when ads are loaded but discarded
static ALGADQueue<ALAd *> *ALGADAdsQueue;

// AdMob preloads ads in bursts of 2 requests
static const NSUInteger ALGADAdsQueueMinCapacity = 2;
static bool loggingEnabled = NO;

+ (void)initialize {
  ALGADAdsQueue = [ALGADQueue queue];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
    self.sdk = [GADMAdapterAppLovinUtils sdkForCredentials:_connector.credentials];

    if (!self.sdk) {
      [self log:@"Failed to initialize SDK"];
    }
  }
  return self;
}

+ (NSString *)adapterVersion {
  return kGADMAdapterAppLovinVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

#pragma mark Interstitial Methods

- (void)getInterstitial {
  self.placement = [GADMAdapterAppLovinUtils placementFromCredentials:self.connector.credentials];

  // If we already have preloaded ads, don't fire off redundant requests
  if (ALGADAdsQueue.count < ALGADAdsQueueMinCapacity) {
    [self log:@"Requesting AppLovin interstitial for placement: %@", self.placement];
    [self.sdk.adService loadNextAd:[ALAdSize sizeInterstitial] andNotify:self];
  } else {
    [self log:@"Attempting to get another interstitial ad when we have preloaded ads already for "
              @"placement: %@",
              self.placement];

    // Simulate ad load netowrk latency
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     [self.connector adapterDidReceiveInterstitial:self];
                   });
  }
}

- (void)loadAfterSleep:(NSTimer *)timer {
  [self.sdk.adService loadNextAd:[ALAdSize sizeInterstitial] andNotify:self];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  ALAd *dequeuedAd = [ALGADAdsQueue dequeue];
  if (dequeuedAd) {
    GADMAdapterAppLovinExtras *extras = _connector.networkExtras;
    if (extras && extras.muteAudio) {
      self.sdk.settings.muted = YES;
    }

    [self log:@"Showing interstitial for placement: %@", self.placement];
    [self.interstitial showOver:[UIApplication sharedApplication].keyWindow
                      placement:self.placement
                      andRender:dequeuedAd];
  } else {
    [self log:@"Failed to show an AppLovin interstitial before one was loaded"];
    [self.connector adapterWillPresentInterstitial:self];
    [self.connector adapterDidDismissInterstitial:self];
  }
}

- (void)stopBeingDelegate {
  self.connector = nil;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  [self log:@"Interstitial did load ad: %@ for placement: %@", ad.adIdNumber, self.placement];
  [ALGADAdsQueue enqueue:ad];
  [self.connector adapterDidReceiveInterstitial:self];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [self log:@"Interstitial failed to load with error: %d", code];

  NSError *error =
      [NSError errorWithDomain:kGADMAdapterAppLovinErrorDomain
                          code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                      userInfo:@{
                        NSLocalizedFailureReasonErrorKey :
                            @"Adaptor requested to display an interstitial before one was loaded"
                      }];
  [self.connector adapter:self didFailAd:error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
  [self log:@"Interstitial displayed"];
  [self.connector adapterWillPresentInterstitial:self];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
  self.sdk.settings.muted = NO;
  [self log:@"Interstitial dismissed"];
  [_connector adapterWillDismissInterstitial:self];
  [_connector adapterDidDismissInterstitial:self];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
  [self log:@"Interstitial clicked"];

  [_connector adapterDidGetAdClick:self];
  [_connector adapterWillLeaveApplication:self];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad {
  [self log:@"Interstitial video playback began"];
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad
             atPlaybackPercent:(NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
  [self log:@"Interstitial video playback ended at playback percent: %lu",
            percentPlayed.unsignedIntegerValue];
}

- (ALInterstitialAd *)interstitial {
  if (!_interstitial) {
    _interstitial = [[ALInterstitialAd alloc] initWithSdk:self.sdk];
    _interstitial.adVideoPlaybackDelegate = self;
    _interstitial.adDisplayDelegate = self;
  }

  return _interstitial;
}

#pragma mark - Banner Implementation

- (void)getBannerWithSize:(GADAdSize)adSize
{
    [self log: @"Requesting AppLovin banner of size %@", NSStringFromGADAdSize(adSize)];
    
    // Convert requested size to AppLovin Ad Size
    ALAdSize *appLovinAdSize = [self appLovinAdSizeFromRequestedSize: adSize];
    if ( appLovinAdSize )
    {
        CGSize size = CGSizeFromGADAdSize(adSize);
        
        self.adView = [[ALAdView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, size.width, size.height)
                                                 size: appLovinAdSize
                                                  sdk: self.sdk];
        
        AppLovinAdMobBannerDelegate *delegate = [[AppLovinAdMobBannerDelegate alloc] initWithParentAdapter: self];
        self.adView.adLoadDelegate = delegate;
        self.adView.adDisplayDelegate = delegate;
        
        if ( [self.adView respondsToSelector: @selector(setAdEventDelegate:)] )
        {
            self.adView.adEventDelegate = delegate;
        }
        
        [self.sdk.adService loadNextAd: appLovinAdSize andNotify: delegate];
    }
    else
    {
        [self log: @"Failed to create an AppLovin Banner with invalid size"];
        
        NSError *error = [NSError errorWithDomain: kGADMAdapterAppLovinErrorDomain
                                             code: kGADErrorMediationInvalidAdSize
                                         userInfo: nil];
        
        [self.connector adapter: self didFailAd: error];
    }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType
{
    return YES;
}

#pragma mark - Banner Utility Methods

- (ALAdSize *)appLovinAdSizeFromRequestedSize:(GADAdSize)size
{
    if ( GADAdSizeEqualToSize(kGADAdSizeBanner, size ) || GADAdSizeEqualToSize(kGADAdSizeLargeBanner, size ) )
    {
        return [ALAdSize sizeBanner];
    }
    else if ( GADAdSizeEqualToSize(kGADAdSizeMediumRectangle, size) )
    {
        return [ALAdSize sizeMRec];
    }
    else if ( GADAdSizeEqualToSize(kGADAdSizeLeaderboard, size) )
    {
        return [ALAdSize sizeLeader];
    }
    // This is not a concrete size, so attempt to check for fluid size
    else
    {
        CGSize frameSize = size.size;
        if ( CGRectGetWidth([UIScreen mainScreen].bounds) == frameSize.width )
        {
            CGFloat frameHeight = frameSize.height;
            if ( frameHeight == CGSizeFromGADAdSize(kGADAdSizeBanner).height || frameHeight == CGSizeFromGADAdSize(kGADAdSizeLargeBanner).height )
            {
                return [ALAdSize sizeBanner];
            }
            else if ( frameHeight == CGSizeFromGADAdSize(kGADAdSizeMediumRectangle).height )
            {
                return [ALAdSize sizeMRec];
            }
            else if ( frameHeight == CGSizeFromGADAdSize(kGADAdSizeLeaderboard).height )
            {
                return [ALAdSize sizeLeader];
            }
        }
    }
    
    [self log: @"Unable to retrieve AppLovin size from GADAdSize: %@", NSStringFromGADAdSize(size)];
    
    return nil;
}

#pragma mark - Utility Methods

- (void)log:(NSString *)format, ...
{
    if ( loggingEnabled )
    {
        va_list valist;
        va_start(valist, format);
        NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
        va_end(valist);
        
        NSLog(@"AppLovinAdapter: %@", message);
    }
}

@end

@implementation AppLovinAdMobBannerDelegate

#pragma mark - Initialization

- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
    }
    return self;
}

#pragma mark - AppLovin Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    [self.parentAdapter log: @"Banner did load ad: %@", ad.adIdNumber];
    
    NSString *placement = [GADMAdapterAppLovinUtils placementFromCredentials: self.parentAdapter.connector.credentials];
    [self.parentAdapter.adView render: ad overPlacement: placement];
    
    [self.parentAdapter.connector adapter: self.parentAdapter didReceiveAdView: self.parentAdapter.adView];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    [self.parentAdapter log: @"Banner failed to load with error: %d", code];
    
    NSError *error = [NSError errorWithDomain: kGADMAdapterAppLovinErrorDomain
                                         code: [GADMAdapterAppLovinUtils toAdMobErrorCode: code]
                                     userInfo: nil];
    [self.parentAdapter.connector adapter: self.parentAdapter didFailAd: error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view
{
    [self.parentAdapter log: @"Banner displayed"];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view
{
    [self.parentAdapter log: @"Banner dismissed"];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view
{
    [self.parentAdapter log: @"Banner clicked"];
    
    [self.parentAdapter.connector adapterDidGetAdClick: self.parentAdapter];
    [self.parentAdapter.connector adapterWillLeaveApplication: self.parentAdapter];
}

#pragma mark - Ad View Event Delegate

- (void)ad:(ALAd *)ad didPresentFullscreenForAdView:(ALAdView *)adView
{
    [self.parentAdapter log: @"Banner presented fullscreen"];
    [self.parentAdapter.connector adapterWillPresentFullScreenModal: self.parentAdapter];
}

- (void)ad:(ALAd *)ad willDismissFullscreenForAdView:(ALAdView *)adView
{
    [self.parentAdapter log: @"Banner will dismiss fullscreen"];
    [self.parentAdapter.connector adapterWillDismissFullScreenModal: self.parentAdapter];
}

- (void)ad:(ALAd *)ad didDismissFullscreenForAdView:(ALAdView *)adView
{
    [self.parentAdapter log: @"Banner did dismiss fullscreen"];
    [self.parentAdapter.connector adapterDidDismissFullScreenModal: self.parentAdapter];
}

- (void)ad:(ALAd *)ad willLeaveApplicationForAdView:(ALAdView *)adView
{
    // We will fire adapterWillLeaveApplication: in the ad:wasClickedIn: callback
    [self.parentAdapter log: @"Banner left application"];
}

- (void)ad:(ALAd *)ad didFailToDisplayInAdView:(ALAdView *)adView withError:(ALAdViewDisplayErrorCode)code
{
    [self.parentAdapter log: @"Banner failed to display: %ld", code];
}

@end
