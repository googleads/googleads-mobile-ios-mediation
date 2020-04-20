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

@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@property(nonatomic, strong) NADView *nadView;
@property(nonatomic, strong) NADInterstitial *interstitial;
@property(nonatomic, strong) NADInterstitialVideo *interstitialVideo;
@property(nonatomic, strong) NSNotificationCenter *notificationCenter;
@property(nonatomic) GADMNendInterstitialType interstitialType;
@property(nonatomic) InterstitialVideoStatus interstitialVideoStatus;

@end

@implementation GADMAdapterNend

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
    _notificationCenter = nil;
    _interstitialVideo = nil;
    _interstitialType = GADMNendInterstitialTypeNormal;
    _interstitialVideoStatus = InterstitialVideoStopped;
  }
  return self;
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  NSString *apiKey = [self getNendAdParam:kGADMAdapterNendApiKey];
  NSString *spotId = [self getNendAdParam:kGADMAdapterNendSpotID];

  if (![GADMAdapterNendAdUnitMapper validateApiKey:apiKey spotId:spotId]) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        kGADErrorInternalError, @"SpotID and apiKey must not be nil");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  GADMAdapterNendExtras *extras = [strongConnector networkExtras];
  if (extras) {
    self.interstitialType = extras.interstitialType;
  }

  if (self.interstitialType == GADMNendInterstitialTypeVideo) {
    self.interstitialVideo = [[NADInterstitialVideo alloc] initWithSpotId:spotId apiKey:apiKey];
    self.interstitialVideo.delegate = self;
    self.interstitialVideo.userId = extras.userId;
    self.interstitialVideo.mediationName = kGADMAdapterNendMediationName;
    [self.interstitialVideo loadAd];
  } else {
    self.interstitial = [NADInterstitial sharedInstance];
    self.interstitial.delegate = self;
    self.interstitial.enableAutoReload = NO;
    [self.interstitial loadAdWithApiKey:apiKey spotId:spotId];
  }
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  adSize = GADSupportedAdSizeFromRequestedSize(adSize);

  if (GADAdSizeEqualToSize(adSize, kGADAdSizeInvalid)) {
    NSString *errorMsg =
        [NSString stringWithFormat:@"Unable to retrieve supported ad size from GADAdSize: %@",
                                   NSStringFromGADAdSize(adSize)];
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(kGADErrorInternalError, errorMsg);
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  self.nadView = [[NADView alloc] initWithFrame:CGRectZero];

  NSString *apiKey = [self getNendAdParam:kGADMAdapterNendApiKey];
  NSString *spotId = [self getNendAdParam:kGADMAdapterNendSpotID];

  if (![GADMAdapterNendAdUnitMapper validateApiKey:apiKey spotId:spotId]) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        kGADErrorInternalError, @"SpotID and apiKey must not be nil");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  [self.nadView setNendID:apiKey spotID:spotId];
  [self.nadView setBackgroundColor:[UIColor clearColor]];
  [self.nadView setDelegate:self];
  [self.nadView load];
}

