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

#import "GADMUnityInitializer.h"
#import "GADUnityError.h"
#import "GADMAdapterUnityUtils.h"
#import "GADMAdapterUnityBannerAd.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMUnityInterstitialAd.h"
#import "GADMediationAdapterUnity.h"

@interface GADMAdapterUnity (){
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _networkConnector;
  
  /// Game ID of Unity Ads network.
  NSString *_gameID;
  
  /// Placement ID of Unity Ads network.
  NSString *_placementID;
  
  /// Unity Ads Banner wrapper
  GADMAdapterUnityBannerAd *_bannerAd;
  
  /// Unity Ads Interstitial Ad wrapper
  GADMUnityInterstitialAd *_interstitialAd;
  
}

@end

@implementation GADMAdapterUnity

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

- (void)initializeWithGameID:(NSString *)gameID withInitDelegate:(id)initDelegate{
  if (![UnityAds isSupported]) {
    NSString *message =
      [[NSString alloc] initWithFormat:@"%@ is not supported for this device.",
       NSStringFromClass([UnityAds class])];
    [initDelegate initializationFailed:(kUnityInitializationErrorInternalError) withMessage:message];
    return;
  }
  
  if ([UnityAds isInitialized]) {
    NSLog(@"Unity Ads has already been initialized.");
    [initDelegate initializationComplete];
    return;
  }
  
  // Metadata needed by Unity Ads SDK before initialization.
  GADMUnityConfigureMediationService();
  // Initializing Unity Ads with |gameID|.
  [UnityAds initialize:gameID testMode:NO enablePerPlacementLoad:YES initializationDelegate:initDelegate];
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
  _interstitialAd = [[GADMUnityInterstitialAd alloc] initWithGADMAdNetworkConnector:strongConnector adapter:self];
  if (!_interstitialAd) {
    NSString *description = [NSString
                             stringWithFormat:@"%@ initialization failed!", NSStringFromClass([GADMUnityInterstitialAd class])];
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdObjectNil, description);
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [_interstitialAd getInterstitial];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _networkConnector;
  if (strongConnector) {
    [strongConnector adapterWillPresentInterstitial:self];
  }
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
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription( GADMAdapterUnityErrorInvalidServerParameters, @"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  _bannerAd = [[GADMAdapterUnityBannerAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                       adapter:self];

  if (!_bannerAd) {
    NSString *description = [NSString
                             stringWithFormat:@"%@ initialization failed!", NSStringFromClass([GADMAdapterUnityBannerAd class])];
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdObjectNil, description);
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

@end

@interface GADMUnityInitializationDelegate ()<UnityAdsInitializationDelegate>

@end

@implementation GADMUnityInitializationDelegate

-(nonnull instancetype)initWithCompletionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  self = [super init];
  if (self) {
    initCompletionBlock = completionHandler;
  }
  return self;
}

// UnityAdsInitialization Delegate methods
- (void)initializationComplete {
  NSLog(@"Unity Ads initialized successfully");
  initCompletionBlock(nil);
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(nonnull NSString *)message {
  NSError *err = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdInitializationFailure, message);
  initCompletionBlock(err);
}

@end
