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
#import <Tapjoy/Tapjoy.h>
#import "GADMAdapterTapjoyConstants.h"
#import "GADMAdapterTapjoySingleton.h"
#import "GADMTapjoyExtras.h"
#import "GADMediationAdapterTapjoy.h"

@interface GADMAdapterTapjoy () <TJPlacementVideoDelegate, TJPlacementDelegate> {
  // Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _interstitialConnector;

  TJPlacement *_intPlacement;
  NSString *_placementName;
}

@end

@implementation GADMAdapterTapjoy

+ (NSString *)adapterVersion {
  return kGADMAdapterTapjoyVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMTapjoyExtras class];
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterTapjoy class];
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

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  NSString *sdkKey = [[strongConnector credentials] objectForKey:kGADMAdapterTapjoySdkKey];
  _placementName = [[strongConnector credentials] objectForKey:kGADMAdapterTapjoyPlacementKey];

  if (!sdkKey.length || !_placementName.length) {
    NSError *adapterError = [NSError
        errorWithDomain:kGADMAdapterTapjoyErrorDomain
                   code:0
               userInfo:@{
                 NSLocalizedDescriptionKey : @"Did not receive valid Tapjoy server parameters"
               }];
    [strongConnector adapter:self didFailAd:adapterError];
    return;
  }

  GADMTapjoyExtras *extras = [strongConnector networkExtras];
  GADMAdapterTapjoySingleton *sharedInstance = [GADMAdapterTapjoySingleton sharedInstance];

  // if not yet connected, wait for connect response before requesting placement.
  if ([Tapjoy isConnected]) {
    [Tapjoy setDebugEnabled:extras.debugEnabled];
    _intPlacement = [sharedInstance requestAdForPlacementName:_placementName delegate:self];
  } else {
    GADMAdapterTapjoy __weak *weakSelf = self;
    NSDictionary *connectOptions =
        @{TJC_OPTION_ENABLE_LOGGING : [NSNumber numberWithInt:extras.debugEnabled]};
    [sharedInstance
        initializeTapjoySDKWithSDKKey:sdkKey
                              options:connectOptions
                    completionHandler:^(NSError *error) {
                      GADMAdapterTapjoy __strong *strongSelf = weakSelf;
                      if (error) {
                        [strongSelf->_interstitialConnector adapter:self didFailAd:error];
                      } else {
                        strongSelf->_intPlacement = [[GADMAdapterTapjoySingleton sharedInstance]
                            requestAdForPlacementName:strongSelf->_placementName
                                             delegate:strongSelf];
                      }
                    }];
  }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_intPlacement showContentWithViewController:rootViewController];
}

- (void)stopBeingDelegate {
  _intPlacement.delegate = nil;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *adapterError = [NSError
      errorWithDomain:kGADMAdapterTapjoyErrorDomain
                 code:0
             userInfo:@{NSLocalizedDescriptionKey : @"This adapter doesn't support banner ads."}];
  [_interstitialConnector adapter:self didFailAd:adapterError];
}

#pragma mark - TJPlacementDelegate methods
- (void)requestDidSucceed:(TJPlacement *)placement {
  if (!placement.contentAvailable) {
    NSError *adapterError = [NSError
        errorWithDomain:kGADMAdapterTapjoyErrorDomain
                   code:0
               userInfo:@{NSLocalizedDescriptionKey : @"Tapjoy interstitial not available"}];
    [_interstitialConnector adapter:self didFailAd:adapterError];
  }
}

- (void)requestDidFail:(TJPlacement *)placement error:(NSError *)error {
  NSError *adapterError = [NSError
      errorWithDomain:kGADMAdapterTapjoyErrorDomain
                 code:0
             userInfo:@{NSLocalizedDescriptionKey : @"Tapjoy interstitial failed to load"}];
  [_interstitialConnector adapter:self didFailAd:adapterError];
}

- (void)contentIsReady:(TJPlacement *)placement {
  [_interstitialConnector adapterDidReceiveInterstitial:self];
}

- (void)contentDidAppear:(TJPlacement *)placement {
  [_interstitialConnector adapterWillPresentInterstitial:self];
}

- (void)contentDidDisappear:(TJPlacement *)placement {
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

@end
