//
//  GADMAdapterNendNativeAdLoader.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeAdLoader.h"
#import "GADMAdapterNend.h"

@interface GADMAdapterNendNativeAdLoader () <GADNendNativeAdLoaderDelegate>

@property(nonatomic, copy) GADMediationNativeLoadCompletionHandler completionHandler;

@end

@implementation GADMAdapterNendNativeAdLoader

- (void)didFailToLoadWithError:(nonnull NSError *)error {
    self.completionHandler(nil, error);
}

- (void)didReceiveUnifiedNativeAd:(nonnull id<GADMediationNativeAd>)ad {
    self.completionHandler(ad, nil);
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
    self.completionHandler = completionHandler;
    
    NSString *spotId = adConfiguration.credentials.settings[kGADMAdapterNendSpotID];
    NSString *apiKey = adConfiguration.credentials.settings[kGADMAdapterNendApiKey];
    
    [self fetchNativeAd:[adConfiguration options] spotId:spotId apiKey:apiKey extra:[adConfiguration extras]];
}
@end
