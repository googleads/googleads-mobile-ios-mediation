//
//  GADMAdapterBaseClass.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMVASAdapterBaseClass.h"

@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;
@protocol GADMRewardBasedVideoAdNetworkAdapter;

#define MM_SMARTBANNER_PHONE CGSizeMake(320, 50)
#define MM_SMARTBANNER_TABLET CGSizeMake(728, 90)
#define MM_SMARTBANNER_MED_CUTOFF 450
#define MM_SMARTBANNER_MAX_CUTOFF 740

static NSString * const kVASAdapterVersion = @"1.0.2.0";

@interface GADMVASAdapterBaseClass ()

@property CGRect inlineAdFrame;

@end

@implementation GADMVASAdapterBaseClass

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

- (void)dealloc
{
    [self stopBeingDelegate];
}

- (void)getInterstitial
{
    __strong typeof(self.connector) connector = self.connector;
    
    if (!self.placementID || ![self.vasAds isInitialized]) {
        [connector adapter:self didFailAd:[NSError errorWithDomain:kGADErrorDomain
                                                              code:kGADErrorMediationAdapterError
                                                          userInfo:@{NSLocalizedDescriptionKey : @"Verizon Ads SDK not properly initialized"}]];
        return;
    }
    
    [self setRequestInfoFromConnector:connector];
    self.interstitialAd = nil;
    self.interstitialAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:self.placementID vasAds:self.vasAds delegate:self];
    [self.interstitialAdFactory load:self];
}

- (void)getBannerWithSize:(GADAdSize)adSize
{
    __strong typeof(self.connector) connector = self.connector;
    
    if (!self.placementID || ! self.vasAds.isInitialized) {
        [connector adapter:self didFailAd:[NSError errorWithDomain:kGADErrorDomain
                                                              code:kGADErrorMediationAdapterError
                                                          userInfo:@{NSLocalizedDescriptionKey : @"Verizon adapter not properly intialized."}]];
        return;
    }
    
    [self setRequestInfoFromConnector:connector];
    
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
    [self.interstitialAd showFromViewController:rootVC];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType
{
    return YES;
}


#pragma mark - VASInterstitialAdFactoryDelegate

-(void)adFactory:(VASInterstitialAdFactory *)adFactory didLoadInterstitialAd:(VASInterstitialAd *)interstitialAd
{
    self.interstitialAd = interstitialAd;
    __strong typeof(self.connector) connector = self.connector;
    
    if ([connector respondsToSelector:@selector(adapterDidReceiveInterstitial:)]) {
        [connector adapterDidReceiveInterstitial:self];
    }
}

#pragma mark - VASInterstitialAdDelegate

-(void)adDidShow:(VASInterstitialAd *)interstitialAd
{
    __strong typeof(self.connector) connector = self.connector;
    if([connector respondsToSelector:@selector(adapterWillPresentInterstitial:)]) {
        [connector adapterWillPresentInterstitial:self];
    }
}

-(void)adDidClose:(VASInterstitialAd *)interstitialAd
{
    __strong typeof(self.connector) connector = self.connector;
    if ([connector respondsToSelector:@selector(adapterDidDismissInterstitial:)]) {
        [connector adapterDidDismissInterstitial:self];
    }
}

#pragma mark - VASInlineAdFactoryDelegate

- (void)adFactory:(nonnull VASInlineAdFactory *)adFactory didFailWithError:(nonnull VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.connector adapter:self didFailAd:errorInfo];
    });
}

- (void)adFactory:(nonnull VASInlineAdFactory *)adFactory didLoadInlineAd:(nonnull VASInlineAdView *)inlineAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        self.inlineAd = inlineAd;
        self.inlineAd.frame = self.inlineAdFrame;
        [self.connector adapter:self didReceiveAdView:self.inlineAd];
    });
}

// Unused required delegate methods
- (void)adFactory:(nonnull VASInlineAdFactory *)adFactory cacheLoadedNumRequested:(NSInteger)numRequested numReceived:(NSInteger)numReceived {
}

- (void)adFactory:(nonnull VASInlineAdFactory *)adFactory cacheUpdatedWithCacheSize:(NSInteger)cacheSize {
}


#pragma mark - VASInlineAdViewDelegate

- (void)adDidFail:(VASInlineAdView *)inlineAd withError:(VASErrorInfo *)errorInfo
{
    [self.connector adapter:self didFailAd:errorInfo];
}

- (void)adDidExpand:(VASInlineAdView *)inlineAd
{
    [self.connector adapterWillPresentFullScreenModal:self];
}

- (void)adDidCollapse:(VASInlineAdView *)inlineAd
{
    [self.connector adapterDidDismissFullScreenModal:self];
}

- (void)adClicked:(VASInlineAdView *)inlineAd
{
    [self.connector adapterDidGetAdClick:self];
}

- (void)adDidLeaveApplication:(VASInlineAdView *)inlineAd
{
    [self.connector adapterWillLeaveApplication:self];
}

- (nullable UIViewController *)adPresentingViewController
{
    return [self.connector viewControllerForPresentingModalView];
}

// Unused delgate methods
- (void)adDidRefresh:(nonnull VASInlineAdView *)inlineAd {
}

- (void)adDidResize:(nonnull VASInlineAdView *)inlineAd {
}

- (void)adEvent:(nonnull VASInlineAdView *)inlineAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nonnull NSDictionary<NSString *,id> *)arguments {
}

#pragma mark - common

- (void)stopBeingDelegate
{
    if (self.inlineAd) {
        if ([self.inlineAd respondsToSelector:@selector(destroy)]) {
            [self.inlineAd performSelector:@selector(destroy)];
        } else {
            NSLog(@"GADMAdapterVerizon: The adapter is intended to work with Verizon Ads SDK version 1.0.1 or higher.  Please update the Verizon Ads SDK.");
        }
    }
    
    if (self.interstitialAd) {
        if ([self.interstitialAd respondsToSelector:@selector(destroy)]) {
            [self.interstitialAd performSelector:@selector(destroy)];
        } else {
            NSLog(@"GADMAdapterVerizon: The adapter is intended to work with Verizon Ads SDK version 1.0.1 or higher.  Please update the Verizon Ads SDK.");
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
    builder.appMediator = [NSString stringWithFormat:@"AdMobVAS-%@",  [GADMVASAdapterBaseClass adapterVersion]];
    
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

@end
