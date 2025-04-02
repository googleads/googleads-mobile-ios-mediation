// Copyright 2021 Google LLC.
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

#import "GADMUnityBannerMediationAdapterProxy.h"
#import "GADMAdapterUnityUtils.h"

@interface GADMUnityBannerMediationAdapterProxy ()
@property(nonatomic, copy) GADMediationBannerLoadCompletionHandler loadCompletionHandler;
@property(nonatomic, weak) id<GADMediationBannerAd> ad;
@property(nonatomic) GADAdSize requestedAdSize;
@property(nonatomic) BOOL isBidding;
@end

@implementation GADMUnityBannerMediationAdapterProxy

- (nonnull instancetype)initWithAd:(id<GADMediationBannerAd>)ad
                   requestedAdSize:(GADAdSize)requestedAdSize
                        forBidding:(BOOL)bidding
                 completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _ad = ad;
    _requestedAdSize = requestedAdSize;
    _loadCompletionHandler = completionHandler;
    _isBidding = bidding;
  }
  return self;
}

#pragma mark UADSBannerViewDelegate

- (void)bannerViewDidLoad:(UADSBannerView *)bannerView {
  id<GADMediationBannerAd> ad = self.ad;
  // Verify the ad size only for waterfall.
  if (!_isBidding) {
    GADAdSize supportedSize = GADClosestValidSizeForAdSizes(
        GADAdSizeFromCGSize(bannerView.size), @[ NSValueFromGADAdSize(_requestedAdSize) ]);
    if (!IsGADAdSizeValid(supportedSize)) {
      NSString *errorMsg = [NSString
          stringWithFormat:@"The banner ad returend by Unity does not match with the requested "
                           @"size. The requested ad size: %@. The Unity ad size: %@",
                           NSStringFromGADAdSize(_requestedAdSize),
                           NSStringFromCGSize(bannerView.size)];
      NSError *error =
          GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorSizeMismatch, errorMsg);
      self.loadCompletionHandler(ad, error);
      return;
    }
  }
  self.eventDelegate = self.loadCompletionHandler(ad, nil);
}

- (void)bannerViewDidError:(UADSBannerView *)bannerView error:(UADSBannerError *)error {
  self.loadCompletionHandler(self.ad, error);
}

@end
