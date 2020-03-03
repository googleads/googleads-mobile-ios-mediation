//
//  GADCHBInterstitial.m
//  Adapter
//
//  Created by Daniel Barros on 02/03/2020.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADCHBInterstitial.h"
#if __has_include(<Chartboost/Chartboost+Mediation.h>)
#import <Chartboost/Chartboost+Mediation.h>
#else
#import "Chartboost+Mediation.h"
#endif

@interface GADCHBInterstitial () <CHBInterstitialDelegate>
@end

@implementation GADCHBInterstitial {
    __weak id<GADMAdNetworkAdapterProtocol> _networkAdapter;
    __weak id<GADMAdNetworkConnector> _connector;
    CHBInterstitial *_ad;
    BOOL _adIsShown;
}

- (instancetype)initWithNetworkAdapter:(id<GADMAdNetworkAdapterProtocol>)networkAdapter
                             connector:(id<GADMAdNetworkConnector>)connector
{
    self = [super init];
    if (self) {
        _networkAdapter = networkAdapter;
        _connector = connector;
        _ad = [[CHBInterstitial alloc] initWithLocation:[self locationFromConnector:connector]
                                              mediation:[self mediation]
                                               delegate:self]
        _adIsShown = NO;
    }
    return self;
}

- (void)destroy
{
    _networkAdapter = nil;
    _connector = nil;
    _ad = nil;
}

- (NSString *)locationFromConnector:(id<GADMAdNetworkConnector>)connector
{
    NSString *location = connector.credentials[kGADMAdapterChartboostAdLocation];
    if ([location isKindOfClass:NSString.class]) {
        location = [location stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    location = location.length > 0 ? location : CBLocationDefault;
    return location;
}

// TODO: Move somewhere else?
- (CHBMediation *)mediation
{
    return [[CHBMediation alloc] initWithType:CBMediationAdMob
                               libraryVersion:[GADRequest sdkVersion]
                               adapterVersion:kGADMAdapterChartboostVersion];
}

- (void)load
{
    [_ad cache];
}

- (void)showFromViewController:(UIViewController *)viewController
{
    [_ad showFromViewController:viewController];
}

// MARK: - CHBAdDelegate

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error
{
    if (error) {
        // TODO: Proper error mapping (adRequestErrorTypeForCBLoadError)
        [_connector adapter:_networkAdapter didFailAd:adRequestErrorTypeForCBLoadError(error)];
    } else {
        [_connector adapterDidReceiveInterstitial:_networkAdapter];
    }
}

- (void)willShowAd:(CHBShowEvent *)event
{
    
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{
    if (error) {
        // if the ad is shown Chartboost will proceed to dismiss it and the rest is handled in didDismissAd:
        if (!_adIsShown) {
            [_connector adapterWillPresentInterstitial:_networkAdapter];
            [_connector adapterWillDismissInterstitial:_networkAdapter];
            [_connector adapterDidDismissInterstitial:_networkAdapter];
        }
    } else {
        _adIsShown = YES;
        [_connector adapterWillPresentInterstitial:_networkAdapter];
    }
}

- (void)didClickAd:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    [_connector adapterDidGetAdClick:_networkAdapter];
    if (!error) {
        [_connector adapterWillLeaveApplication:_networkAdapter];
    }
}

- (void)didFinishHandlingClick:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    
}

- (void)didDismissAd:(CHBDismissEvent *)event
{
    _adIsShown = NO;
    [_connector adapterWillDismissInterstitial:_networkAdapter];
    [_connector adapterDidDismissInterstitial:_networkAdapter];
}

@end
