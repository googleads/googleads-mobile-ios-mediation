//
//  GADMAdapterNend.m
//  NendAdapter
//
//  Copyright © 2017 FAN Communications. All rights reserved.
//

#import "GADMAdapterNend.h"

#import <NendAd/NendAd.h>

#import "GADMAdapterNendAdUnitMapper.h"
#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNendUtils.h"

@implementation GADMAdapterNendExtras
@end

typedef NS_ENUM(NSInteger, InterstitialVideoStatus) {
  InterstitialVideoStopped,
  InterstitialVideoIsPlaying,
  InterstitialVideoClickedWhenPlaying,
};

/// Find closest supported ad size from a given ad size.
/// Returns nil if no supported size matches.
static GADAdSize GADSupportedAdSizeFromRequestedSize(GADAdSize gadAdSize) {
  NSArray *potentials = @[
    NSValueFromGADAdSize(kGADAdSizeBanner),
    NSValueFromGADAdSize(kGADAdSizeLargeBanner),
    NSValueFromGADAdSize(kGADAdSizeMediumRectangle),
    NSValueFromGADAdSize(kGADAdSizeLeaderboard),
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);

  return closestSize;
}

@interface GADMAdapterNend () <NADViewDelegate,
                               NADInterstitialDelegate,
                               NADInterstitialVideoDelegate>

@end

@implementation GADMAdapterNend {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// nend ad view.
  NADView *_nadView;

  /// nend interstitial.
  NADInterstitial *_interstitial;

  /// nend interstitial video.
  NADInterstitialVideo *_interstitialVideo;

  /// Interstitial type.
  GADMNendInterstitialType _interstitialType;

  /// Interstitial  video status.
  InterstitialVideoStatus _interstitialVideoStatus;
}

+ (nonnull NSString *)adapterVersion {
  return kGADMAdapterNendVersion;
}

+ (nonnull Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterNendExtras class];
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:
    (nonnull id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self != nil) {
    _connector = connector;
    _nadView = nil;
    _interstitial = nil;
    _interstitialVideo = nil;
    _interstitialType = GADMNendInterstitialTypeNormal;
    _interstitialVideoStatus = InterstitialVideoStopped;
  }
  return self;
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *apiKey = [self getNendAdParam:kGADMAdapterNendApiKey];
  NSString *spotId = [self getNendAdParam:kGADMAdapterNendSpotID];

  if (![GADMAdapterNendAdUnitMapper isValidAPIKey:apiKey spotId:spotId]) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        kGADErrorInternalError, @"SpotID and apiKey must not be nil");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  GADMAdapterNendExtras *extras = [strongConnector networkExtras];
  if (extras) {
    _interstitialType = extras.interstitialType;
  }

  if (_interstitialType == GADMNendInterstitialTypeVideo) {
    _interstitialVideo = [[NADInterstitialVideo alloc] initWithSpotId:spotId apiKey:apiKey];
    _interstitialVideo.delegate = self;
    _interstitialVideo.userId = extras.userId;
    _interstitialVideo.mediationName = kGADMAdapterNendMediationName;
    [_interstitialVideo loadAd];
  } else {
    _interstitial = [NADInterstitial sharedInstance];
    _interstitial.delegate = self;
    _interstitial.enableAutoReload = NO;
    [_interstitial loadAdWithApiKey:apiKey spotId:spotId];
  }
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  adSize = GADSupportedAdSizeFromRequestedSize(adSize);

  if (GADAdSizeEqualToSize(adSize, kGADAdSizeInvalid)) {
    NSString *errorMsg =
        [NSString stringWithFormat:@"Unable to retrieve supported ad size from GADAdSize: %@",
                                   NSStringFromGADAdSize(adSize)];
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(kGADErrorInternalError, errorMsg);
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _nadView = [[NADView alloc] initWithFrame:CGRectZero];

  NSString *apiKey = [self getNendAdParam:kGADMAdapterNendApiKey];
  NSString *spotId = [self getNendAdParam:kGADMAdapterNendSpotID];

  if (![GADMAdapterNendAdUnitMapper isValidAPIKey:apiKey spotId:spotId]) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        kGADErrorInternalError, @"SpotID and apiKey must not be nil");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  [_nadView setNendID:apiKey spotID:spotId];
  [_nadView setBackgroundColor:UIColor.clearColor];
  [_nadView setDelegate:self];
  [_nadView load];
}

