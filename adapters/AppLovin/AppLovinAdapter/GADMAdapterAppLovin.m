//
//  GADMAdapterAppLovin.m
//
//
//  Created by Thomas So on 1/10/18.
//
//

#import <AppLovinSDK/AppLovinSDK.h>
#import "GADMAdapterAppLovin.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinExtras.h"
#import "ALGADQueue.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface GADMAdapterAppLovin () <ALAdLoadDelegate>

// Controlled Properties
@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic,   weak) id<GADMAdNetworkConnector> connector;
@property (nonatomic,   copy, nullable) NSString *placement;

// Interstitial Properties
@property (nonatomic, strong, nullable) ALInterstitialAd *interstitial;

// Banner Properties
@property (nonatomic, strong, nullable) ALAdView *adView;

@end

/**
 * Interstitial Delegate
 */
@interface GADMAdapterAppLovinInterstitialDelegate : NSObject<ALAdDisplayDelegate, ALAdVideoPlaybackDelegate, ALAdViewEventDelegate>
@property (nonatomic, weak) GADMAdapterAppLovin *parentAdapter;
- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter;
@end

/**
 * Banner Delegate
 */
@interface GADMAdapterAppLovinBannerDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>
@property (nonatomic, weak) GADMAdapterAppLovin *parentAdapter;
- (instancetype)initWithParentAdapter:(GADMAdapterAppLovin *)parentAdapter;
@end

@implementation GADMAdapterAppLovin

static ALGADQueue<ALAd *> *ALInterstitialAdQueue;
static NSObject *ALInterstitialAdQueueLock;
static const NSUInteger ALInterstitialAdQueueMinCapacity = 2; // AdMob preloads ads in bursts of 2 requests

static const CGFloat kALBannerHeightOffsetTolerance = 10.0f;
static const CGFloat kALBannerStandardHeight = 50.0f;

static bool kALLoggingEnabled = NO;

#pragma mark - Class Initialization

+ (void)initialize
{
    ALInterstitialAdQueue = [ALGADQueue queue];
    ALInterstitialAdQueueLock = [[NSObject alloc] init];
}

#pragma mark - GAD Ad Network Protocol Methods

+ (NSString *)adapterVersion
{
    return GADMAdapterAppLovinConstant.adapterVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass
{
    return [GADMAdapterAppLovinExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
{
    self = [super init];
    if ( self )
    {
        self.connector = connector;
        self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials: connector.credentials];
        
        if ( !self.sdk )
        {
            [self log: @"Failed to initialize SDK"];
        }
    }
    return self;
}

- (void)stopBeingDelegate
{
    self.connector = nil;
    
    self.interstitial.adDisplayDelegate = nil;
    self.interstitial.adVideoPlaybackDelegate = nil;
    
    self.adView.adLoadDelegate = nil;
    self.adView.adDisplayDelegate = nil;
    self.adView.adEventDelegate = nil;
}

#pragma mark - GAD Ad Network Protocol Interstitial Methods

- (void)getInterstitial
{
    self.placement = self.connector.credentials[GADMAdapterAppLovinConstant.placementKey];
    
    @synchronized ( ALInterstitialAdQueueLock )
    {
        // If we already have preloaded ads, don't fire off redundant requests
        if ( ALInterstitialAdQueue.count < ALInterstitialAdQueueMinCapacity )
        {
            [self log: @"Requesting interstitial for placement: %@", self.placement];
            [self.sdk.adService loadNextAd: [ALAdSize sizeInterstitial] andNotify: self];
        }
        else
        {
            [self log: @"Requesting interstitial for placement: %@ when %lu are preloaded already", self.placement, ALInterstitialAdQueue.count];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.connector adapterDidReceiveInterstitial: self];
            }];
        }
    }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    ALAd *dequeuedAd;
    
    @synchronized ( ALInterstitialAdQueueLock )
    {
        dequeuedAd = [ALInterstitialAdQueue dequeue];
    }
    
    if ( dequeuedAd )
    {
        // If pub explicitly requested to mute audio, mute it
        GADMAdapterAppLovinExtras *networkExtras = self.connector.networkExtras;
        if ( networkExtras.muteAudio ) self.sdk.settings.muted = YES;
        
        [self log: @"Showing interstitial for placement: %@", self.placement];
        [self.interstitial showOver: [UIApplication sharedApplication].keyWindow
                          placement: self.placement
                          andRender: dequeuedAd];
    }
    else
    {
        [self log: @"Attempting to show interstitial before one was loaded"];
        
        if ( [self.interstitial isReadyForDisplay] )
        {
            [self log: @"Showing preloaded interstitial for placement: %@", self.placement];
            [self.interstitial showOverPlacement: self.placement];
        }
        else
        {
            [self.connector adapterWillPresentInterstitial: self];
            [self.connector adapterDidDismissInterstitial: self];
        }
    }
}

- (ALInterstitialAd *)interstitial
{
    if ( !_interstitial )
    {
        _interstitial = [[ALInterstitialAd alloc] initWithSdk: self.sdk];
        
        GADMAdapterAppLovinInterstitialDelegate *delegate = [[GADMAdapterAppLovinInterstitialDelegate alloc] initWithParentAdapter: self];
        _interstitial.adDisplayDelegate = delegate;
        _interstitial.adVideoPlaybackDelegate = delegate;
    }
    
    return _interstitial;
}

