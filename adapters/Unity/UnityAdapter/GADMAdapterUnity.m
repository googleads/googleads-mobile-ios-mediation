// Copyright 2020 Google LLC.
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

#import "GADMAdapterUnity.h"
#import "GADMAdapterUnityBannerAd.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"
#import "GADMUnityInterstitialAd.h"
#import "GADMediationAdapterUnity.h"
#import "GADUnityError.h"

@interface GADMAdapterUnity () <UnityAdsInitializationDelegate>
@end

@implementation GADMAdapterUnity {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _networkConnector;

  /// Completion handler for initializing the Unity Ads SDK.
  GADMediationAdapterSetUpCompletionBlock _initCompletionHandler;

  /// Game ID of Unity Ads network.
  NSString *_gameID;

  /// Placement ID of Unity Ads network.
  NSString *_placementID;

  /// Unity Ads Banner wrapper
  GADMAdapterUnityBannerAd *_bannerAd;

  /// Unity Ads Interstitial Ad wrapper
  GADMUnityInterstitialAd *_interstitialAd;
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterUnity class];
}

+ (NSString *)adapterVersion {
  return kGADMAdapterUnityVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

- (void)stopBeingDelegate {
  if (_bannerAd != nil) {
    [_bannerAd stopBeingDelegate];
  }
}

- (void)initializeWithGameID:(NSString *)gameID
       withCompletionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (![UnityAds isSupported]) {
    NSString *message = [[NSString alloc] initWithFormat:@"%@ is not supported for this device.",
                                                         NSStringFromClass([UnityAds class])];
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorAdInitializationFailure, message);
    completionHandler(error);
    return;
  }

  if ([UnityAds isInitialized]) {
    NSLog(@"Unity Ads initialized successfully");
    completionHandler(nil);
    return;
  }

  // Configure metadata needed by Unity Ads SDK before initialization.
  GADMAdapterUnityConfigureMediationService();

  // Initializing Unity Ads with |gameID|.
  _initCompletionHandler = completionHandler;
  [UnityAds initialize:gameID testMode:NO enablePerPlacementLoad:YES initializationDelegate:self];
}

#pragma mark Interstitial Methods

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _networkConnector = connector;
  }
  return self;
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _networkConnector;
  if (!strongConnector) return;
  _gameID = [[[strongConnector credentials] objectForKey:kGADMAdapterUnityGameID] copy];
  _interstitialAd = [[GADMUnityInterstitialAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                            adapter:self];
  if (!_interstitialAd) {
    NSString *description =
        [NSString stringWithFormat:@"%@ initialization failed!",
                                   NSStringFromClass([GADMUnityInterstitialAd class])];
    NSError *error =
        GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdObjectNil, description);
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [_interstitialAd getInterstitial];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_interstitialAd presentInterstitialFromRootViewController:rootViewController];
}

#pragma mark Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _networkConnector;

  if (!strongConnector) {
    NSLog(@"Adapter Error: No GADMAdNetworkConnector found.");

    return;
  }
  GADAdSize supportedSize = [self supportedAdSizeFromRequestedSize:adSize];
  if (!IsGADAdSizeValid(supportedSize)) {
    NSString *errorMsg = [NSString
        stringWithFormat:
            @"UnityAds supported banner sizes are not a good fit for the requested size: %@",
            NSStringFromGADAdSize(adSize)];
    NSError *error =
        GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorSizeMismatch, errorMsg);
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  _gameID = [strongConnector.credentials[kGADMAdapterUnityGameID] copy];
  _placementID = [strongConnector.credentials[kGADMAdapterUnityPlacementID] copy];
  if (!_gameID || !_placementID) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorInvalidServerParameters, @"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  _bannerAd = [[GADMAdapterUnityBannerAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                       adapter:self];

  if (!_bannerAd) {
    NSString *description =
        [NSString stringWithFormat:@"%@ initialization failed!",
                                   NSStringFromClass([GADMAdapterUnityBannerAd class])];
    NSError *error =
        GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdObjectNil, description);
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [_bannerAd loadBannerWithSize:supportedSize];
}

/// Find closest supported ad size from a given ad size.
- (GADAdSize)supportedAdSizeFromRequestedSize:(GADAdSize)gadAdSize {
  NSArray *potentials =
      @[ NSValueFromGADAdSize(kGADAdSizeBanner), NSValueFromGADAdSize(kGADAdSizeLeaderboard) ];
  return GADClosestValidSizeForAdSizes(gadAdSize, potentials);
}

#pragma mark UnityAdsInitializationDelegate Methods

- (void)initializationComplete {
  NSLog(@"Unity Ads initialized successfully");
  _initCompletionHandler(nil);
}

- (void)initializationFailed:(UnityAdsInitializationError)error
                 withMessage:(nonnull NSString *)message {
  NSError *adapterError = GADMAdapterUnityErrorWithCodeAndDescription(
      GADMAdapterUnityErrorAdInitializationFailure, message);
  _initCompletionHandler(adapterError);
}

@end
