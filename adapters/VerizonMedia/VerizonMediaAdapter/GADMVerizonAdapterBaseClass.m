//
//  GADMVerizonAdapterBaseClass.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMVerizonAdapterBaseClass.h"
#import "GADMVerizonMediaConstants.h"
#import "GADMVerizonNativeAd.h"
#import "GADMVerizonRewardedVideo.h"

@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;
@protocol GADMRewardBasedVideoAdNetworkAdapter;

#define MM_SMARTBANNER_PHONE CGSizeMake(320, 50)
#define MM_SMARTBANNER_TABLET CGSizeMake(728, 90)
#define MM_SMARTBANNER_MED_CUTOFF 450
#define MM_SMARTBANNER_MAX_CUTOFF 740

NSString * const GADMVASAdapterBaseClassVideoCompleteEventId = @"onVideoComplete";

@interface GADMVerizonAdapterBaseClass ()

@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler rewardedCompletionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> rewardedDelegate;

@property CGRect inlineAdFrame;
@property BOOL isVideoCompletionEventCalled;

@end

@implementation GADMVerizonAdapterBaseClass

#pragma mark - Logger

+ (VASLogger *)logger
{
    static VASLogger *_logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logger = [VASLogger loggerForClass:[GADMVerizonAdapterBaseClass class]];
    });
    return _logger;
}

#pragma mark - GADMAdNetworkAdapter

+ (Class<GADAdNetworkExtras>)networkExtrasClass
{
    return nil;
}

+ (NSString *)adapterVersion
{
    return kVASAdapterVersion;
}

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)gadConnector
{
    if (self = [super init]) {
        _connector = gadConnector;
    }
    
    return self;
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:(id<GADMRewardBasedVideoAdNetworkConnector>)connector {

    if (self = [super init]) {
        _connector = connector;
    }
    return self;
}

- (void)dealloc
{
    [self stopBeingDelegate];
}

- (void)getInterstitial
{
    if (![self prepareAdapterForAdRequest]) {
        return;
    }
    
    self.interstitialAd = nil;
    self.interstitialAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:self.placementID vasAds:self.vasAds delegate:self];
    [self.interstitialAdFactory load:self];
}

- (void)getBannerWithSize:(GADAdSize)adSize
{
    if (![self prepareAdapterForAdRequest]) {
        return;
    }
    
    __strong typeof(self.gadConnector) connector = self.gadConnector;
    
    // Create the InlineAd object
    CGRect adFrame = [self makeBannerRect:adSize];
    
    // Check for banner smartness failure--
    if ( adFrame.size.width < 0 ) {
        [connector adapter:self didFailAd:[NSError errorWithDomain:kGADErrorDomain code:kGADErrorInvalidRequest userInfo:nil]];
        return;
    }
    
    self.inlineAdFrame = adFrame;
    
    VASInlineAdSize *size = [[VASInlineAdSize alloc] initWithWidth:self.inlineAdFrame.size.width height:self.inlineAdFrame.size.height];
    self.inlineAdFactory = [[VASInlineAdFactory alloc] initWithPlacementId:self.placementID adSizes:@[size] vasAds:[VASAds sharedInstance] delegate:self];
    
    [self.inlineAd removeFromSuperview];
    self.inlineAd = nil;
    
    [self.inlineAdFactory load:self];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootVC
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showFromViewController:rootVC];
    });
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType
{
    return YES;
}

- (void)getNativeAdWithAdTypes:(__unused NSArray<GADAdLoaderAdType> *)adTypes
                       options:(__unused NSArray<GADAdLoaderOptions *> *)options
{
    if (![self prepareAdapterForAdRequest]) {
        return;
    }
    self.nativeAdFactory = [[VASNativeAdFactory alloc] initWithPlacementId:self.placementID
                                                                   adTypes:@[@"inline"]
                                                                    vasAds:[VASAds sharedInstance]
                                                                  delegate:self];
    [self.nativeAdFactory load:self];
}

#pragma mark - GADMediationAdapter

+ (GADVersionNumber)version
{
    NSArray *versionComponents = [kVASAdapterVersion componentsSeparatedByString:@"."];
    
    GADVersionNumber version = {0};
    if (versionComponents.count == 3) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}

