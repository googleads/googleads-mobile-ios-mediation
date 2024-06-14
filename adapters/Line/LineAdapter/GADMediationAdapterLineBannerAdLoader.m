// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterLineBannerAdLoader.h"

#import <UIKit/UIKit.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineUtils.h"

/// Returns nil if the loaded banner ad size is supported. Otherwise, an error is returned.
static NSError *_Nullable GADMediationAdapterLineVerifyLoadedBannerSize(
    FADAdViewCustomLayout *_Nonnull loadedBannerAd, GADAdSize requestedAdSize) {
  GADAdSize adSize = GADAdSizeFromCGSize(loadedBannerAd.frame.size);
  GADAdSize closestSize =
      GADClosestValidSizeForAdSizes(requestedAdSize, @[ NSValueFromGADAdSize(adSize) ]);
  if (!IsGADAdSizeValid(closestSize)) {
    NSString *errorMessage = [NSString
        stringWithFormat:@"The loaded banner ad's size does not match with the requested ad size. "
                         @"The loaded banner ad size: %@. The requested ad size:%@",
                         NSStringFromCGSize(adSize.size), NSStringFromCGSize(requestedAdSize.size)];
    NSError *error = GADMediationAdapterLineErrorWithCodeAndDescription(
        GADMediationAdapterLineErrorLoadedBannerSizeMismatch, errorMessage);
    GADMediationAdapterLineLog(errorMessage);
    return error;
  }
  return nil;
}

@implementation GADMediationAdapterLineBannerAdLoader {
  /// The banner ad configuration.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// The ad event delegate which is used to report banner related information to the Google Mobile
  /// Ads SDK.
  __weak id<GADMediationBannerAdEventDelegate> _bannerAdEventDelegate;

  /// The banner ad.
  __block FADAdViewCustomLayout *_bannerAd;

  /// The requested banner ad size.
  GADAdSize _requestedBannerSize;

  /// Indicates whether the load completion handler was called.
  BOOL _isCompletionHandlerCalled;

  /// The completion handler that needs to be called upon finishing loading an ad.
  GADMediationBannerLoadCompletionHandler _bannerAdLoadCompletionHandler;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
      loadCompletionHandler:(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _requestedBannerSize = adConfiguration.adSize;
    _isCompletionHandlerCalled = NO;
    _bannerAdLoadCompletionHandler = [completionHandler copy];
  }
  return self;
}

- (void)loadAd {
  NSError *error = GADMediationAdapterLineRegisterFiveAd(@[ _adConfiguration.credentials ]);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  if (_adConfiguration.bidResponse) {
    [self loadBiddingAd];
  } else {
    [self loadWaterfallAd];
  }
}

- (void)loadWaterfallAd {
  NSError *error;
  NSString *slotID = GADMediationAdapterLineSlotID(_adConfiguration.credentials, &error);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  _bannerAd = [[FADAdViewCustomLayout alloc] initWithSlotId:slotID
                                                      width:_requestedBannerSize.size.width];
  [_bannerAd setLoadDelegate:self];
  [_bannerAd setEventListener:self];
  [_bannerAd enableSound:GADMediationAdapterLineShouldEnableAudio(_adConfiguration.extras)];
  GADMediationAdapterLineLog(@"Start loading a banner ad from FiveAd SDK.");
  [_bannerAd loadAdAsync];
}

- (void)loadBiddingAd {
  __block NSError *error;
  FADAdLoader *adLoader = GADMediationAdapterLineFADAdLoaderForRegisteredConfig(&error);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }
  NSString *watermarkString =
      GADMediationAdapterLineWatermarkStringFromAdConfiguration(_adConfiguration);
  FADBidData *bidData = [[FADBidData alloc] initWithBidResponse:_adConfiguration.bidResponse
                                                  withWatermark:watermarkString];
  GADMediationAdapterLineBannerAdLoader *__weak weakSelf = self;
  [adLoader
      loadBannerAdWithBidData:bidData
             withLoadCallback:^(FADAdViewCustomLayout *_Nullable customLayout,
                                NSError *_Nullable adLoadError) {
               GADMediationAdapterLineBannerAdLoader *strongSelf = weakSelf;
               if (!strongSelf) {
                 return;
               }

               if (adLoadError) {
                 GADMediationAdapterLineLog(
                     @"FiveAd SDK failed to load a bidding banner ad. The FiveAd error code: %ld.",
                     adLoadError.code);
                 error = GADMediationAdapterLineErrorWithFiveAdErrorCode(adLoadError.code);
                 [strongSelf callCompletionHandlerIfNeededWithAd:nil error:error];
                 return;
               }

               error = GADMediationAdapterLineVerifyLoadedBannerSize(
                   customLayout, strongSelf->_requestedBannerSize);
               if (error) {
                 [self callCompletionHandlerIfNeededWithAd:nil error:error];
                 return;
               }

               CGSize adSize = strongSelf->_requestedBannerSize.size;
               CGRect adFrame = CGRectMake(0, 0, adSize.width, adSize.height);
               customLayout.frame = adFrame;
               [customLayout invalidateIntrinsicContentSize];
               [customLayout layoutIfNeeded];

               [customLayout setEventListener:strongSelf];
               [customLayout enableSound:GADMediationAdapterLineShouldEnableAudio(
                                             strongSelf->_adConfiguration.extras)];
               strongSelf->_bannerAd = customLayout;
               [strongSelf callCompletionHandlerIfNeededWithAd:strongSelf error:nil];
             }];
}

