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
#import "GADMAdapterAppLovinQueue.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#define DEFAULT_ZONE @""

@interface GADMAdapterAppLovin () <ALAdLoadDelegate>

// Controlled Properties
@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic,   weak) id<GADMAdNetworkConnector> connector;

// Interstitial Properties
@property (nonatomic, strong, nullable) ALInterstitialAd *interstitial;

// Banner Properties
@property (nonatomic, strong, nullable) ALAdView *adView;

// Dynamic Properties - Please note: placements are left in this adapter for backwards-compatibility purposes
@property (nonatomic, copy, readonly) NSString *placement;
@property (nonatomic, copy, readonly) NSString *zoneIdentifier;

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
@dynamic placement, zoneIdentifier;

static NSMutableDictionary<NSString *, GADMAdapterAppLovinQueue<ALAd *> *> *ALInterstitialAdQueues;
static NSObject *ALInterstitialAdQueueLock;
static const NSUInteger ALInterstitialAdQueueMaxCapacity = 2;

static const CGFloat kALBannerHeightOffsetTolerance = 10.0f;
static const CGFloat kALBannerStandardHeight = 50.0f;

#pragma mark - Class Initialization

+ (void)initialize
{
    ALInterstitialAdQueues = [NSMutableDictionary dictionary];
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
    @synchronized (ALInterstitialAdQueueLock)
    {
        NSString *placement = [self placement];
        NSString *zoneIdentifier = [self zoneIdentifier];
        
        // If we already have preloaded ads, don't fire off redundant requests
        GADMAdapterAppLovinQueue *queue = ALInterstitialAdQueues[zoneIdentifier];
        if ( queue.count < ALInterstitialAdQueueMaxCapacity )
        {
            if ( zoneIdentifier.length > 0 )
            {
                [self log: @"Requesting interstitial for zone: %@", zoneIdentifier];
                [self.sdk.adService loadNextAdForZoneIdentifier: zoneIdentifier andNotify: self];
            }
            else
            {
                [self log: @"Requesting interstitial for placement: %@", placement];
                [self.sdk.adService loadNextAd: [ALAdSize sizeInterstitial] andNotify: self];
            }
        }
        else
        {
            [self log: @"Requesting interstitial for zone: %@ and placement: %@ when %lu are preloaded already", zoneIdentifier, placement, queue.count];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.connector adapterDidReceiveInterstitial: self];
            }];
        }
    }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    @synchronized (ALInterstitialAdQueueLock)
    {
        // Update mute state
        GADMAdapterAppLovinExtras *networkExtras = self.connector.networkExtras;
        self.sdk.settings.muted = networkExtras.muteAudio;
        
        NSString *placement = [self placement];
        NSString *zoneIdentifier = [self zoneIdentifier];
        
        ALAd *dequeuedAd = [ALInterstitialAdQueues[zoneIdentifier] dequeue];
        if ( dequeuedAd )
        {
            [self log: @"Showing interstitial for zone: %@ placement: %@", zoneIdentifier, placement];
            [self.interstitial showOver: [UIApplication sharedApplication].keyWindow
                              placement: placement
                              andRender: dequeuedAd];
        }
        else
        {
            [self log: @"Attempting to show interstitial before one was loaded"];
            
            // Check if we have a default zone interstitial available
            if ( zoneIdentifier.length == 0 && [self.interstitial isReadyForDisplay] )
            {
                [self.interstitial showOverPlacement: placement];
            }
            // TODO: Show ad for zone identifier if exists
            else
            {
                [self.connector adapterWillPresentInterstitial: self];
                [self.connector adapterDidDismissInterstitial: self];
            }
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

#pragma mark - Interstitial Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad
{
    [self log: @"Interstitial did load ad: %@ for zoneIdentifier: %@ and placement: %@", ad.adIdNumber, ad.zoneIdentifier, self.placement];
    
    @synchronized (ALInterstitialAdQueueLock)
    {
        GADMAdapterAppLovinQueue<ALAd *> *preloadedAds = ALInterstitialAdQueues[ad.zoneIdentifier];
        if ( !preloadedAds )
        {
            preloadedAds = [GADMAdapterAppLovinQueue queueWithCapacity: ALInterstitialAdQueueMaxCapacity];
            ALInterstitialAdQueues[ad.zoneIdentifier] = preloadedAds;
        }
        
        [preloadedAds enqueue: ad];
        
        [self.connector adapterDidReceiveInterstitial: self];
    }
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    [self log: @"Interstitial failed to load with error: %d", code];
    
    NSError *error = [NSError errorWithDomain: GADMAdapterAppLovinConstant.errorDomain
                                         code: [GADMAdapterAppLovinUtils toAdMobErrorCode: code]
                                     userInfo: @{NSLocalizedFailureReasonErrorKey : @"Adapter requested to display an interstitial before one was loaded"}];
    [self.connector adapter: self didFailAd: error];
}

#pragma mark - GAD Ad Network Protocol Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize
{
    [self log: @"Requesting banner of size %@", NSStringFromGADAdSize(adSize)];
    
    // Convert requested size to AppLovin Ad Size
    ALAdSize *appLovinAdSize = [self appLovinAdSizeFromRequestedSize: adSize];
    if ( appLovinAdSize )
    {
        NSString *zoneIdentifier = [self zoneIdentifier];
        self.adView = [[ALAdView alloc] initWithSize: appLovinAdSize zoneIdentifier: zoneIdentifier];
        
        CGSize size = CGSizeFromGADAdSize(adSize);
        self.adView.frame = CGRectMake(0, 0, size.width, size.height);
        
        GADMAdapterAppLovinBannerDelegate *delegate = [[GADMAdapterAppLovinBannerDelegate alloc] initWithParentAdapter: self];
        self.adView.adLoadDelegate = delegate;
        self.adView.adDisplayDelegate = delegate;
        self.adView.adEventDelegate = delegate;
        
        if ( zoneIdentifier.length > 0 )
        {
            [self.sdk.adService loadNextAdForZoneIdentifier: zoneIdentifier andNotify: delegate];
        }
        else
        {
            [self.sdk.adService loadNextAd: appLovinAdSize andNotify: delegate];
        }
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

#pragma mark - Logging

- (void)log:(NSString *)format, ...
{
    if ( GADMAdapterAppLovinConstant.loggingEnabled )
    {
        va_list valist;
        va_start(valist, format);
        NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
        va_end(valist);
        
        NSLog(@"AppLovinAdapter: %@", message);
    }
}

#pragma mark - Dynamic Properties

- (NSString *)placement
{
    return self.connector.credentials[GADMAdapterAppLovinConstant.placementKey] ?: @"";
}

- (NSString *)zoneIdentifier
{
    return ((GADMAdapterAppLovinExtras *) self.connector.networkExtras).zoneIdentifier ?: DEFAULT_ZONE;
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
    
    [self.parentAdapter.adView render: ad overPlacement: self.parentAdapter.placement];
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
