//
//  GADCHBBanner.m
//  Adapter
//
//  Created by Daniel Barros on 04/03/2020.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADCHBBanner.h"
#import "GADChartboostError.h"

@interface GADCHBBanner () <CHBBannerDelegate>
@end

@implementation GADCHBBanner {
  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _networkAdapter;
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
  /// Chartboost banner ad.
  CHBBanner *_ad;
}

- (instancetype)initWithSize:(CGSize)size
                    location:(NSString *)location
                   mediation:(CHBMediation *)mediation
              networkAdapter:(id<GADMAdNetworkAdapter>)networkAdapter
                   connector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _networkAdapter = networkAdapter;
    _connector = connector;
    _ad = [[CHBBanner alloc] initWithSize:size
                                 location:location
                                mediation:mediation
                                 delegate:self];
    _ad.automaticallyRefreshesContent = NO;
  }
  return self;
}

- (void)destroy {
  _networkAdapter = nil;
  _connector = nil;
  _ad = nil;
}

- (void)showFromViewController:(UIViewController *)viewController {
  [_ad showFromViewController:viewController];
}

// MARK: - CHBBannerDelegate

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _networkAdapter;
  if (error) {
    [strongConnector adapter:strongAdapter didFailAd:NSErrorForCHBCacheError(error)];
  } else {
    [strongConnector adapter:strongAdapter didReceiveAdView:_ad];
  }
  _ad = nil; // we don't need a strong reference to the banner after it is loaded
}

- (void)willShowAd:(CHBShowEvent *)event {
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error {
  if (error) {
    [_connector adapter:_networkAdapter didFailAd:NSErrorForCHBShowError(error)];
  }
}

- (void)didClickAd:(CHBClickEvent *)event error:(nullable CHBClickError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _networkAdapter;
  [strongConnector adapterDidGetAdClick:strongAdapter];
  if (!error) {
    [strongConnector adapterWillPresentFullScreenModal:strongAdapter];
  }
}

- (void)didFinishHandlingClick:(CHBClickEvent *)event error:(nullable CHBClickError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _networkAdapter;
  [strongConnector adapterWillDismissFullScreenModal:strongAdapter];
  [strongConnector adapterDidDismissFullScreenModal:strongAdapter];
}

@end
