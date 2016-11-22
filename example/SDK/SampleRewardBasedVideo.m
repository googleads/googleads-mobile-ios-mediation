//
// Copyright (C) 2016 Google, Inc.
//
// SampleRewardBasedVideo.m
// Sample Ad Network SDK
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SampleRewardBasedVideo.h"

#import "SampleRewardBasedVideoAd.h"
#import "SampleRewardBasedVideoController.h"

@interface SampleRewardBasedVideo () {
  /// Array of reward-based videos.
  NSMutableArray *_rewardBasedVideos;

  /// YES, if the SDK is initialized.
  BOOL _isSDKInitialized;
}

@end

@implementation SampleRewardBasedVideo

+ (SampleRewardBasedVideo *)sharedInstance {
  static SampleRewardBasedVideo *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[SampleRewardBasedVideo alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _rewardBasedVideos = [[NSMutableArray alloc] init];
  }

  return self;
}

- (void)initializeWithAdRequest:(SampleAdRequest *)request adUnitID:(NSString *)adUnitID {
  _adUnitID = [adUnitID copy];

  if (_isSDKInitialized) {
    NSLog(@"Sample SDK is already initialized.");
    return;
  }

  if (!_adUnitID) {
    id<SampleRewardBasedVideoDelegate> strongDelegate = self.delegate;
    [strongDelegate rewardBasedVideoAd:self didFailToInitializeWithError:SampleErrorCodeBadRequest];

    return;
  }

  _isSDKInitialized = YES;
  [self loadAd];
}

/// Loads a reward-based video ad.
- (void)loadAd {
  // Randomly decide whether to succeed or fail.
  int randomValue = arc4random_uniform(100);
  id<SampleRewardBasedVideoDelegate> strongDelegate = self.delegate;

  if (randomValue < 85) {
    if (randomValue < 20) {
      [self createSampleRewardBasedVideoAds:2 rewardAmount:5];
    } else if (randomValue < 40) {
      [self createSampleRewardBasedVideoAds:4 rewardAmount:10];
    } else if (randomValue < 60) {
      [self createSampleRewardBasedVideoAds:6 rewardAmount:15];
    } else {
      [self createSampleRewardBasedVideoAds:8 rewardAmount:20];
    }

    if (!_isSDKInitialized) {
      _isSDKInitialized = YES;
      if ([strongDelegate respondsToSelector:@selector(rewardBasedVideoAdInitialized:)]) {
        [strongDelegate rewardBasedVideoAdInitialized:self];
      }
    }
  } else if (randomValue < 90) {
    if ([strongDelegate
            respondsToSelector:@selector(rewardBasedVideoAd:didFailToInitializeWithError:)]) {
      [strongDelegate rewardBasedVideoAd:self didFailToInitializeWithError:SampleErrorCodeUnknown];
    }
  } else if (randomValue < 95) {
    if ([strongDelegate
            respondsToSelector:@selector(rewardBasedVideoAd:didFailToInitializeWithError:)]) {
      [strongDelegate rewardBasedVideoAd:self
            didFailToInitializeWithError:SampleErrorCodeNetworkError];
    }

  } else {
    if ([strongDelegate
            respondsToSelector:@selector(rewardBasedVideoAd:didFailToInitializeWithError:)]) {
      [strongDelegate rewardBasedVideoAd:self
            didFailToInitializeWithError:SampleErrorCodeNoInventory];
    }
  }
}

/// Creates multiple reward-based video ads.
- (void)createSampleRewardBasedVideoAds:(int)numberOfAds rewardAmount:(int)reward {
  for (int i = 0; i < numberOfAds; i++) {
    NSString *adName = [NSString stringWithFormat:@"Sample reward-based video ad %d", i];
    SampleRewardBasedVideoAd *rewardBasedVideo =
        [[SampleRewardBasedVideoAd alloc] initWithAdName:adName reward:reward];
    [_rewardBasedVideos addObject:rewardBasedVideo];
  }
}

- (BOOL)checkAdAvailability {
  if (!_isSDKInitialized) {
    NSLog(@"Sample SDK is not initialized.");
    return NO;
  }

  if (_rewardBasedVideos.count > 0) {
    return YES;
  } else {
    [self loadAd];
    return NO;
  }
}

- (void)presentFromRootViewController:(UIViewController *)viewController {
  if (![self checkAdAvailability]) {
    return;
  }

  id<SampleRewardBasedVideoDelegate> strongDelegate = self.delegate;
  SampleRewardBasedVideoAd *sampleRewardBasedVideo =
      (SampleRewardBasedVideoAd *)_rewardBasedVideos[0];
  SampleRewardBasedVideoController *rewardBasedVideoController =
      [[SampleRewardBasedVideoController alloc] initWithRewardBasedVideo:sampleRewardBasedVideo];
  rewardBasedVideoController.delegate = self.delegate;
  [viewController
      presentViewController:rewardBasedVideoController
                   animated:YES
                 completion:^{
                   if ([strongDelegate respondsToSelector:@selector(rewardBasedVideoAdDidOpen:)]) {
                     [strongDelegate rewardBasedVideoAdDidOpen:self];
                   }

                   if ([strongDelegate
                           respondsToSelector:@selector(rewardBasedVideoAdDidStartPlaying:)]) {
                     [strongDelegate rewardBasedVideoAdDidStartPlaying:self];
                   }
                   [_rewardBasedVideos removeObject:sampleRewardBasedVideo];
                 }];
}

@end
