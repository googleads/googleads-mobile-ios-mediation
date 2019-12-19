// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterFyber.h"
#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberRewardedAd.h"
#import "GADMAdapterFyberUtils.h"

#import <CoreLocation/CoreLocation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IASDKCore/IASDKCore.h>
#import <IASDKMRAID/IASDKMRAID.h>
#import <IASDKVideo/IASDKVideo.h>

@interface GADMediationAdapterFyber () <GADMediationAdapter, GADMAdNetworkAdapter, IAUnitDelegate>
@end

@implementation GADMediationAdapterFyber {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Fyber fullscreen controller to catch banner related ad events.
  IAViewUnitController *_viewUnitController;

  /// Fyber fullscreen controller to catch interstitial related ad events.
  IAFullscreenUnitController *_fullscreenUnitController;

  /// Fyber fullscreen controller to catch video content related callbacks.
  IAMRAIDContentController *_MRAIDContentController;

  /// Fyber video controller to catch video progress events.
  IAVideoContentController *_videoContentController;

  /// Fyber Ad spot to be loaded.
  IAAdSpot *_adSpot;

  /// Fyber rewarded ad wrapper.
  GADMAdapterFyberRewardedAd *_rewardedAd;
}

#pragma mark - GADMediationAdapter

+ (GADVersionNumber)adSDKVersion {
  return GADMAdapterFyberVersionFromString([[IASDKCore sharedInstance] version]);
}

+ (GADVersionNumber)version {
  return GADMAdapterFyberVersionFromString(kGADMAdapterFyberVersion);
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet<NSString *> *applicationIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *credential in configuration.credentials) {
    NSString *appID = credential.settings[kGADMAdapterFyberApplicationID];
    if (appID.length) {
      GADMAdapterFyberMutableSetAddObject(applicationIDs, appID);
    }
  }

  if (!applicationIDs.count) {
    NSString *logMessage =
        @"Fyber Marketplace SDK could not be initialized; missing or invalid application ID.";
    GADMAdapterFyberLog(@"%@", logMessage);
    NSError *error =
        GADMAdapterFyberErrorWithCodeAndDescription(kGADErrorMediationDataError, logMessage);
    completionHandler(error);
    return;
  }

  NSString *applicationID = applicationIDs.allObjects.firstObject;
  if (applicationIDs.count > 1) {
    GADMAdapterFyberLog(
        @"Fyber supports a single application ID but multiple application IDs were provided. "
        @"Remove unneeded applications IDs from your mediation configurations. Application IDs: %@",
        applicationIDs);
    GADMAdapterFyberLog(@"Configuring Fyber Marketplace SDK with application ID: %@.",
                        applicationID);
  }

  NSError *initError = nil;
  GADMAdapterFyberInitializeWithAppID(applicationID, &initError);
  completionHandler(initError);
}

#pragma mark - GADMAdNetworkAdapter

+ (NSString *)adapterVersion {
  return kGADMAdapterFyberVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;

  NSError *initError = nil;
  BOOL didInitialize = GADMAdapterFyberInitializeWithAppID(
      strongConnector.credentials[kGADMAdapterFyberApplicationID], &initError);
  if (!didInitialize) {
    GADMAdapterFyberLog(@"Failed to load banner ad: %@", initError.localizedDescription);
    [strongConnector adapter:self didFailAd:initError];
    return;
  }

  NSString *spotID = strongConnector.credentials[kGADMAdapterFyberSpotID];
  IAAdRequest *request =
      GADMAdapterFyberBuildRequestWithSpotIDAndConnector(spotID, strongConnector);
  [self initBannerWithRequest:request];

  GADMediationAdapterFyber *__weak weakSelf = self;
  [_adSpot fetchAdWithCompletion:^(IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel,
                                   NSError *_Nullable error) {
    GADMediationAdapterFyber *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (error) {
      GADMAdapterFyberLog(@"Failed to load banner ad: %@", error.localizedDescription);
      [strongConnector adapter:strongSelf didFailAd:error];
    } else {
      [strongConnector adapter:strongSelf didReceiveAdView:strongSelf->_viewUnitController.adView];
    }
  }];
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;

  NSError *initError = nil;
  BOOL didInitialize = GADMAdapterFyberInitializeWithAppID(
      strongConnector.credentials[kGADMAdapterFyberApplicationID], &initError);
  if (!didInitialize) {
    GADMAdapterFyberLog(@"Failed to load interstitial ad: %@", initError.localizedDescription);
    [strongConnector adapter:self didFailAd:initError];
    return;
  }

  NSString *spotID = strongConnector.credentials[kGADMAdapterFyberSpotID];
  IAAdRequest *request =
      GADMAdapterFyberBuildRequestWithSpotIDAndConnector(spotID, strongConnector);
  [self initInterstitialWithRequest:request];

  GADMediationAdapterFyber *__weak weakSelf = self;
  [_adSpot fetchAdWithCompletion:^(IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel,
                                   NSError *_Nullable error) {
    GADMediationAdapterFyber *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (error) {
      GADMAdapterFyberLog(@"Failed to load interstitial ad: %@", error.localizedDescription);
      [strongConnector adapter:strongSelf didFailAd:error];
    } else {
      [strongConnector adapterDidReceiveInterstitial:strongSelf];
    }
  }];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[GADMAdapterFyberRewardedAd alloc] initWithAdConfiguration:adConfiguration
                                                          completionHandler:completionHandler];
  [_rewardedAd loadRewardedAd];
}