- (void)callCompletionHandlerIfNeededWithAd:(nullable id<GADMediationBannerAd>)ad
                                      error:(nullable NSError *)error {
  @synchronized(self) {
    if (_isCompletionHandlerCalled) {
      return;
    }
    _isCompletionHandlerCalled = YES;
  }

  if (_bannerAdLoadCompletionHandler) {
    _bannerAdEventDelegate = _bannerAdLoadCompletionHandler(ad, error);
  }
  _bannerAdLoadCompletionHandler = nil;
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
  return _bannerAd;
}

#pragma mark - FADLoadDelegate (for waterfall banner ad)

- (void)fiveAdDidLoad:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"FiveAd SDK loaded a waterfall banner ad.");

  // Since the FiveAd SDK does not allow the caller to specify the height at the request point, the
  // loaded banner's size must be verified against the requested ad size.
  FADAdViewCustomLayout *bannerAd = (FADAdViewCustomLayout *)ad;
  NSError *error = GADMediationAdapterLineVerifyLoadedBannerSize(bannerAd, _requestedBannerSize);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }
  [self callCompletionHandlerIfNeededWithAd:self error:nil];
}

- (void)fiveAd:(id<FADAdInterface>)ad didFailedToReceiveAdWithError:(FADErrorCode)errorCode {
  GADMediationAdapterLineLog(@"FiveAd SDK failed to load a banner ad. The FiveAd error code: %ld.",
                             errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [self callCompletionHandlerIfNeededWithAd:nil error:error];
}

#pragma mark - FADCustomLayoutEventListener

- (void)fiveCustomLayoutAdDidImpression:(FADAdViewCustomLayout *)ad {
  // Called when the banner ad records a user impression.
  GADMediationAdapterLineLog(@"The FiveAd banner ad did impression.");
  [_bannerAdEventDelegate reportImpression];
}

- (void)fiveCustomLayoutAdDidClick:(FADAdViewCustomLayout *)ad {
  // Called when the banner ad is clicked by the user.
  GADMediationAdapterLineLog(@"The FiveAd banner ad did click.");
  [_bannerAdEventDelegate reportClick];
}

- (void)fiveCustomLayoutAd:(FADAdViewCustomLayout *)ad
    didFailedToShowAdWithError:(FADErrorCode)errorCode {
  // Called when something goes wrong in the Five Ad SDK.
  GADMediationAdapterLineLog(@"The FiveAd banner ad did fail to show. The FiveAd error code: %ld.",
                             errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [_bannerAdEventDelegate didFailToPresentWithError:error];
}

- (void)fiveCustomLayoutAdViewDidRemove:(FADAdViewCustomLayout *)ad {
  // Called when the banner ad is closed by user using a close button.
  GADMediationAdapterLineLog(@"The FiveAd banner ad did remove.");
}

- (void)fiveCustomLayoutAdDidPlay:(FADAdViewCustomLayout *)ad {
  // Called if the banner contains a video content and when it starts.
  GADMediationAdapterLineLog(@"The FiveAd banner ad did play.");
}

- (void)fiveCustomLayoutAdDidPause:(FADAdViewCustomLayout *)ad {
  // Called if the banner contains a video content and when the app goes background while the video
  // is still playing.
  GADMediationAdapterLineLog(@"The FiveAd banner ad did pause.");
}

- (void)fiveCustomLayoutAdDidViewThrough:(FADAdViewCustomLayout *)ad {
  // Called if the banner contains a video content and when the video reaches its end.
  GADMediationAdapterLineLog(@"The FiveAd banner ad did view through.");
}

@end
