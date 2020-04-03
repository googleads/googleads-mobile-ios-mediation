//
//  GADMediationAdapterNativeForwarder.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeAdLoader.h"

@interface GADMediationAdapterNendNativeForwarder : GADMAdapterNendNativeAdLoader

- (nonnull instancetype)initWithAdapter:(nonnull id<GADMAdNetworkAdapter>)adapter
                      connector:(nonnull id<GADMAdNetworkConnector>)connector;
- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes options:(NSArray<GADAdLoaderOptions *> *)options;

@end

