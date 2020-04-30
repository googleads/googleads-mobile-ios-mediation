//
//  GADMediationAdapterNativeForwarder.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMediationAdapterNendNativeForwarder.h"

#import "GADMAdapterNend.h"
#import "GADMAdapterNendAdUnitMapper.h"
#import "GADMAdapterNendConstants.h"

@interface GADMediationAdapterNendNativeForwarder () <GADMAdapterNendNativeAdLoaderDelegate>

@end

@implementation GADMediationAdapterNendNativeForwarder {
  // Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  // Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;
}

- (nonnull instancetype)initWithAdapter:(nonnull id<GADMAdNetworkAdapter>)adapter
                              connector:(nonnull id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self != nil) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)getNativeAdWithAdTypes:(nonnull NSArray<GADAdLoaderAdType> *)adTypes
                       options:(nullable NSArray<GADAdLoaderOptions *> *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  NSString *spotId = [strongConnector credentials][kGADMAdapterNendSpotID];
  NSString *apiKey = [strongConnector credentials][kGADMAdapterNendApiKey];
  GADMAdapterNendExtras *extras = [strongConnector networkExtras];

  [self fetchNativeAd:options spotId:spotId apiKey:apiKey extra:extras];
}

- (void)didFailToLoadWithError:(nonnull NSError *)error {
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongAdapter != nil) {
    [_connector adapter:strongAdapter didFailAd:error];
  }
}

- (void)didReceiveUnifiedNativeAd:(nonnull id<GADMediationNativeAd>)ad {
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongAdapter != nil) {
    [_connector adapter:strongAdapter didReceiveMediatedUnifiedNativeAd:ad];
  }
}

@end
