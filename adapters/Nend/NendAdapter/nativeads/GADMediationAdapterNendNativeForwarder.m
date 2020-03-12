//
//  GADMediationAdapterNativeForwarder.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMediationAdapterNendNativeForwarder.h"
#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNend.h"
#import "GADMAdapterNendAdUnitMapper.h"

@interface GADMediationAdapterNendNativeForwarder () <GADMAdapterNendNativeAdLoaderDelegate>

@property(nonatomic, weak) id<GADMAdNetworkAdapter> adapter;
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;

@end

@implementation GADMediationAdapterNendNativeForwarder


- (instancetype)initWithAdapter:(id<GADMAdNetworkAdapter>)adapter
                      connector:(id<GADMAdNetworkConnector>)connector {
    self = [super init];
    if (self != nil) {
        _adapter = adapter;
        _connector = connector;
    }
    return self;
}

- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes options:(NSArray<GADAdLoaderOptions *> *)options {
    id<GADMAdNetworkConnector> strongConnector = self.connector;

    NSString *spotId= [GADMAdapterNendAdUnitMapper mappingAdUnitId:strongConnector paramKey:kGADMAdapterNendSpotID];
    NSString *apiKey = [GADMAdapterNendAdUnitMapper mappingAdUnitId:strongConnector paramKey:kGADMAdapterNendApiKey];
    GADMAdapterNendExtras *extras;
    if (strongConnector != nil) {
        extras = [strongConnector networkExtras];
    }

    [self fetchNativeAd:options spotId:spotId apiKey:apiKey extra:extras];
}

- (void)didFailToLoadWithError:(NSError *)error {
    id<GADMAdNetworkAdapter> strongAdapter = self.adapter;
    if (strongAdapter != nil) {
        [self.connector adapter:strongAdapter didFailAd:error];
    }
}

- (void)didReceiveUnifiedNativeAd:(nonnull id<GADMediationNativeAd>)ad {
    id<GADMAdNetworkAdapter> strongAdapter = self.adapter;
    if (strongAdapter != nil) {
        [self.connector adapter:strongAdapter didReceiveMediatedUnifiedNativeAd:ad];
    }
}

@end
