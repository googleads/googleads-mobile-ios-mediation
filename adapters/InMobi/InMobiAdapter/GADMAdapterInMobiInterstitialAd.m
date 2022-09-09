//
//  GADMAdapterInMobiRTBInterstitialAd.m
//  IMAdMobAdapter
//
//  Created by Bavirisetti.Dinesh on 02/09/22.
//

#import "GADMAdapterInMobiInterstitialAd.h"
#import <InMobiSDK/IMSdk.h>
#include <stdatomic.h>
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"

@implementation GADMAdapterInMobiInterstitialAd {
    id<GADMediationInterstitialAdEventDelegate> _interstitalAdEventDelegate;
    
    /// Ad Configuration for the nterstitial ad to be rendered.
    GADMediationInterstitialAdConfiguration *_interstitialAdConfig;
    
    GADMediationInterstitialLoadCompletionHandler _interstitialRenderCompletionHandler;
    
    /// InMobi rewarded ad.
    IMInterstitial *_interstitialAd;
    
    /// InMobi Placement identifier.
    NSNumber *_placementIdentifier;
}

/// Initializes the Interstitial ad renderer.
- (nonnull instancetype)initWithPlacementIdentifier:(nonnull NSNumber *)placementIdentifier {
    self = [super init];
    if (self) {
        _placementIdentifier = placementIdentifier;
    }
    return self;
}

- (void)loadInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
    _interstitialAdConfig = adConfiguration;
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
    [completionHandler copy];
    _interstitialRenderCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(id<GADMediationInterstitialAd> interstitialAd, NSError *error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationInterstitialAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
            delegate = originalCompletionHandler(interstitialAd, error);
        }
        originalCompletionHandler = nil;
        return delegate;
    };
    
    GADMAdapterInMobiInterstitialAd *__weak weakSelf = self;
    NSString *accountID = _interstitialAdConfig.credentials.settings[GADMAdapterInMobiAccountID];
    [GADMAdapterInMobiInitializer.sharedInstance
     initializeWithAccountID:accountID
     completionHandler:^(NSError *_Nullable error) {
        GADMAdapterInMobiInterstitialAd *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (error) {
            NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
            strongSelf->_interstitialRenderCompletionHandler(nil, error);
            return;
        }
        
        [strongSelf requestInterstitialAd];
    }];
}

- (void)requestInterstitialAd {
    long long placementId =
    [_interstitialAdConfig.credentials.settings[GADMAdapterInMobiPlacementID] longLongValue];
    if (placementId == 0) {
        NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
                                                                      GADMAdapterInMobiErrorInvalidServerParameters,
                                                                      @"[InMobi] Error - Placement ID not specified.");
        _interstitialRenderCompletionHandler(nil,error);
        return;
    }
    
    if ([_interstitialAdConfig isTestRequest]) {
        NSLog(@"[InMobi] Please enter your device ID in the InMobi console to receive test ads from "
              @"InMobi");
    }
    
    _interstitialAd = [[IMInterstitial alloc] initWithPlacementId:placementId];
    
    GADInMobiExtras *extras =  _interstitialAdConfig.extras;
    if (extras && extras.keywords) {
        [_interstitialAd setKeywords:extras.keywords];
    }
    
    GADMAdapterInMobiSetTargetingFromAdConfiguration(_interstitialAdConfig);
    NSDictionary<NSString *, id> *requestParameters =
    GADMAdapterInMobiCreateRequestParametersFromAdConfiguration(_interstitialAdConfig);
    [_interstitialAd setExtras:requestParameters];
    
    _interstitialAd.delegate = self;
    [_interstitialAd load];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    if ([_interstitialAd isReady]) {
        [_interstitialAd showFromViewController:viewController
                                  withAnimation:kIMInterstitialAnimationTypeCoverVertical];
    }
}

- (void)stopBeingDelegate {
    _interstitialAd.delegate = nil;
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
    return [_interstitialAd isReady];
}

#pragma mark IMAdInterstitialDelegate methods

- (void)interstitialDidFinishLoading:(nonnull IMInterstitial *)interstitial {
    NSLog(@"<<<< interstitialDidFinishRequest >>>>");
    _interstitalAdEventDelegate = _interstitialRenderCompletionHandler(self, nil);
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
didFailToLoadWithError:(IMRequestStatus *)error {
    _interstitialRenderCompletionHandler(nil, error);
}

- (void)interstitialWillPresent:(nonnull IMInterstitial *)interstitial {
    NSLog(@"<<<< interstitialWillPresentScreen >>>>");
    [_interstitalAdEventDelegate willPresentFullScreenView];
}

- (void)interstitialDidPresent:(nonnull IMInterstitial *)interstitial {
    NSLog(@"<<<< interstitialDidPresent >>>>");
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
didFailToPresentWithError:(IMRequestStatus *)error {
    _interstitialRenderCompletionHandler(nil,error);
}

- (void)interstitialWillDismiss:(nonnull IMInterstitial *)interstitial {
    NSLog(@"<<<< interstitialWillDismiss >>>>");
    [_interstitalAdEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDismiss:(nonnull IMInterstitial *)interstitial {
    NSLog(@"<<<< interstitialDidDismiss >>>>");
    [_interstitalAdEventDelegate didDismissFullScreenView];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
didInteractWithParams:(nonnull NSDictionary *)params {
    NSLog(@"<<<< interstitialDidInteract >>>>");
    [_interstitalAdEventDelegate reportClick];
}

- (void)userWillLeaveApplicationFromInterstitial:(nonnull IMInterstitial *)interstitial {
    NSLog(@"<<<< userWillLeaveApplicationFromInterstitial >>>>");
    [_interstitalAdEventDelegate willBackgroundApplication];
}

- (void)interstitialDidReceiveAd:(nonnull IMInterstitial *)interstitial {
    NSLog(@"InMobi AdServer returned a response.");
}

-(void)interstitialAdImpressed:(nonnull IMInterstitial *)interstitial {
    NSLog(@"<<<< interstitialAdImpressed >>>>");
    [_interstitalAdEventDelegate reportImpression];
}

@end

