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

#import "GADMAdapterUnityBannerAd.h"

#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnitySingleton.h"
#import "GADMediationAdapterUnity.h"
#import "GADUnityError.h"

@interface GADMAdapterUnityBannerAd () {

}

@end

@implementation GADMAdapterUnityBannerAd

/// Connector from Google Mobile Ads SDK to receive ad configurations.
__weak id<GADMAdNetworkConnector> _connector;

/// Adapter for receiving ad request notifications.
__weak id<GADMAdNetworkAdapter> _adapter;

/// Banner ad object used by Unity Ads
UADSBannerView* _bannerAd;

///Placement ID
NSString* _placementID;

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector || !strongAdapter) {
    NSLog(@"Adaptor Error: No GADMAdNetworkConnector or GADMAdNetworkAdapter found for getBannerWithSize:");
    return;
  }

  _placementID = [strongConnector.credentials[kGADMAdapterUnityPlacementID] copy];

  if (!_placementID){
    NSString *description = @"Tried to initialize Unity banner with nil placement.";
    NSError *error = GADUnityErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _bannerAd = [[UADSBannerView alloc] initWithPlacementId:_placementID size:adSize.size];

  if (!_bannerAd) {
    NSString *description = @"Unity banne failed to initialize.";
    NSError *error = GADUnityErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  [_bannerAd setDelegate:self];
  [_bannerAd load];
}

- (void)stopBeingDelegate {
  _bannerAd = nil;
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
    NSString *errorMsg = @"Unity Ads banner failed to load - Error.";
    if ( error.code == UADSBannerErrorCodeNoFillError) {
      errorMsg = @"Unity Ads banner failed to load - No Fill.";
    }
    [strongConnector adapter:strongAdapter didFailAd:GADUnityErrorWithDescription(errorMsg)];
    }
  }

@end
