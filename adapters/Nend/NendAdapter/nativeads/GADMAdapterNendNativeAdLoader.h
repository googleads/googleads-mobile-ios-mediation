//
//  GADMAdapterNendNativeAdLoader.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADNendNativeAdLoader.h"

@interface GADMAdapterNendNativeAdLoader : GADNendNativeAdLoader

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler;
@end
