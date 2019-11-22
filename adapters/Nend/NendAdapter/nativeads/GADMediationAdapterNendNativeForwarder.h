//
//  GADMediationAdapterNativeForwarder.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADNendNativeAdLoader.h"

@interface GADMediationAdapterNendNativeForwarder : GADNendNativeAdLoader

- (instancetype)initWithAdapter:(id<GADMAdNetworkAdapter>)adapter
                      connector:(id<GADMAdNetworkConnector>)connector;
- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes options:(NSArray<GADAdLoaderOptions *> *)options;

@end