- (void)stopBeingDelegate {
  if (self.nadView) {
    self.nadView.delegate = nil;
  }
  if (self.interstitial && self.interstitial.delegate == self) {
    self.interstitial.delegate = nil;
  }
  if (self.notificationCenter) {
    [self.notificationCenter removeObserver:self
                                       name:UIApplicationWillEnterForegroundNotification
                                     object:nil];
    self.notificationCenter = nil;
  }
  if (self.interstitialVideo) {
    self.interstitialVideo.delegate = nil;
    [self.interstitialVideo releaseVideoAd];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  if (self.interstitialType == GADMNendInterstitialTypeVideo) {
    if (self.interstitialVideo.isReady) {
      [self.interstitialVideo showAdFromViewController:rootViewController];
    } else {
      NSLog(@"[nend adapter] Interstitial video ad is not ready...");
    }
  } else {
    NADInterstitialShowResult result =
        [self.interstitial showAdFromViewController:rootViewController];
    if (result == AD_SHOW_SUCCESS) {
      [self.connector adapterWillPresentInterstitial:self];
    } else {
      NSLog(@"[nend adapter] Interstitial ad failed to present.");
    }
  }
}

- (void)dealloc {
  [self stopBeingDelegate];
}

#pragma mark - Internal

- (NSString *)getNendAdParam:(NSString *)paramKey {
  return [self.connector credentials][paramKey];
}

- (void)willEnterForeground:(nonnull NSNotification *)notification {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

#pragma mark - NADViewDelegate

- (void)nadViewDidReceiveAd:(nonnull NADView *)adView {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  [self.nadView pause];

  [strongConnector adapter:self didReceiveAdView:adView];
}

- (void)nadViewDidFailToReceiveAd:(nonnull NADView *)adView {
  NSLog(@"[nend adapter] Banner did fail to load...");
  [self.nadView pause];
  NSError *error = GADMAdapterNendErrorWithCodeAndDescription(kGADErrorInternalError,
                                                              @"Failed to load banner ad.");
  [self.connector adapter:self didFailAd:error];
}

- (void)nadViewDidClickAd:(nonnull NADView *)adView {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
}

- (void)nadViewDidClickInformation:(nonnull NADView *)adView {
  [self.connector adapterWillLeaveApplication:self];
}

#pragma mark - NADInterstitialDelegate

- (void)didFinishLoadInterstitialAdWithStatus:(NADInterstitialStatusCode)status {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  if (status == SUCCESS) {
    [strongConnector adapterDidReceiveInterstitial:self];
  } else {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(kGADErrorInternalError,
                                                                @"Failed to load interstitial ad.");
    [strongConnector adapter:self didFailAd:error];
  }
}

- (void)didClickWithType:(NADInterstitialClickType)type {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  switch (type) {
    case DOWNLOAD:
    case INFORMATION:
      [strongConnector adapterWillDismissInterstitial:self];
      [strongConnector adapterDidDismissInterstitial:self];
      [strongConnector adapterWillLeaveApplication:self];
      break;
    case CLOSE:
      if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [strongConnector adapterWillDismissInterstitial:self];
        [strongConnector adapterDidDismissInterstitial:self];
      } else {
        self.notificationCenter = [NSNotificationCenter defaultCenter];
        [self.notificationCenter addObserver:self
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
  [self.connector adapterDidReceiveInterstitial:self];
}

- (void)nadInterstitialVideoAd:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd
        didFailToLoadWithError:(nonnull NSError *)error {
  [self.connector adapter:self didFailAd:error];
}

- (void)nadInterstitialVideoAdDidFailedToPlay:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  NSLog(@"[nend adapter] Interstitial video ad failed to play...");
}

- (void)nadInterstitialVideoAdDidOpen:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  [self.connector adapterWillPresentInterstitial:self];
}

- (void)nadInterstitialVideoAdDidClose:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
  if (self.interstitialVideoStatus == InterstitialVideoClickedWhenPlaying) {
    [strongConnector adapterWillLeaveApplication:self];
  }
}

- (void)nadInterstitialVideoAdDidClickAd:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  switch (self.interstitialVideoStatus) {
    case InterstitialVideoIsPlaying:
    case InterstitialVideoClickedWhenPlaying:
      self.interstitialVideoStatus = InterstitialVideoClickedWhenPlaying;
      break;
    default:
      [self.connector adapterWillLeaveApplication:self];
      break;
  }
}

- (void)nadInterstitialVideoAdDidClickInformation:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  [self.connector adapterWillLeaveApplication:self];
}

- (void)nadInterstitialVideoAdDidStopPlaying:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  if (self.interstitialVideoStatus != InterstitialVideoClickedWhenPlaying) {
    self.interstitialVideoStatus = InterstitialVideoStopped;
  }
}

- (void)nadInterstitialVideoAdDidStartPlaying:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  self.interstitialVideoStatus = InterstitialVideoIsPlaying;
}

- (void)nadInterstitialVideoAdDidCompletePlaying:
    (nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  self.interstitialVideoStatus = InterstitialVideoStopped;
}

@end
