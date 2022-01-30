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

#import "GADMediationSnapBanner.h"

#import "GADMediationAdapterSnapConstants.h"

#import <SAKSDK/SAKSDK.h>

static SAKAdViewFormat GADSAKAdViewFormatFromAdSize(GADAdSize adSize, BOOL *valid) {
  NSArray<NSValue *> *supportedSizes = @[
    @(GADAdSizeBanner),
    @(GADAdSizeMediumRectangle),
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, supportedSizes);
  if (GADAdSizeEqualToSize(closestSize, GADAdSizeBanner)) {
    *valid = YES;
    return SAKAdViewFormatBanner;
  } else if (GADAdSizeEqualToSize(closestSize, GADAdSizeMediumRectangle)) {
    *valid = YES;
    return SAKAdViewFormatMediumRectangle;
  }
  *valid = NO;
  return -1;
}

@interface GADMediationSnapBanner () <SAKAdViewDelegate>
@end

@implementation GADMediationSnapBanner {
  // Ad Configuration for the ad to be rendered.
  GADMediationBannerAdConfiguration *_adConfiguration;
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationBannerLoadCompletionHandler _completionHandler;
  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationBannerAdEventDelegate> _adEventDelegate;
  // The Snap banner ad.
  SAKAdView *_adView;
}

- (void)renderBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  BOOL isValid = NO;
  SAKAdViewFormat format = GADSAKAdViewFormatFromAdSize(adConfiguration.adSize, &isValid);
  if (!isValid) {
    NSString *size = NSStringFromGADAdSize(adConfiguration.adSize);
    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unsupported ad size: %@", size]};
    completionHandler(nil, [[NSError alloc] initWithDomain:GADErrorDomain
                                                      code:GADErrorMediationInvalidAdSize
                                                  userInfo:userInfo]);
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

  _adConfiguration = adConfiguration;
  _completionHandler = [completionHandler copy];

  _adView = [[SAKAdView alloc] initWithFormat:format];
  [_adView sizeToFit];
  _adView.delegate = self;

  NSData *bidPayload = [[NSData alloc] initWithBase64EncodedString:adConfiguration.bidResponse
                                                           options:0];
  [_adView loadAdWithBidPayload:bidPayload publisherSlotId:slotID];
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
  return _adView;
}

#pragma mark - SAKAdViewDelegate

- (UIViewController *)rootViewController {
  return _adConfiguration.topViewController;
}

- (void)adViewDidLoad:(SAKAdView *)adView {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)adView:(SAKAdView *)adView didFailWithError:(NSError *)error {
  _completionHandler(nil, error);
}

- (void)adViewDidClick:(SAKAdView *)adView {
  [_adEventDelegate reportClick];
  [_adEventDelegate willPresentFullScreenView];
}

- (void)adViewDidTrackImpression:(SAKAdView *)adView {
  [_adEventDelegate reportImpression];
}

@end