+ (GADVersionNumber)adSDKVersion
{
    NSString *versionString = [[[VASAds sharedInstance] configuration] stringForDomain:@"com.verizon.ads"
                                                                                    key:@"editionVersion"
                                                                            withDefault:nil];
    if (versionString.length == 0) {
        versionString = [VASAds sdkInfo].version;
    }

    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    
    GADVersionNumber version = {0};
    if (versionComponents.count == 3) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler
{
    if (!self.vasAds) {
        [self initializeVASSDKWithAdConfiguration:adConfiguration];
    }
    
    if (!self.placementID || !self.vasAds.isInitialized) {
        NSError *error = [NSError errorWithDomain:kGADErrorDomain
                                             code:kGADErrorMediationAdapterError
                                         userInfo:@{NSLocalizedDescriptionKey : @"Verizon adapter not properly intialized."}];
        completionHandler(nil, error);
    }
    
    self.rewardedCompletionHandler = completionHandler;
    
    self.interstitialAd = nil;
    self.interstitialAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:self.placementID
                                                                                vasAds:self.vasAds
                                                                              delegate:self];
    
    [self.interstitialAdFactory load:self];
}

- (void)initializeVASSDKWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
{
    // Implemented by subclass
}

#pragma mark - VASInterstitialAdFactoryDelegate

-(void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory didLoadInterstitialAd:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = interstitialAd;
        [self.gadConnector adapterDidReceiveInterstitial:self];
        
        if (self.rewardedCompletionHandler) {
            self.rewardedDelegate = self.rewardedCompletionHandler([[GADMVerizonRewardedVideo alloc] initWithInterstitialAd:interstitialAd], nil);
            self.rewardedCompletionHandler = nil;
        } else {
            [self.rewardConnector adapterDidReceiveRewardBasedVideoAd:self];
        }
    });
}

- (void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory didFailWithError:(VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapter:self didFailAd:errorInfo];
        
        if (self.rewardedCompletionHandler) {
            self.rewardedCompletionHandler(nil, errorInfo);
            self.rewardedCompletionHandler = nil;
        } else {
            [self.rewardConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:errorInfo];
        }
    });
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory cacheLoadedNumRequested:(NSInteger)numRequested numReceived:(NSInteger)numReceived
{
    // Unused
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory cacheUpdatedWithCacheSize:(NSInteger)cacheSize
{
    // Unused
}

- (void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory cacheLoadedNumRequested:(NSInteger)numRequested
{
    // unused
}

#pragma mark - VASInterstitialAdDelegate

- (void)interstitialAdDidShow:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterWillPresentInterstitial:self];
        [self.rewardConnector adapterDidOpenRewardBasedVideoAd:self];
        
        [self.rewardedDelegate willPresentFullScreenView];
    });
}

- (void)interstitialAdDidFail:(VASInterstitialAd *)interstitialAd withError:(VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapter:self didFailAd:errorInfo];
        [self.rewardConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:errorInfo];
        
        [self.rewardedDelegate didFailToPresentWithError:errorInfo];
    });
}

- (void)interstitialAdDidClose:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterDidDismissInterstitial:self];
        [self.rewardConnector adapterDidCloseRewardBasedVideoAd:self];
        
        [self.rewardedDelegate willDismissFullScreenView];
        [self.rewardedDelegate didDismissFullScreenView];
    });
}

- (void)interstitialAdDidLeaveApplication:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterWillLeaveApplication:self];
        [self.rewardConnector adapterWillLeaveApplication:self];
    });
}

- (void)interstitialAdClicked:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterDidGetAdClick:self];
        [self.rewardConnector adapterDidGetAdClick:self];
        
        [self.rewardedDelegate reportClick];
    });
}

- (void)interstitialAdEvent:(VASInterstitialAd *)interstitialAd source:(NSString *)source eventId:(NSString *)eventId arguments:(NSDictionary<NSString *, id> *)arguments
{
    if ([eventId isEqualToString:GADMVASAdapterBaseClassVideoCompleteEventId] && !self.isVideoCompletionEventCalled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                             rewardAmount:[[NSDecimalNumber alloc] initWithInteger:1]];
            [self.rewardConnector adapter:self didRewardUserWithReward:reward];
            
            [self.rewardedDelegate didRewardUserWithReward:reward];
            
            self.isVideoCompletionEventCalled = YES;
        });
    }
}

