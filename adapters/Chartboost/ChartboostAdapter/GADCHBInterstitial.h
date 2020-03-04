//
//  GADCHBInterstitial.h
//  Adapter
//
//  Created by Daniel Barros on 02/03/2020.
//  Copyright © 2020 Google. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMobileAds/Mediation/GADMAdNetworkAdapterProtocol.h>
#if __has_include(<Chartboost/Chartboost+Mediation.h>)
#import <Chartboost/Chartboost+Mediation.h>
#else
#import "Chartboost+Mediation.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface GADCHBInterstitial : NSObject
- (instancetype)initWithLocation:(NSString *)location
                       mediation:(CHBMediation *)mediation
                  networkAdapter:(id<GADMAdNetworkAdapter>)networkAdapter
                             connector:(id<GADMAdNetworkConnector>)connector;
- (void)destroy;
- (void)load;
- (void)showFromViewController:(nullable UIViewController *)viewController;
@end

NS_ASSUME_NONNULL_END
