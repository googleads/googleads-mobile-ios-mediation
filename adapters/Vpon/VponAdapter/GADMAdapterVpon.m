//
// GADMAdapterVpon.m
//
// Copyright 2011 Google, Inc.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "GADMAdapterVpon.h"
#import "GADVpadnDefinition.h"

#define VP_CONTENT_URL @"contentURL"
#define VP_CONTENT_DATA @"contentData"

#define VP_CONTENT_FRIENDLY_OBS @"friendlyObstructions"
#define VP_CONTENT_FRIENDLY_VIEW @"view"
#define VP_CONTENT_FRIENDLY_PURPOSE @"purpose"
#define VP_CONTENT_FRIENDLY_DESC @"desc"

@interface GADMAdapterVpon (CallBacks) <VpadnBannerDelegate, VpadnInterstitialDelegate>

- (void)callBackToConnectorWithAd:(UIView *)view;
- (void)callBackToConnectorWithInterstitial:(NSObject *)interstitial;
- (void)callBackToConnectorWithError:(NSError *)error;

@end

@implementation GADMAdapterVpon

- (void)dealloc {
    [self stopBeingDelegate];
}

#pragma mark - GADMAdNetworkAdapter Imp

+ (NSString *)adapterVersion {
    return VPADN_ADMOB_ADAPTER_VERSION;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADExtras class];
}

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)c {
    self = [super init];
    if (self != nil) {
        _connector = c;
    }
    return self;
}

- (void)stopBeingDelegate {
    // CHANGE THIS: Remove this adapter from being a delegate of your SDK, or
    // remove this adapter from any ad-related notifications.
    if(_banner) {
        _banner.delegate = nil;
        _banner = nil;
    }
    if(_interstitial) {
        _interstitial.delegate = nil;
        _interstitial = nil;
    }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
    return YES;
}

- (BOOL)handlesUserClicks {
    return YES;
}

- (BOOL)handlesUserImpressions {
    return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    if(_interstitial) {
        [_connector adapterWillPresentInterstitial:self];
        [_interstitial showFromRootViewController:rootViewController];
    }
}

#pragma mark Connector Callback methods

- (void) callBackToConnectorWithAd:(UIView *)view {
    if (_connector && [_connector  respondsToSelector:@selector(adapter:didReceiveAdView:)]) {
        NSLog(@"<VponAdapter> callBackToConnectorWithAd:");
         [_connector adapter:self didReceiveAdView:view];
    }
}

- (void) callBackToConnectorWithInterstitial:(NSObject *)interstitial {
    if (_connector && [_connector respondsToSelector:@selector(adapterDidReceiveInterstitial:)]) {
        [_connector adapterDidReceiveInterstitial:self];
    }
}

- (void) callBackToConnectorWithError:(NSError *)error {
    if (_connector && [_connector  respondsToSelector:@selector(adapter:didFailAd:)]) {
        NSLog(@"<VponAdapter> callBackToConnectorWithError:");
        [_connector adapter:self didFailAd:error];
    }
}

#pragma mark - VPON Banner request & call back

- (VpadnAdRequest *) createRequest {
    VpadnAdRequest *request = [[VpadnAdRequest alloc] init];
    [request setAutoRefresh:NO];
    [request setTestDevices:@[]];
    if ([_connector networkExtras]) {
        GADExtras *extra = [_connector networkExtras];
        if (extra.additionalParameters) {
            if ([request respondsToSelector:@selector(setContentData:)]&&
                [extra.additionalParameters.allKeys containsObject:VP_CONTENT_DATA] &&
                [extra.additionalParameters[VP_CONTENT_DATA] isKindOfClass:[NSDictionary class]]) {
                [request setContentData:extra.additionalParameters[VP_CONTENT_DATA]];
            }
            if ([request respondsToSelector:@selector(setContentUrl:)] &&
                [extra.additionalParameters.allKeys containsObject:VP_CONTENT_URL] &&
                [extra.additionalParameters[VP_CONTENT_URL] isKindOfClass:[NSString class]]) {
                    [request setContentUrl:extra.additionalParameters[VP_CONTENT_URL]];
            }
            if ([request respondsToSelector:@selector(addFriendlyObstruction:purpose:description:)] &&
                [extra.additionalParameters.allKeys containsObject:VP_CONTENT_FRIENDLY_OBS] &&
                [extra.additionalParameters[VP_CONTENT_FRIENDLY_OBS] isKindOfClass:[NSArray class]]) {
                NSArray *friendlyObstructions = extra.additionalParameters[VP_CONTENT_FRIENDLY_OBS];
                for (NSDictionary *friendlyObstruction in friendlyObstructions) {
                    if (![friendlyObstruction isKindOfClass:NSDictionary.class]) continue;
                    if (![friendlyObstruction[VP_CONTENT_FRIENDLY_VIEW] isKindOfClass:UIView.class]) continue;
                    UIView *view = friendlyObstruction[VP_CONTENT_FRIENDLY_VIEW];
                    NSString *desc = [friendlyObstruction[VP_CONTENT_FRIENDLY_DESC] isKindOfClass:NSString.class] ? friendlyObstruction[VP_CONTENT_FRIENDLY_DESC] : @"";
                    VpadnFriendlyObstructionType purpose = VpadnFriendlyObstructionOther;
                    if ([friendlyObstruction.allKeys containsObject:VP_CONTENT_FRIENDLY_PURPOSE]) {
                        purpose = [VpadnAdObstruction getVpadnPurpose:[friendlyObstruction[VP_CONTENT_FRIENDLY_PURPOSE] integerValue]];
                    }
                    [request addFriendlyObstruction:view purpose:purpose description:desc];
                }
            }
        }
    }
    for (NSString *keyword in [_connector userKeywords]) {
        [request addKeyword:keyword];
    }
    return request;
}