#pragma mark - VASInlineAdFactoryDelegate

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory didFailWithError:(nonnull VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapter:self didFailAd:errorInfo];
    });
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory didLoadInlineAd:(nonnull VASInlineAdView *)inlineAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.inlineAd = inlineAd;
        self.inlineAd.frame = self.inlineAdFrame;
        [self.gadConnector adapter:self didReceiveAdView:self.inlineAd];
    });
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory cacheLoadedNumRequested:(NSInteger)numRequested numReceived:(NSInteger)numReceived
{
    // Unused
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory cacheUpdatedWithCacheSize:(NSInteger)cacheSize
{
    // Unused
}

#pragma mark - VASInlineAdViewDelegate

- (void)inlineAdDidFail:(VASInlineAdView *)inlineAd withError:(VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapter:self didFailAd:errorInfo];
    });
}

- (void)inlineAdDidExpand:(VASInlineAdView *)inlineAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterWillPresentFullScreenModal:self];
    });
}

- (void)inlineAdDidCollapse:(VASInlineAdView *)inlineAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterDidDismissFullScreenModal:self];
    });
}

- (void)inlineAdClicked:(VASInlineAdView *)inlineAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterDidGetAdClick:self];
    });
}

- (void)inlineAdDidLeaveApplication:(VASInlineAdView *)inlineAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterWillLeaveApplication:self];
    });
}

- (nullable UIViewController *)adPresentingViewController
{
    return [self.gadConnector viewControllerForPresentingModalView];
}

- (void)inlineAdDidRefresh:(nonnull VASInlineAdView *)inlineAd
{
    // Unused
}

- (void)inlineAdDidResize:(nonnull VASInlineAdView *)inlineAd
{
    // Unused
}

- (void)inlineAdEvent:(nonnull VASInlineAdView *)inlineAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nonnull NSDictionary<NSString *,id> *)arguments
{
    // Unused
}

#pragma mark - VASNativeAd Delegate

- (void)nativeAdDidClose:(nonnull VASNativeAd *)nativeAd {
    // Admob adapter has no similar event, ignore it.
}

- (void)nativeAdDidFail:(nonnull VASNativeAd *)nativeAd withError:(nonnull VASErrorInfo *)errorInfo {
    [GADMVerizonAdapterBaseClass.logger error:@"Native Ad did fail with error: %@", [errorInfo localizedDescription]];
}

- (void)nativeAdDidLeaveApplication:(nonnull VASNativeAd *)nativeAd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterWillLeaveApplication:self];
    });
}

#pragma mark - VASNativeAdFactory Delegate

- (void)nativeAdEvent:(nonnull VASNativeAd *)nativeAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nonnull NSDictionary<NSString *,id> *)arguments {}

- (nullable UIViewController *)nativeAdPresentingViewController { 
    return [self.gadConnector  viewControllerForPresentingModalView];
}

- (void)nativeAdClicked:(nonnull VASNativeAd *)nativeAd withComponent:(nonnull id<VASComponent>)component {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterDidGetAdClick:self];
    });
}


- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory cacheLoadedNumRequested:(NSUInteger)numRequested numReceived:(NSUInteger)numReceived {}

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory cacheUpdatedWithCacheSize:(NSUInteger)cacheSize {}

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory didFailWithError:(nullable VASErrorInfo *)errorInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector  adapter:self didFailAd:errorInfo];
    });
}

- (void)nativeAdFactory:(nonnull VASNativeAdFactory *)adFactory didLoadNativeAd:(nonnull VASNativeAd *)nativeAd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector  adapter:self
     didReceiveMediatedNativeAd:[[GADMVerizonNativeAd alloc] initWithNativeAd:nativeAd]];
    });
}

#pragma mark - GADMRewardBasedVideoAdNetworkAdapter

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
    [self.interstitialAd showFromViewController:viewController];
}

- (void)requestRewardBasedVideoAd {
    self.isVideoCompletionEventCalled = NO;
    [self.interstitialAdFactory abortLoad];
    [self.interstitialAdFactory load:self];
}

- (void)setUp {
    if (![self prepareAdapterForAdRequest]) {
        return;
    }
    self.interstitialAd = nil;
    self.interstitialAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:self.placementID vasAds:self.vasAds delegate:self];
    [self.rewardConnector adapterDidSetUpRewardBasedVideoAd:self];
}

#pragma mark - common