#pragma mark - GAD Ad Network Protocol Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize
{
    [self log: @"Requesting banner of size %@", NSStringFromGADAdSize(adSize)];
    
    // Convert requested size to AppLovin Ad Size
    ALAdSize *appLovinAdSize = [self appLovinAdSizeFromRequestedSize: adSize];
    if ( appLovinAdSize )
    {
        CGSize size = CGSizeFromGADAdSize(adSize);
        
        self.adView = [[ALAdView alloc] initWithFrame: CGRectMake(0, 0, size.width, size.height)
                                                 size: appLovinAdSize
                                                  sdk: self.sdk];
        
        GADMAdapterAppLovinBannerDelegate *delegate = [[GADMAdapterAppLovinBannerDelegate alloc] initWithParentAdapter: self];
        self.adView.adLoadDelegate = delegate;
        self.adView.adDisplayDelegate = delegate;
        self.adView.adEventDelegate = delegate;
        
        [self.sdk.adService loadNextAd: appLovinAdSize andNotify: delegate];
    }
    else
    {
        [self log: @"Failed to request banner with unsupported size"];
        
        NSError *error = [NSError errorWithDomain: GADMAdapterAppLovinConstant.errorDomain
                                             code: kGADErrorMediationInvalidAdSize
                                         userInfo: @{NSLocalizedFailureReasonErrorKey : @"Adapter requested to display a banner ad of unsupported size"}];
        [self.connector adapter: self didFailAd: error];
    }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType
{
    return YES;
}

- (nullable ALAdSize *)appLovinAdSizeFromRequestedSize:(GADAdSize)size
{
    if ( GADAdSizeEqualToSize(kGADAdSizeBanner, size) || GADAdSizeEqualToSize(kGADAdSizeLargeBanner, size) )
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
    // This is not a one of AdMob's predefined size
    else
    {
        CGSize frameSize = size.size;
        
        // Attempt to check for fluid size
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
        
        // Assume fluid width, and check for height with offset tolerance
        CGFloat offset = ABS(kALBannerStandardHeight - frameSize.height);
        if ( offset <= kALBannerHeightOffsetTolerance )
        {
            return [ALAdSize sizeBanner];
        }
    }
    
    [self log: @"Unable to retrieve AppLovin size from GADAdSize: %@", NSStringFromGADAdSize(size)];
    
    return nil;
}

#pragma mark - Interstitial Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    [self log: @"Interstitial did load ad: %@ for placement: %@", ad.adIdNumber, self.placement];
    
    @synchronized (ALInterstitialAdQueueLock)
    {
        [ALInterstitialAdQueue enqueue: ad];
    }
    
    [self.connector adapterDidReceiveInterstitial: self];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    [self log: @"Interstitial failed to load with error: %d", code];
    
    NSError *error = [NSError errorWithDomain: GADMAdapterAppLovinConstant.errorDomain
                                         code: [GADMAdapterAppLovinUtils toAdMobErrorCode: code]
                                     userInfo: @{NSLocalizedFailureReasonErrorKey : @"Adapter requested to display an interstitial before one was loaded"}];
    [self.connector adapter: self didFailAd: error];
}

#pragma mark - Utility Methods

- (void)log:(NSString *)format, ...
{
    if ( kALLoggingEnabled )
    {
        va_list valist;
        va_start(valist, format);
        NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
        va_end(valist);
        
        NSLog(@"AppLovinAdapter: %@", message);
    }
}

@end

@implementation GADMAdapterAppLovinInterstitialDelegate

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

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view
{
    [self.parentAdapter log: @"Interstitial displayed"];
    [self.parentAdapter.connector adapterWillPresentInterstitial: self.parentAdapter];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view
{
    [self.parentAdapter log: @"Interstitial dismissed"];
    [self.parentAdapter.connector adapterWillDismissInterstitial: self.parentAdapter];
    [self.parentAdapter.connector adapterDidDismissInterstitial: self.parentAdapter];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view
{
    [self.parentAdapter log: @"Interstitial clicked"];
    [self.parentAdapter.connector adapterDidGetAdClick: self.parentAdapter];
    [self.parentAdapter.connector adapterWillLeaveApplication: self.parentAdapter];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad
{
    [self.parentAdapter log: @"Interstitial video playback began"];
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad atPlaybackPercent:(NSNumber *)percentPlayed fullyWatched:(BOOL)wasFullyWatched
{
    [self.parentAdapter log: @"Interstitial video playback ended at playback percent: %lu%%", percentPlayed.unsignedIntegerValue];
}

@end

@implementation GADMAdapterAppLovinBannerDelegate

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

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    [self.parentAdapter log: @"Banner did load ad: %@", ad.adIdNumber];
    
    NSString *placement = self.parentAdapter.connector.credentials[GADMAdapterAppLovinConstant.placementKey];
    [self.parentAdapter.adView render: ad overPlacement: placement];
    
    [self.parentAdapter.connector adapter: self.parentAdapter didReceiveAdView: self.parentAdapter.adView];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    [self.parentAdapter log: @"Banner failed to load with error: %d", code];
    
    NSError *error = [NSError errorWithDomain: GADMAdapterAppLovinConstant.placementKey
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
    [self.parentAdapter log: @"Banner left application"];
    [self.parentAdapter.connector adapterWillLeaveApplication: self.parentAdapter];
}

- (void)ad:(ALAd *)ad didFailToDisplayInAdView:(ALAdView *)adView withError:(ALAdViewDisplayErrorCode)code
{
    [self.parentAdapter log: @"Banner failed to display: %ld", code];
}

@end

#pragma clang diagnostic pop
