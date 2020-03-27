// Copyright 2019 Google LLC.
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

#import "GADMAdapterUnityBannerAd.h"

#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnitySingleton.h"
#import "GADMediationAdapterUnity.h"
#import "GADUnityError.h"

@interface GADMAdapterUnityBannerAd () <UADSBannerViewDelegate>
@end

@implementation GADMAdapterUnityBannerAd {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Unity Ads banner ad object.
  UADSBannerView *_bannerAd;

  /// Unity ads placement ID.
  NSString *_placementID;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)loadBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector || !strongAdapter) {
    NSLog(@"Adapter Error: No GADMAdNetworkConnector or GADMAdNetworkAdapter found.");
    return;
  }

  if (![UnityAds isInitialized]) {
    NSString *gameID = [strongConnector.credentials[kGADMAdapterUnityGameID] copy];
    [GADMAdapterUnitySingleton.sharedInstance initializeWithGameID:gameID];
  }

  _placementID = [strongConnector.credentials[kGADMAdapterUnityPlacementID] copy];
  _bannerAd = [[UADSBannerView alloc] initWithPlacementId:_placementID size:adSize.size];

  if (!_bannerAd) {
    NSError *error = GADUnityErrorWithDescription(@"Unity banner failed to initialize.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _bannerAd.delegate = self;
  [_bannerAd load];
}

- (void)stopBeingDelegate {
  _bannerAd = nil;
  _bannerAd.delegate = nil;
}

#pragma mark UADSBannerView Delegate methods

- (void)bannerViewDidLoad:(UADSBannerView *)bannerView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapter:strongAdapter didReceiveAdView:bannerView];
  }
}

- (void)bannerViewDidClick:(UADSBannerView *)bannerView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongAdapter && strongConnector) {
    [strongConnector adapterDidGetAdClick:strongAdapter];
  }
}

- (void)bannerViewDidLeaveApplication:(UADSBannerView *)bannerView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongAdapter && strongConnector) {
    [strongConnector adapterWillLeaveApplication:strongAdapter];
  }
}

- (void)bannerViewDidError:(UADSBannerView *)bannerView error:(UADSBannerError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    NSString *errorMsg =
        [NSString stringWithFormat:@"Unity Ads banner failed to load with error: %@",
                                   error.localizedDescription];
    [strongConnector adapter:strongAdapter didFailAd:GADUnityErrorWithDescription(errorMsg)];
  }
}

@end
