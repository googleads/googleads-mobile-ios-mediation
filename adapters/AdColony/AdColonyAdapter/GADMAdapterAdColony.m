//
// Copyright 2016, AdColony, Inc.
//

#import "GADMAdapterAdColony.h"

#import <AdColony/AdColony.h>

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMAdapterAdColonyInitializer.h"
#import "GADMediationAdapterAdColony.h"

@implementation GADMAdapterAdColony {
  /// AdColony interstitial ad.
  AdColonyInterstitial *_ad;

  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterAdColony class];
}

+ (NSString *)adapterVersion {
  return kGADMAdapterAdColonyVersionString;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return GADMAdapterAdColonyExtras.class;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
  }
  return self;
}

#pragma mark - Interstitial

- (void)getInterstitial {
  GADMAdapterAdColony *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper
      setupZoneFromConnector:_connector
                    callback:^(NSString *zone, NSError *error) {
                      GADMAdapterAdColony *strongSelf = weakSelf;
                      if (!strongSelf) {
                        return;
                      }

                      id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
                      if (!strongConnector) {
                        return;
                      }

                      if (error) {
                        [strongConnector adapter:strongSelf didFailAd:error];
                        return;
                      }

                      GADMAdapterAdColonyLog(@"Requesting interstitial ad for AdColony Zone: %@",
                                             zone);
                      [strongSelf getInterstitialFromZoneId:zone withConnector:strongConnector];
                    }];
}

- (void)getInterstitialFromZoneId:(nonnull NSString *)zone
                    withConnector:(nonnull id<GADMAdNetworkConnector>)connector {
  _ad = nil;

  GADMAdapterAdColony *__weak weakSelf = self;

  AdColonyAdOptions *options = [GADMAdapterAdColonyHelper getAdOptionsFromConnector:connector];

  [AdColony requestInterstitialInZone:zone
      options:options
      success:^(AdColonyInterstitial *_Nonnull ad) {
        GADMAdapterAdColonyLog(@"Retrieved AdColony interstital ad for zone: %@", zone);
        GADMAdapterAdColony *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        strongSelf->_ad = ad;
        [strongSelf->_connector adapterDidReceiveInterstitial:strongSelf];

        // Re-request intersitial when expires, this avoids the situation:
        // 1. Admob interstitial request from zone A. Causes ADC configure to occur with zone A,
        // then ADC ad request from zone A. Both succeed.
        // 2. Admob rewarded video request from zone B. Causes ADC configure to occur with zones A,
        // B, then ADC ad request from zone B. Both succeed.
        // 3. Try to present ad loaded from zone A. It doesn’t show because of error: `No session
        // with id: xyz has been registered. Cannot show interstitial`.
        [ad setExpire:^{
          GADMAdapterAdColonyLog(
              @"Interstitial Ad expired from zone: %@ because of configuring "
              @"another Ad. To avoid this situation, use startWithCompletionHandler: "
              @"to initialize Google Mobile Ads SDK and wait for the completion handler to be "
              @"called before requesting an ad.",
              zone);
        }];
      }
      failure:^(AdColonyAdRequestError *_Nonnull error) {
        NSError *requestError = GADMAdapterAdColonyErrorWithCodeAndDescription(
            kGADErrorInvalidRequest, error.localizedDescription);
        GADMAdapterAdColony *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        [strongSelf->_connector adapter:strongSelf didFailAd:requestError];
        GADMAdapterAdColonyLog(@"Failed to retrieve AdColony ad for zone: %@ with error: %@", zone,
                               requestError.localizedDescription);
      }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  GADMAdapterAdColony *__weak weakSelf = self;

  [_ad setOpen:^{
    GADMAdapterAdColony *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf->_connector adapterWillPresentInterstitial:strongSelf];
    }
  }];

  [_ad setClick:^{
    GADMAdapterAdColony *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf->_connector adapterDidGetAdClick:strongSelf];
    }
  }];

  [_ad setClose:^{
    GADMAdapterAdColony *strongSelf = weakSelf;
    if (strongSelf) {
      id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
      [strongConnector adapterWillDismissInterstitial:strongSelf];
      [strongConnector adapterDidDismissInterstitial:strongSelf];
    }
  }];

  [_ad setLeftApplication:^{
    GADMAdapterAdColony *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf->_connector adapterWillLeaveApplication:strongSelf];
    }
  }];

  if (![_ad showWithPresentingViewController:rootViewController]) {
    GADMAdapterAdColonyLog(@"Failed to show ad.");
  }
}

#pragma mark - Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(
      kGADErrorInvalidRequest, @"AdColony adapter doesn't currently support Instant-Feed videos.");
  [_connector adapter:self didFailAd:error];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return NO;
}

#pragma mark - Misc

- (void)stopBeingDelegate {
  // AdColony retains the AdColonyAdDelegate during ad playback and does not issue any callbacks
  // outside of ad playback or async calls already in flight.
  // We could cancel the callbacks for async calls already made, but is overkill IMO.
}

@end