- (void)stopBeingDelegate {
  [NSNotificationCenter.defaultCenter removeObserver:self
                                                name:UIApplicationWillEnterForegroundNotification
                                              object:nil];

  if (_nadView) {
    _nadView.delegate = nil;
  }
  if (_interstitial && _interstitial.delegate == self) {
    _interstitial.delegate = nil;
  }
  if (_interstitialVideo) {
    _interstitialVideo.delegate = nil;
    [_interstitialVideo releaseVideoAd];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  if (_interstitialType == GADMNendInterstitialTypeVideo) {
    if (!_interstitialVideo.isReady) {
      NSLog(@"[nend adapter] Interstitial video ad is not ready...");
      return;
    }
    [_interstitialVideo showAdFromViewController:rootViewController];
  } else {
    NADInterstitialShowResult result = [_interstitial showAdFromViewController:rootViewController];
    if (result != AD_SHOW_SUCCESS) {
      NSLog(@"[nend adapter] Interstitial ad failed to present.");
      return;
    }
    [_connector adapterWillPresentInterstitial:self];
  }
}

- (void)dealloc {
  [self stopBeingDelegate];
}

#pragma mark - Internal

- (nonnull NSString *)getNendAdParam:(nonnull NSString *)paramKey {
  return [_connector credentials][paramKey];
}

- (void)willEnterForeground:(nonnull NSNotification *)notification {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

#pragma mark - NADViewDelegate

- (void)nadViewDidReceiveAd:(nonnull NADView *)adView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [_nadView pause];

  [strongConnector adapter:self didReceiveAdView:adView];
}

- (void)nadViewDidFailToReceiveAd:(nonnull NADView *)adView {
  NSLog(@"[nend adapter] Banner did fail to load...");
  [_nadView pause];
  NSError *error = GADMAdapterNendErrorWithCodeAndDescription(kGADErrorInternalError,
                                                              @"Failed to load banner ad.");
  [_connector adapter:self didFailAd:error];
}

- (void)nadViewDidClickAd:(nonnull NADView *)adView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
}

- (void)nadViewDidClickInformation:(nonnull NADView *)adView {
  [_connector adapterWillLeaveApplication:self];
}

#pragma mark - NADInterstitialDelegate

- (void)didFinishLoadInterstitialAdWithStatus:(NADInterstitialStatusCode)status {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (status != SUCCESS) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(kGADErrorInternalError,
                                                                @"Failed to load interstitial ad.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [strongConnector adapterDidReceiveInterstitial:self];
}

- (void)didClickWithType:(NADInterstitialClickType)type {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  switch (type) {
    case DOWNLOAD:
    case INFORMATION:
      [strongConnector adapterWillDismissInterstitial:self];
      [strongConnector adapterDidDismissInterstitial:self];
      [strongConnector adapterWillLeaveApplication:self];
      break;
    case CLOSE:
      if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        [strongConnector adapterWillDismissInterstitial:self];
        [strongConnector adapterDidDismissInterstitial:self];
      } else {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(willEnterForeground:)
                                                   name:UIApplicationWillEnterForegroundNotification
                                                 object:nil];
      }
      break;
    default:
      break;
  }
}

#pragma mark - NADInterstitialVideoDelegate

- (void)nadInterstitialVideoAdDidReceiveAd:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  [_connector adapterDidReceiveInterstitial:self];
}

- (void)nadInterstitialVideoAd:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd
        didFailToLoadWithError:(nonnull NSError *)error {
  [_connector adapter:self didFailAd:error];
}

- (void)nadInterstitialVideoAdDidFailedToPlay:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  NSLog(@"[nend adapter] Interstitial video ad failed to play...");
}

- (void)nadInterstitialVideoAdDidOpen:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)nadInterstitialVideoAdDidClose:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
  if (_interstitialVideoStatus == InterstitialVideoClickedWhenPlaying) {
    [strongConnector adapterWillLeaveApplication:self];
  }
}

- (void)nadInterstitialVideoAdDidClickAd:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  switch (_interstitialVideoStatus) {
    case InterstitialVideoIsPlaying:
    case InterstitialVideoClickedWhenPlaying:
      _interstitialVideoStatus = InterstitialVideoClickedWhenPlaying;
      break;
    default:
      [_connector adapterWillLeaveApplication:self];
      break;
  }
}

- (void)nadInterstitialVideoAdDidClickInformation:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  [_connector adapterWillLeaveApplication:self];
}

- (void)nadInterstitialVideoAdDidStopPlaying:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  if (_interstitialVideoStatus != InterstitialVideoClickedWhenPlaying) {
    _interstitialVideoStatus = InterstitialVideoStopped;
  }
}

- (void)nadInterstitialVideoAdDidStartPlaying:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  _interstitialVideoStatus = InterstitialVideoIsPlaying;
}

- (void)nadInterstitialVideoAdDidCompletePlaying:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  _interstitialVideoStatus = InterstitialVideoStopped;
}

@end