- (BOOL)prepareAdapterForAdRequest {
    if (!self.placementID || ! self.vasAds.isInitialized) {
        NSError *error = [NSError errorWithDomain:kGADErrorDomain
                                             code:kGADErrorMediationAdapterError
                                         userInfo:@{NSLocalizedDescriptionKey : @"Verizon adapter not properly intialized."}];
        [self.gadConnector adapter:self didFailAd:error];
        [self.rewardConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
        return NO;
    }
    
    [self setRequestInfoFromConnector:self.connector];
    
    return YES;
}

- (void)stopBeingDelegate
{
    if (self.inlineAd) {
        if ([self.inlineAd respondsToSelector:@selector(destroy)]) {
            [self.inlineAd performSelector:@selector(destroy)];
        } else {
            NSLog(@"GADMAdapterVerizon: The adapter is intended to work with Verizon Ads SDK version 1.0.4 or higher.  Please update the Verizon Ads SDK.");
        }
    }
    
    if (self.interstitialAd) {
        if ([self.interstitialAd respondsToSelector:@selector(destroy)]) {
            [self.interstitialAd performSelector:@selector(destroy)];
        } else {
            NSLog(@"GADMAdapterVerizon: The adapter is intended to work with Verizon Ads SDK version 1.0.4 or higher.  Please update the Verizon Ads SDK.");
        }
    }
    
    self.inlineAdFactory.delegate = nil;
    self.inlineAd.delegate = nil;
    self.interstitialAdFactory.delegate = nil;
    self.interstitialAd.delegate = nil;
    self.inlineAd = nil;
    self.interstitialAd = nil;
}

#pragma mark - private

- (void)setRequestInfoFromConnector:(id<GADMediationAdRequest>)connector
{
    //User Settings
    [self setUserSettingsFromConnector:connector];
    
    //COPPA
    [self setCoppaFromConnector:connector];
    
    // Location
    if (connector.userHasLocation) {
        self.vasAds.locationEnabled = YES;
    }
}

- (void)setUserSettingsFromConnector:(id<GADMediationAdRequest>)connector
{
    VASRequestMetadataBuilder *builder = [[VASRequestMetadataBuilder alloc] init];
    
    // Mediator
    builder.appMediator = [NSString stringWithFormat:@"AdMobVAS-%@",  [GADMVerizonAdapterBaseClass adapterVersion]];
    
    // Keywords
    if ([connector userKeywords] != nil && [[connector userKeywords] count] > 0) {
        builder.userKeywords = [connector userKeywords];;
    }
    
    self.vasAds.requestMetadata = [builder build];
}

- (void)setCoppaFromConnector:(id<GADMediationAdRequest>)connector
{
    self.vasAds.COPPA = [connector childDirectedTreatment];
}

- (CGRect)makeBannerRect:(GADAdSize)adSize
{
    // Consideration for smart banners ( http://bit.ly/1wAWn0r )
    CGSize windowSize = [[UIApplication sharedApplication] keyWindow].bounds.size;
    
    if ( GADAdSizeEqualToSize(kGADAdSizeSmartBannerPortrait, adSize) ||
        GADAdSizeEqualToSize(kGADAdSizeSmartBannerLandscape, adSize) ) {
        int offsetX = (int)(windowSize.width / 2);
        
        if ( windowSize.height < MM_SMARTBANNER_MED_CUTOFF ) {
            // MYDAS will attempt to return a 320x50, even when hsht < 320 / hswd < 50
            return CGRectMake(0,0,-1,-1);
        } else if ( windowSize.height >= MM_SMARTBANNER_MED_CUTOFF &&
                   windowSize.height <= MM_SMARTBANNER_MAX_CUTOFF) {
            return CGRectMake(offsetX - (MM_SMARTBANNER_PHONE.width / 2), 0,
                              MM_SMARTBANNER_PHONE.width, MM_SMARTBANNER_PHONE.height);
        } else if ( windowSize.height > MM_SMARTBANNER_MAX_CUTOFF ) {
            return CGRectMake(offsetX - (MM_SMARTBANNER_TABLET.width / 2), 0,
                              MM_SMARTBANNER_TABLET.width, MM_SMARTBANNER_TABLET.height);
        }
    }
    
    return CGRectMake(0, 0, adSize.size.width, adSize.size.height);
}

- (id<GADMAdNetworkConnector>)gadConnector
{
    return [self.connector conformsToProtocol:@protocol(GADMAdNetworkConnector)]
    ? (id<GADMAdNetworkConnector>)self.connector
    : nil;
}

- (id<GADMRewardBasedVideoAdNetworkConnector>)rewardConnector
{
    return [self.connector conformsToProtocol:@protocol(GADMRewardBasedVideoAdNetworkConnector)]
    ? (id<GADMRewardBasedVideoAdNetworkConnector>)self.connector
    : nil;
}

@end
