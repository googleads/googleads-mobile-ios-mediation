// Copyright 2016 Google Inc.
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

#import "GADMAdapterTapjoy.h"
#import "GADMTapjoyExtras.h"

#import <Tapjoy/Tapjoy.h>

NSString *const kGADMAdapterTapjoyVersion = @"12.2.0.0";
NSString *const kMediationAgent = @"admob";
NSString *const kTapjoyInternalAdapterVersion = @"1.0.0";

@interface GADMAdapterTapjoy () <TJPlacementVideoDelegate, TJPlacementDelegate> {
  // Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardBasedVideoAdConnector;

  // Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _interstitialConnector;

  TJPlacement *_rvPlacement;
  TJPlacement *_intPlacement;
  BOOL _rvIsRequesting;
  BOOL _intIsRequesting;
}

@end

@implementation GADMAdapterTapjoy

+ (NSString *)adapterVersion {
  return kGADMAdapterTapjoyVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMTapjoyExtras class];
}

#pragma mark Rewardbased video

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
(id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _rewardBasedVideoAdConnector = connector;
  }
  return self;
}

- (void)setUp {
  NSString *sdkKey = [[_rewardBasedVideoAdConnector credentials] objectForKey:@"sdkKey"];
  NSString *placementName = [[_rewardBasedVideoAdConnector credentials]
                             objectForKey:@"placementName"];

  if (!sdkKey.length || !placementName.length) {
    NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey:
                                                @"Did not receive valid Tapjoy server parameters"}];
    [_rewardBasedVideoAdConnector adapter:self
didFailToSetUpRewardBasedVideoAdWithError:adapterError];
    return;
  }

  // if not yet connected, wait for connect response before requesting placement.
  if (![Tapjoy isConnected]) {
    [self setupListeners];
    GADMTapjoyExtras *extras = [_rewardBasedVideoAdConnector networkExtras];
    NSMutableDictionary *connectOptions = [[NSMutableDictionary alloc] init];
    [connectOptions setObject:@(extras.debugEnabled) forKey:TJC_OPTION_ENABLE_LOGGING];

    [Tapjoy connect:sdkKey options:connectOptions];
  }
  else {
    [_rewardBasedVideoAdConnector adapterDidSetUpRewardBasedVideoAd:self];
  }
}

- (void)initRVPlacement {
  NSString *videoPlacementName = [[_rewardBasedVideoAdConnector credentials]
                                  objectForKey:@"placementName"];

  _rvPlacement = [TJPlacement placementWithName:videoPlacementName
                                 mediationAgent:kMediationAgent
                                    mediationId:nil
                                       delegate:self];
  _rvPlacement.adapterVersion = kTapjoyInternalAdapterVersion;
  _rvPlacement.videoDelegate = self;

  _rvIsRequesting = YES;
  [_rvPlacement requestContent];
}

- (void)requestRewardBasedVideoAd {
  NSString *videoPlacementName = [[_rewardBasedVideoAdConnector credentials]
                                  objectForKey:@"placementName"];

  if (!videoPlacementName.length) {
    NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey:
                                                        @"Tapjoy placement name empty or missing"}];
    [_rewardBasedVideoAdConnector adapter:self
 didFailToLoadRewardBasedVideoAdwithError:adapterError];
    return;
  }

  // If incoming placement name is different from the one already preloaded, create new placement.
  if (_rvPlacement && ![videoPlacementName isEqualToString:_rvPlacement.placementName]) {
    [self initRVPlacement];
  }
  // If content is already available from previous request, fire success.
  else if (_rvPlacement && _rvPlacement.contentReady) {
    [_rewardBasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
  }
  else {
    // If we're not already in the middle of a request, send new placement request.
    if (!_rvIsRequesting) {
      [self initRVPlacement];
    }
  }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  [_rvPlacement showContentWithViewController:viewController];
}

#pragma mark Interstitial

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _interstitialConnector = connector;
  }
  return self;
}

- (void)initInterstitialPlacement {
  NSString *interstitialPlacementName = [[_interstitialConnector credentials]
                                         objectForKey:@"placementName"];
  _intPlacement = [TJPlacement placementWithName:interstitialPlacementName
                                  mediationAgent:kMediationAgent
                                     mediationId:nil
                                        delegate:self];
  _intPlacement.adapterVersion = kTapjoyInternalAdapterVersion;

  _intIsRequesting = YES;
  [_intPlacement requestContent];
}

- (void)getInterstitial {
  NSString *sdkKey = [[_interstitialConnector credentials] objectForKey:@"sdkKey"];
  NSString *placementName = [[_interstitialConnector credentials] objectForKey:@"placementName"];

  if (!sdkKey.length || !placementName.length) {
    NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey:
                                                @"Did not receive valid Tapjoy server parameters"}];
    [_interstitialConnector adapter:self didFailAd:adapterError];
    return;
  }

  // if not yet connected, wait for connect response before requesting placement.
  if (![Tapjoy isConnected]) {
    [self setupListeners];
    GADMTapjoyExtras *extras = [_interstitialConnector networkExtras];
    NSMutableDictionary *connectOptions = [[NSMutableDictionary alloc] init];
    [connectOptions setObject:@(extras.debugEnabled) forKey:TJC_OPTION_ENABLE_LOGGING];

    [Tapjoy connect:sdkKey options:connectOptions];
  } else {
    // If content is already available from previous request, fire success.
    if (_intPlacement && _intPlacement.contentReady) {
      [_interstitialConnector adapterDidReceiveInterstitial:self];
    } else {
      // If we're not already in the middle of a request, send new placement request.
      if (!_intIsRequesting) {
        [self initInterstitialPlacement];
      }
    }
    NSLog(@"Requesting interstitial from Tapjoy");
  }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_intPlacement showContentWithViewController:rootViewController];
}

