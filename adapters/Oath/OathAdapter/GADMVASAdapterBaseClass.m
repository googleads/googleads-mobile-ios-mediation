//
//  GADMAdapterBaseClass.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMVASAdapterBaseClass.h"

@protocol GADMAdNetworkAdapter;
@protocol GADMAdNetworkConnector;

static NSString * const kVASAdapterVersion = @"1.1.2.0";

@interface GADMVASAdapterBaseClass ()

@property CGRect inlineAdFrame;

@end

@implementation GADMVASAdapterBaseClass

#pragma mark - Logger

+ (VASLogger *)logger
{
    static VASLogger *_logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _logger = [VASLogger loggerForClass:[GADMVASAdapterBaseClass class]];
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
- (void)getBannerWithSize:(GADAdSize)gadSize
{
    if (![self prepareAdapterForAdRequest]) {
        return;
    }

    __strong typeof(self.gadConnector) connector = self.gadConnector;

    CGSize adSize = [self GADSupportedAdSizeFromRequestedSize:gadSize];
    if (CGSizeEqualToSize(adSize, CGSizeZero)) {
        [connector adapter:self didFailAd:[NSError errorWithDomain:kGADErrorDomain code:kGADErrorInvalidRequest userInfo:nil]];
        return;
    }

    VASInlineAdSize *size = [[VASInlineAdSize alloc] initWithWidth:adSize.width height:adSize.height];
    self.inlineAdFactory = [[VASInlineAdFactory alloc] initWithPlacementId:self.placementID
                                                                   adSizes:@[size]
                                                                    vasAds:[VASAds sharedInstance]
                                                                  delegate:self];

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

#pragma mark - VASInterstitialAdFactoryDelegate

- (void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory didLoadInterstitialAd:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = interstitialAd;
        [self.gadConnector adapterDidReceiveInterstitial:self];
    });
}

- (void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory didFailWithError:(VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapter:self didFailAd:errorInfo];
    });
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory cacheLoadedNumRequested:(NSInteger)numRequested numReceived:(NSInteger)numReceived
{
    // The cache mechanism is not used in the AdMob mediation flow.
}

- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)adFactory cacheUpdatedWithCacheSize:(NSInteger)cacheSize
{
    // The cache mechanism is not used in the AdMob mediation flow.
}

- (void)interstitialAdFactory:(VASInterstitialAdFactory *)adFactory cacheLoadedNumRequested:(NSInteger)numRequested
{
    // The cache mechanism is not used in the AdMob mediation flow.
}

#pragma mark - VASInterstitialAdDelegate

- (void)interstitialAdDidShow:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterWillPresentInterstitial:self];
    });
}

- (void)interstitialAdDidFail:(VASInterstitialAd *)interstitialAd withError:(VASErrorInfo *)errorInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapter:self didFailAd:errorInfo];
    });
}

- (void)interstitialAdDidClose:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterDidDismissInterstitial:self];
    });
}

- (void)interstitialAdDidLeaveApplication:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterWillLeaveApplication:self];
    });
}

- (void)interstitialAdClicked:(VASInterstitialAd *)interstitialAd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gadConnector adapterDidGetAdClick:self];
    });
}

- (void)interstitialAdEvent:(VASInterstitialAd *)interstitialAd source:(NSString *)source eventId:(NSString *)eventId arguments:(NSDictionary<NSString *, id> *)arguments
{
    // A generic callback that does currently need an implementation for interstitial placements.
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
        self.inlineAd.frame = CGRectMake(0, 0, inlineAd.adSize.width, inlineAd.adSize.height);
        [self.gadConnector adapter:self didReceiveAdView:self.inlineAd];
    });
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory cacheLoadedNumRequested:(NSInteger)numRequested numReceived:(NSInteger)numReceived
{
    // The cache mechanism is not used in the AdMob mediation flow.
}

- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)adFactory cacheUpdatedWithCacheSize:(NSInteger)cacheSize
{
    // The cache mechanism is not used in the AdMob mediation flow.
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
    // AdMob publishers use the AdMob inline refresh mechanism, so an implementation here is not needed.
}

- (void)inlineAdDidResize:(nonnull VASInlineAdView *)inlineAd
{
    // AdMob does not expose a resize callback to map to this.
}

- (void)inlineAdEvent:(nonnull VASInlineAdView *)inlineAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nonnull NSDictionary<NSString *,id> *)arguments
{
    // A generic callback that does currently need an implementation for inline placements.
}

#pragma mark - common

- (BOOL)prepareAdapterForAdRequest {
    if (!self.placementID || ! self.vasAds.isInitialized) {
        NSError *error = [NSError errorWithDomain:kGADErrorDomain
                                             code:kGADErrorMediationAdapterError
                                         userInfo:@{NSLocalizedDescriptionKey : @"Verizon adapter not properly intialized."}];
        [self.gadConnector adapter:self didFailAd:error];
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

- (id<GADMAdNetworkConnector>)gadConnector
{
    return [self.connector conformsToProtocol:@protocol(GADMAdNetworkConnector)]
    ? (id<GADMAdNetworkConnector>)self.connector
    : nil;
}

- (CGSize)GADSupportedAdSizeFromRequestedSize:(GADAdSize)gadAdSize {
    NSArray *potentials = @[
                            NSValueFromGADAdSize(kGADAdSizeBanner),
                            NSValueFromGADAdSize(kGADAdSizeMediumRectangle),
                            NSValueFromGADAdSize(kGADAdSizeLeaderboard)
                            ];
    GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
    if (IsGADAdSizeValid(closestSize)) {
        return CGSizeFromGADAdSize(closestSize);
    }

    return CGSizeZero;
}

@end