- (void) getBannerWithSize:(GADAdSize)adSize {
    [GADVpadnDefinition adapterNote];
    VpadnAdSize vpadnAdSize = VpadnAdSizeBanner;
    NSString *sizeType = NSStringFromGADAdSize(adSize);
    if ([GADVpadnDefinition verifyVersion] == NO ||
        [sizeType rangeOfString:@"GADAdSizeFluid"].location != NSNotFound ||
        [sizeType rangeOfString:@"GADAdSizeInvalid"].location != NSNotFound ||
        [sizeType rangeOfString:@"GADAdSizeSkyscraper"].location != NSNotFound) {
        [self callBackToConnectorWithError:[GADVpadnDefinition defaultError]];
        return;
    } else if([sizeType rangeOfString:@"GADAdSizeBanner"].location != NSNotFound) {
        vpadnAdSize = VpadnAdSizeBanner;
    } else if ([sizeType rangeOfString:@"GADAdSizeFullBanner"].location != NSNotFound) {
        vpadnAdSize = VpadnAdSizeFullBanner;
    } else if ([sizeType rangeOfString:@"GADAdSizeLargeBanner"].location != NSNotFound) {
        vpadnAdSize = VpadnAdSizeLargeBanner;
    } else if ([sizeType rangeOfString:@"GADAdSizeLeaderboard"].location != NSNotFound) {
        vpadnAdSize = VpadnAdSizeLeaderboard;
    } else if ([sizeType rangeOfString:@"GADAdSizeSmartBannerPortrait"].location != NSNotFound) {
        vpadnAdSize = VpadnAdSizeSmartBannerPortrait;
    } else if ([sizeType rangeOfString:@"GADAdSizeSmartBannerLandscape"].location != NSNotFound) {
        vpadnAdSize = VpadnAdSizeSmartBannerLandscape;
    } else if ([sizeType rangeOfString:@"GADAdSizeMediumRectangle"].location != NSNotFound) {
        vpadnAdSize = VpadnAdSizeMediumRectangle;
    } else {
        vpadnAdSize = VpadnAdSizeFromCGSize(adSize.size);
    }
    
    if (_banner != nil) {
        __block __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.banner.getVpadnAdView removeFromSuperview];
        });
    }

    _banner = [[VpadnBanner alloc] initWithLicenseKey:[_connector publisherId] adSize:vpadnAdSize];
    _banner.delegate = self;
    [_banner loadRequest:[self createRequest]];
    
    VpadnAdmobFmt(@"AdSize:%@ Flags:%lu", NSStringFromCGSize(adSize.size), (unsigned long)adSize.flags);
}

- (void) onVpadnAdLoaded:(VpadnBanner *)banner {
    NSLog(@"<VponAdapter> onVpadnAdLoaded:");
    _adView = banner.getVpadnAdView;
    [self callBackToConnectorWithAd:_adView];
}

- (void) onVpadnAd:(VpadnBanner *)banner failedToLoad:(NSError *)error {
    NSLog(@"<VponAdapter> onVpadnAd:failedToLoad:");
    [self callBackToConnectorWithError:error];
}

- (void) onVpadnAdWillOpen:(VpadnBanner *)banner {
    [_connector adapterWillPresentFullScreenModal:self];
}

- (void) onVpadnAdClosed:(VpadnBanner *)banner {
    [_connector adapterDidDismissFullScreenModal:self];
}

- (void) onVpadnAdClicked:(VpadnBanner *)banner {
    [_connector adapterDidGetAdClick:self];
}

- (void) onVpadnAdWillLeaveApplication:(VpadnBanner *)banner {
    if ([_connector respondsToSelector:@selector(adapterWillLeaveApplication:)]) {
        [_connector adapterWillLeaveApplication:self];
    }
}

#pragma mark - VPON Interstitial request & call back

- (void) getInterstitial {
    [GADVpadnDefinition adapterNote];
    if (![GADVpadnDefinition verifyVersion]) {
        [self callBackToConnectorWithError:[GADVpadnDefinition defaultError]];
        return;
    }
    _interstitial = [[VpadnInterstitial alloc] initWithLicenseKey:[_connector publisherId]];
    _interstitial.delegate = self;
    [_interstitial loadRequest:[self createRequest]];
}

- (void) onVpadnInterstitialLoaded:(VpadnInterstitial *)interstitial {
    [self callBackToConnectorWithInterstitial:_interstitial];
}

- (void) onVpadnInterstitial:(VpadnInterstitial *)interstitial failedToLoad:(NSError *)error {
    [self callBackToConnectorWithError:error];
}

- (void) onVpadnInterstitialWillOpen:(VpadnInterstitial *)interstitial {
    [_connector adapterWillPresentInterstitial:self];
}

- (void) onVpadnInterstitialClosed:(VpadnInterstitial *)interstitial {
    [_connector adapterDidDismissInterstitial:self];
}

- (void) onVpadnInterstitialClicked:(VpadnInterstitial *)interstitial {
    [_connector adapterDidGetAdClick:self];
}

- (void) onVpadnInterstitialWillLeaveApplication:(VpadnInterstitial *)interstitial {
    if ([_connector respondsToSelector:@selector(adapterWillLeaveApplication:)]) {
        [_connector adapterWillLeaveApplication:self];
    }
}

@end