- (void)setupListeners {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tjcConnectSuccess:)
                                               name:TJC_CONNECT_SUCCESS
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tjcConnectFail:)
                                               name:TJC_CONNECT_FAILED
                                             object:nil];
}

-(void)tjcConnectSuccess:(NSNotification*)notifyObj {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_SUCCESS object:nil];
  if (_rewardBasedVideoAdConnector) {
    [_rewardBasedVideoAdConnector adapterDidSetUpRewardBasedVideoAd:self];
  } else if (_interstitialConnector) {
    [self initInterstitialPlacement];
  }
}

- (void)tjcConnectFail:(NSNotification*)notifyObj {
  NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                              code:0
                                          userInfo:@{NSLocalizedDescriptionKey:
                                                       @"Tapjoy Connect did not succeed."}];
  if (_rewardBasedVideoAdConnector) {
    [_rewardBasedVideoAdConnector adapter:self
didFailToSetUpRewardBasedVideoAdWithError:adapterError];
  } else if (_interstitialConnector) {
    [_interstitialConnector adapter:self didFailAd:adapterError];
  }

  [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_FAILED object:nil];
}

- (void)stopBeingDelegate {
  if (_rewardBasedVideoAdConnector) {
    _rvPlacement.delegate = nil;
    _rvPlacement.videoDelegate = nil;
  } else if (_interstitialConnector) {
    _intPlacement.delegate = nil;
  }
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                              code:0
                                          userInfo:@{NSLocalizedDescriptionKey:
                                                       @"This adapter doesn't support banner ads."}];
  [_interstitialConnector adapter:self didFailAd:adapterError];
}


#pragma mark - TJPlacementDelegate methods
- (void)requestDidSucceed:(TJPlacement*)placement {
  if (!placement.contentAvailable) {
    if (_rewardBasedVideoAdConnector) {
      _rvIsRequesting = NO;
      NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                                  code:0
                                              userInfo:@{NSLocalizedDescriptionKey:
                                                           @"Tapjoy Video not available"}];
      [_rewardBasedVideoAdConnector adapter:self
   didFailToLoadRewardBasedVideoAdwithError:adapterError];
    } else if (_interstitialConnector) {
      _intIsRequesting = NO;
      NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                                  code:0
                                              userInfo:@{NSLocalizedDescriptionKey:
                                                           @"Tapjoy interstitial not available"}];
      [_interstitialConnector adapter:self didFailAd:adapterError];
    }
  }
}

- (void)requestDidFail:(TJPlacement*)placement error:(NSError*)error {
  if (_rewardBasedVideoAdConnector) {
    _rvIsRequesting = NO;
    NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey:
                                                         @"Tapjoy Video failed to load"}];
    [_rewardBasedVideoAdConnector adapter:self
 didFailToLoadRewardBasedVideoAdwithError:adapterError];
  } else if (_interstitialConnector) {
    _intIsRequesting = NO;
    NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey:
                                                         @"Tapjoy interstitial failed to load"}];
    [_interstitialConnector adapter:self didFailAd:adapterError];
  }
}

- (void)contentIsReady:(TJPlacement*)placement {
  if (_rewardBasedVideoAdConnector) {
    _rvIsRequesting = NO;
    [_rewardBasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
  } else if (_interstitialConnector) {
    _intIsRequesting = NO;
    [_interstitialConnector adapterDidReceiveInterstitial:self];
  }
}

- (void)contentDidAppear:(TJPlacement*)placement {
  if (_rewardBasedVideoAdConnector) {
    [_rewardBasedVideoAdConnector adapterDidOpenRewardBasedVideoAd:self];
  } else if (_interstitialConnector) {
    [_interstitialConnector adapterWillPresentInterstitial:self];
  }
}

- (void)contentDidDisappear:(TJPlacement*)placement {
  if (_rewardBasedVideoAdConnector) {
    [_rewardBasedVideoAdConnector adapterDidCloseRewardBasedVideoAd:self];

    // Preload on dismiss.
    _rvIsRequesting = YES;
    [_rvPlacement requestContent];
  } else if (_interstitialConnector) {
    [_interstitialConnector adapterWillDismissInterstitial:self];
    [_interstitialConnector adapterDidDismissInterstitial:self];
  }
}

#pragma mark Tapjoy Video
- (void)videoDidStart:(TJPlacement*)placement {
  [_rewardBasedVideoAdConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

- (void)videoDidComplete:(TJPlacement*)placement {
  [_rewardBasedVideoAdConnector adapterDidCompletePlayingRewardBasedVideoAd:self];
  // Tapjoy only supports fixed rewards and doesn't provide a reward type or amount.
  GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                   rewardAmount:[NSDecimalNumber one]];
  [_rewardBasedVideoAdConnector adapter:self didRewardUserWithReward:reward];
}

- (void)videoDidFail:(TJPlacement*)placement error:(NSString*)errorMsg {
  NSError *adapterError = [NSError errorWithDomain:@"com.google.mediation.tapjoy"
                                              code:0
                                          userInfo:@{NSLocalizedDescriptionKey:
                                                       @"Tapjoy Video playback failed"}];
  [_rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:adapterError];
}

@end
