// Copyright 2021 Google LLC
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

#import "GADMediationSnapInterstitial.h"

#import "GADMediationAdapterSnapConstants.h"

#import <SAKSDK/SAKSDK.h>

@interface GADMediationSnapInterstitial () <SAKInterstitialDelegate>
@end

@implementation GADMediationSnapInterstitial {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _completionHandler;
  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;
  // The Snap interstitial ad.
  SAKInterstitial *_interstitial;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _interstitial = [[SAKInterstitial alloc] init];
    _interstitial.delegate = self;
  }
  return self;
}

- (void)renderInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:
                               (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  if (!adConfiguration.bidResponse.length) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"No or empty bid response"};
    NSError *error = [NSError errorWithDomain:GADErrorDomain
                                         code:GADErrorMediationDataError
                                     userInfo:userInfo];
    completionHandler(nil, error);
    return;
  }
  NSString *slotID = adConfiguration.credentials.settings[GADMAdapterSnapAdSlotID];
  if (!slotID.length) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"No slotId found"};
    completionHandler(nil, [[NSError alloc] initWithDomain:GADErrorDomain
                                                      code:GADErrorInvalidRequest
                                                  userInfo:userInfo]);
    return;
  }

  _completionHandler = [completionHandler copy];
  NSData *bidPayload = [[NSData alloc] initWithBase64EncodedString:adConfiguration.bidResponse
                                                           options:0];
  [_interstitial loadAdWithBidPayload:bidPayload publisherSlotId:slotID];
}

#pragma mark - SAKInterstitialDelegate

- (void)interstitialDidLoad:(SAKInterstitial *)ad {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)interstitial:(SAKInterstitial *)ad didFailWithError:(NSError *)error {
  _completionHandler(nil, error);
}

- (void)interstitialDidExpire:(SAKInterstitial *)ad {
  NSError *error = [NSError errorWithDomain:GADErrorDomain
                                       code:GADErrorMediationAdapterError
                                   userInfo:@{NSLocalizedDescriptionKey : @"Ad expired"}];
  [_adEventDelegate didFailToPresentWithError:error];
}

- (void)interstitialWillAppear:(SAKInterstitial *)ad {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)interstitialDidAppear:(SAKInterstitial *)ad {
  // no-op
}

- (void)interstitialWillDisappear:(SAKInterstitial *)ad {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDisappear:(SAKInterstitial *)ad {
  // no-op
}

- (void)interstitialDidShowAttachment:(SAKInterstitial *)ad {
  [_adEventDelegate reportClick];
}

- (void)interstitialDidTrackImpression:(SAKInterstitial *)ad {
  [_adEventDelegate reportImpression];
}

- (void)presentFromViewController:(UIViewController *)viewController {
  [_interstitial presentFromRootViewController:viewController
                             dismissTransition:viewController.view.bounds];
}

@end
