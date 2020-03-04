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
/// Ad wrapper initializer.
- (instancetype)initWithLocation:(NSString *)location
                       mediation:(CHBMediation *)mediation
                  networkAdapter:(id<GADMAdNetworkAdapter>)networkAdapter
                       connector:(id<GADMAdNetworkConnector>)connector;
/// Removes references to adapter, connector and ad severing all communication between them.
- (void)destroy;
/// Loads an ad.
- (void)load;
/// Shows an ad.
- (void)showFromViewController:(nullable UIViewController *)viewController;
@end

NS_ASSUME_NONNULL_END
