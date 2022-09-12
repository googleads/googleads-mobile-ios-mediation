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

@interface GADMAdapterAdColony () <AdColonyAdViewDelegate, AdColonyInterstitialDelegate>
@end

@implementation GADMAdapterAdColony {
  /// AdColony interstitial ad.
  AdColonyInterstitial *_interstitialAd;

  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterAdColony class];
}

+ (NSString *)adapterVersion {
  return GADMAdapterAdColonyVersionString;
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
                    callback:^(NSString *_Nullable zone, NSError *_Nullable error) {
                      GADMAdapterAdColony *strongSelf = weakSelf;
                      if (!strongSelf) {
                        return;
                      }
                      id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
                      if (error) {
                        [strongConnector adapter:strongSelf didFailAd:error];
                        return;
                      }

                      GADMAdapterAdColonyLog(@"Requesting interstitial ad for zone: %@", zone);
                      AdColonyAdOptions *options =
                          [GADMAdapterAdColonyHelper getAdOptionsFromConnector:strongConnector];
                      [AdColony requestInterstitialInZone:zone
                                                  options:options
                                              andDelegate:strongSelf];
                    }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  if (![_interstitialAd showWithPresentingViewController:rootViewController]) {
    GADMAdapterAdColonyLog(@"Failed to show ad.");
  }
}

#pragma mark - Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
  GADMAdapterAdColony *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper
      setupZoneFromConnector:_connector
                    callback:^(NSString *_Nullable zone, NSError *_Nullable error) {
                      GADMAdapterAdColony *strongSelf = weakSelf;
                      if (!strongSelf) {
                        return;
                      }

                      id<GADMAdNetworkConnector> strongConnector = strongSelf->_connector;
                      if (error) {
                        [strongConnector adapter:strongSelf didFailAd:error];
                        return;
                      }

                      dispatch_async(dispatch_get_main_queue(), ^{
                        UIViewController *viewController =
                            [strongConnector viewControllerForPresentingModalView];
                        if (!viewController) {
                          NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(
                              GADMAdapterAdColonyErrorRootViewControllerNil,
                              @"View controller cannot be nil.");
                          [strongConnector adapter:strongSelf didFailAd:error];
                          return;
                        }

                        GADMAdapterAdColonyLog(@"Requesting banner for zone: %@", zone);
                        [strongSelf requestBannerInZoneId:zone
                                                   adSize:adSize
                                           viewController:viewController];
                      });
                    }];
}

- (void)requestBannerInZoneId:(nonnull NSString *)zone
                       adSize:(GADAdSize)adSize
               viewController:(nonnull UIViewController *)viewController {
  AdColonyAdSize adColonyAdSize = AdColonyAdSizeMake(adSize.size.width, adSize.size.height);
  [AdColony requestAdViewInZone:zone
                       withSize:adColonyAdSize
                 viewController:viewController
                    andDelegate:self];
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

#pragma mark - AdColonyAdViewDelegate Delegate

- (void)adColonyAdViewDidLoad:(nonnull AdColonyAdView *)adView {
  GADMAdapterAdColonyLog(@"Banner ad loaded.");
  [_connector adapter:self didReceiveAdView:adView];
}

- (void)adColonyAdViewDidFailToLoad:(nonnull AdColonyAdRequestError *)error {
  GADMAdapterAdColonyLog(@"Failed to load banner ad: %@", error.localizedDescription);
  [_connector adapter:self didFailAd:error];
}

- (void)adColonyAdViewWillLeaveApplication:(nonnull AdColonyAdView *)adView {
  [_connector adapterWillLeaveApplication:self];
}

- (void)adColonyAdViewWillOpen:(nonnull AdColonyAdView *)adView {
  [_connector adapterWillPresentFullScreenModal:self];
}

- (void)adColonyAdViewDidClose:(nonnull AdColonyAdView *)adView {
  [_connector adapterDidDismissFullScreenModal:self];
}

- (void)adColonyAdViewDidReceiveClick:(nonnull AdColonyAdView *)adView {
  [_connector adapterDidGetAdClick:self];
}

#pragma mark - AdColonyInterstitialDelegate Delegate

- (void)adColonyInterstitialDidLoad:(nonnull AdColonyInterstitial *)interstitial {
  GADMAdapterAdColonyLog(@"Loaded interstitial ad for zone: %@", interstitial.zoneID);
  _interstitialAd = interstitial;
  [_connector adapterDidReceiveInterstitial:self];
}

- (void)adColonyInterstitialDidFailToLoad:(nonnull AdColonyAdRequestError *)error {
  GADMAdapterAdColonyLog(@"Failed to load interstitial ad with error: %@",
                         error.localizedDescription);
  [_connector adapter:self didFailAd:error];
}

- (void)adColonyInterstitialWillOpen:(nonnull AdColonyInterstitial *)interstitial {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)adColonyInterstitialDidClose:(nonnull AdColonyInterstitial *)interstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

- (void)adColonyInterstitialExpired:(nonnull AdColonyInterstitial *)interstitial {
  // Each time AdColony's SDK is configured, it discards previously loaded ads. Publishers should
  // initialize the GMA SDK and wait for initialization to complete to ensure that AdColony's SDK
  // gets initialized with all known zones.
  GADMAdapterAdColonyLog(
      @"Interstitial ad expired due to configuring another ad. Use -[GADMobileAds "
      @"startWithCompletionHandler:] to initialize the Google Mobile Ads SDK and wait for the "
      @"completion handler to be called before requesting an ad. Zone: %@",
      interstitial.zoneID);
}

- (void)adColonyInterstitialWillLeaveApplication:(nonnull AdColonyInterstitial *)interstitial {
  [_connector adapterWillLeaveApplication:self];
}

- (void)adColonyInterstitialDidReceiveClick:(nonnull AdColonyInterstitial *)interstitial {
  [_connector adapterDidGetAdClick:self];
}

@end