- (void)stopBeingDelegate {
  _viewUnitController.unitDelegate = nil;
  _fullscreenUnitController.unitDelegate = nil;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_fullscreenUnitController showAdAnimated:YES completion:nil];
}

#pragma mark - Service

- (void)initBannerWithRequest:(nonnull IAAdRequest *)request {
  _MRAIDContentController =
      [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder){
      }];

  GADMediationAdapterFyber *__weak weakSelf = self;

  _viewUnitController =
      [IAViewUnitController build:^(id<IAViewUnitControllerBuilder> _Nonnull builder) {
        GADMediationAdapterFyber *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        builder.unitDelegate = strongSelf;
        [builder addSupportedContentController:strongSelf->_MRAIDContentController];
      }];

  _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
    builder.adRequest = request;

    GADMediationAdapterFyber *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    [builder addSupportedUnitController:strongSelf->_viewUnitController];
  }];
}

- (void)initInterstitialWithRequest:(nonnull IAAdRequest *)request {
  _MRAIDContentController =
      [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder){
      }];
  _videoContentController =
      [IAVideoContentController build:^(id<IAVideoContentControllerBuilder> _Nonnull builder){
      }];

  GADMediationAdapterFyber *__weak weakSelf = self;

  _fullscreenUnitController =
      [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder> _Nonnull builder) {
        GADMediationAdapterFyber *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        builder.unitDelegate = strongSelf;
        [builder addSupportedContentController:strongSelf->_MRAIDContentController];
        [builder addSupportedContentController:strongSelf->_videoContentController];
      }];

  _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
    builder.adRequest = request;

    GADMediationAdapterFyber *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    [builder addSupportedUnitController:strongSelf->_fullscreenUnitController];
  }];
}

#pragma mark - IAUnitDelegate

- (nonnull UIViewController *)IAParentViewControllerForUnitController:
    (nullable IAUnitController *)unitController {
  return [_connector viewControllerForPresentingModalView];
}

- (void)IAAdDidReceiveClick:(nullable IAUnitController *)unitController {
  [_connector adapterDidGetAdClick:self];
}

- (void)IAUnitControllerWillPresentFullscreen:(nullable IAUnitController *)unitController {
  id<GADMAdNetworkConnector> strongConnector = _connector;

  if (unitController == _viewUnitController) {
    [strongConnector adapterWillPresentFullScreenModal:self];
  } else if (unitController == _fullscreenUnitController) {
    [strongConnector adapterWillPresentInterstitial:self];
  }
}

- (void)IAUnitControllerWillDismissFullscreen:(nullable IAUnitController *)unitController {
  id<GADMAdNetworkConnector> strongConnector = _connector;

  if (unitController == _viewUnitController) {
    [strongConnector adapterWillDismissFullScreenModal:self];
  } else if (unitController == _fullscreenUnitController) {
    [strongConnector adapterWillDismissInterstitial:self];
  }
}

- (void)IAUnitControllerDidDismissFullscreen:(nullable IAUnitController *)unitController {
  id<GADMAdNetworkConnector> strongConnector = _connector;

  if (unitController == _viewUnitController) {
    [strongConnector adapterDidDismissFullScreenModal:self];
  } else if (unitController == _fullscreenUnitController) {
    [strongConnector adapterDidDismissInterstitial:self];
  }
}

- (void)IAUnitControllerWillOpenExternalApp:(nullable IAUnitController *)unitController {
  [_connector adapterWillLeaveApplication:self];
}

@end
