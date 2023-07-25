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

#import "GADMediationAdapterLineNativeAdLoader.h"

#import <UIKit/UIKit.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"
#import "GADMediationAdapterLineUtils.h"

/// The timeout for loading the icon and the information icon image assets in seconds.
static NSUInteger GADMediationAdapterLineImageAssetLoadingTimeoutInSeconds = 10;

@implementation GADMediationAdapterLineNativeAdLoader {
  /// The native ad configuration.
  GADMediationNativeAdConfiguration *_adConfiguration;

  /// The ad event delegate which is used to report native ad related information to the Google
  /// Mobile Ads SDK.
  id<GADMediationNativeAdEventDelegate> _nativeAdEventDelegate;

  /// The native ad instance.
  FADNative *_nativeAd;

  /// Indicates whether the icon and the information icon images need to be loaded.
  BOOL _shouldLoadAdImages;

  /// The icon image for the loaded native ad.
  GADNativeAdImage *_iconImage;

  /// The information icon image view for the loaded native ad.
  UIImageView *_informationIconImageView;

  /// Indicates whether the load completion handler was called.
  BOOL _isCompletionHandlerCalled;

  /// The completion handler that needs to be called upon finishing loading an ad.
  GADMediationNativeLoadCompletionHandler _nativeAdLoadCompletionHandler;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
      loadCompletionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _isCompletionHandlerCalled = NO;
    _nativeAdLoadCompletionHandler = [completionHandler copy];
  }
  return self;
}

- (void)loadAd {
  NSError *error = GADMediationAdapterLineRegisterFiveAd(@[ _adConfiguration.credentials ]);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  NSString *slotID = GADMediationAdapterLineSlotID(_adConfiguration, &error);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  _shouldLoadAdImages = YES;
  NSUInteger numberOfImageAdLoaderOptions = 0;
  for (GADAdLoaderOptions *loaderOptions in _adConfiguration.options) {
    if ([loaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      GADNativeAdImageAdLoaderOptions *imageOptions =
          (GADNativeAdImageAdLoaderOptions *)loaderOptions;
      _shouldLoadAdImages = !imageOptions.disableImageLoading;
      numberOfImageAdLoaderOptions += 1;
    }
  }

  if (numberOfImageAdLoaderOptions > 1) {
    NSString *multipleAdLoaderOptionsWarningMessage = [NSString
        stringWithFormat:@"Multiple image ad loader options were found. If multiple ad loader "
                         @"options are specified, then the adapter uses the last option found. To "
                         @"avoid this behavior, please pass only one image ad loader option. %@",
                         _shouldLoadAdImages
                             ? @"Images will be loaded for this native ad request."
                             : @"Images will be not loaded for this native ad request."];
    GADMediationAdapterLineLog(multipleAdLoaderOptionsWarningMessage);
  }

  GADMediationAdapterLineExtras *extras = (GADMediationAdapterLineExtras *)_adConfiguration.extras;
  _nativeAd = [[FADNative alloc] initWithSlotId:slotID videoViewWidth:extras.nativeAdVideoWidth];
  [_nativeAd setLoadDelegate:self];
  [_nativeAd setAdViewEventListener:self];
  [_nativeAd enableSound:!GADMobileAds.sharedInstance.applicationMuted];
  GADMediationAdapterLineLog(@"Start loading a native ad from FiveAd SDK.");
  [_nativeAd loadAdAsync];
}

- (void)loadAdImageAssetsAsynchronously {
  NSAssert(_nativeAd.state == kFADStateLoaded,
           @"The native ad images cannot be loaded because the native ad hasn't been loaded yet.");

  dispatch_group_t imageLoadGroup = dispatch_group_create();
  __weak __typeof__(self) weakSelf = self;

  GADMediationAdapterLineLog(@"Start loading the icon image for the loaded native ad.");
  dispatch_group_enter(imageLoadGroup);
  [_nativeAd loadIconImageAsyncWithBlock:^(UIImage *iconImage) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) {
      dispatch_group_leave(imageLoadGroup);
      return;
    }

    if (iconImage) {
      GADMediationAdapterLineLog(@"Finished loading the icon image.");
      strongSelf->_iconImage = [[GADNativeAdImage alloc] initWithImage:iconImage];
    } else {
      GADMediationAdapterLineLog(@"The icon image couldn't be loaded.");
    }

    dispatch_group_leave(imageLoadGroup);
  }];

  GADMediationAdapterLineLog(@"Start loading the information icon image for the loaded native ad.");
  dispatch_group_enter(imageLoadGroup);
  [_nativeAd loadInformationIconImageAsyncWithBlock:^(UIImage *informationIconImage) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) {
      dispatch_group_leave(imageLoadGroup);
      return;
    }

    if (informationIconImage) {
      GADMediationAdapterLineLog(@"Finished loading the information icon image.");
      UIImageView *informationIconImageView =
          [[UIImageView alloc] initWithImage:informationIconImage];
      informationIconImageView.contentMode = UIViewContentModeScaleAspectFill;
      strongSelf->_informationIconImageView = informationIconImageView;
    } else {
      GADMediationAdapterLineLog(@"The information icon image couldn't be loaded.");
    }

    dispatch_group_leave(imageLoadGroup);
  }];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    dispatch_time_t timeout = dispatch_time(
        DISPATCH_TIME_NOW, GADMediationAdapterLineImageAssetLoadingTimeoutInSeconds * NSEC_PER_SEC);
    long result = dispatch_group_wait(imageLoadGroup, timeout);

    // It is intended to call the ad load completion handler with the loaded ad even though some of
    // the image assets could have failed to load.
    if (result != 0) {
      GADMediationAdapterLineLog(@"The icon and/or the information icon couldn't be loaded.");
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      __typeof__(self) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      [strongSelf callCompletionHandlerIfNeededWithAd:strongSelf error:nil];
    });
  });
}

- (void)callCompletionHandlerIfNeededWithAd:(nullable id<GADMediationNativeAd>)ad
                                      error:(nullable NSError *)error {
  @synchronized(self) {
    if (_isCompletionHandlerCalled) {
      return;
    }
    _isCompletionHandlerCalled = YES;
  }

  if (_nativeAdLoadCompletionHandler) {
    _nativeAdEventDelegate = _nativeAdLoadCompletionHandler(ad, error);
  }
  _nativeAdLoadCompletionHandler = nil;
}

#pragma mark - FADLoadDelegate

- (void)fiveAdDidLoad:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"FiveAd SDK loaded a native ad.");

  if (_shouldLoadAdImages) {
    // If image assets need to be loaded, wait until they are loaded before calling the ad load
    // completion handler.
    [self loadAdImageAssetsAsynchronously];
    return;
  }

  [self callCompletionHandlerIfNeededWithAd:self error:nil];
}

- (void)fiveAd:(id<FADAdInterface>)ad didFailedToReceiveAdWithError:(FADErrorCode)errorCode {
  GADMediationAdapterLineLog(@"FiveAd SDK failed to load a native ad. The FiveAd error code: %ld.",
                             errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [self callCompletionHandlerIfNeededWithAd:nil error:error];
}

#pragma mark - GADMediationNativeAd

- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (BOOL)hasVideoContent {
  return YES;
}

- (nullable GADNativeAdImage *)icon {
  return _iconImage;
}

- (nullable UIView *)adChoicesView {
  return _informationIconImageView;
}

- (nullable NSString *)headline {
  return _nativeAd.getAdTitle;
}

- (nullable NSString *)body {
  return _nativeAd.getDescriptionText;
}

- (nullable NSString *)callToAction {
  return _nativeAd.getButtonText;
}

- (nullable NSString *)advertiser {
  return _nativeAd.getAdvertiserName;
}

- (nullable UIView *)mediaView {
  return _nativeAd.getAdMainView;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return nil;
}

- (nullable NSDecimalNumber *)starRating {
  return nil;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  return nil;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  [_nativeAd registerViewForInteraction:view
                withInformationIconView:self.adChoicesView
                     withClickableViews:clickableAssetViews.allValues];
}

#pragma mark - FADAdViewEventListener

- (void)fiveAdDidImpression:(id<FADAdInterface>)ad {
  // Called when the native ad records a user impression.
  GADMediationAdapterLineLog(@"The FiveAd native ad did impression.");
  [_nativeAdEventDelegate reportImpression];
}

- (void)fiveAdDidClick:(id<FADAdInterface>)ad {
  // Called when the native ad is clicked by the user.
  GADMediationAdapterLineLog(@"The FiveAd native ad did click.");
  [_nativeAdEventDelegate reportClick];
}

- (void)fiveAdDidStart:(id<FADAdInterface>)ad {
  // Called if the native ad contains a video content and when it starts.
  GADMediationAdapterLineLog(@"The FiveAd native ad did start.");
  [_nativeAdEventDelegate didPlayVideo];
}

- (void)fiveAdDidViewThrough:(id<FADAdInterface>)ad {
  // Called if the native ad contains a video content and when the video reaches its end.
  GADMediationAdapterLineLog(@"The FiveAd native ad did view through.");
  [_nativeAdEventDelegate didEndVideo];
}

- (void)fiveAdDidPause:(id<FADAdInterface>)ad {
  // Called if the native ad contains a video content and when the app goes background while the
  // video is still playing.
  GADMediationAdapterLineLog(@"The FiveAd native ad did pause.");
  [_nativeAdEventDelegate didPauseVideo];
}

- (void)fiveAd:(id<FADAdInterface>)ad didFailedToShowAdWithError:(FADErrorCode)errorCode {
  // Called when something goes wrong in the Five Ad SDK.
  GADMediationAdapterLineLog(@"The FiveAd native ad did fail to show. The FiveAd error code: %ld.",
                             errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [_nativeAdEventDelegate didFailToPresentWithError:error];
}

- (void)fiveAdDidClose:(id<FADAdInterface>)ad {
  // Called when the native ad is closed by user using a close button.
  GADMediationAdapterLineLog(@"The FiveAd native ad did close.");
}

- (void)fiveAdDidResume:(id<FADAdInterface>)ad {
  // Called if the native ad's video content was paused and when the app comes back to foreground.
  GADMediationAdapterLineLog(@"The FiveAd native ad did resume.");
}

- (void)fiveAdDidReplay:(id<FADAdInterface>)ad {
  // Called if the native ad contains a video content and when the video contents gets replayed.
  GADMediationAdapterLineLog(@"The FiveAd native ad did replay.");
}

- (void)fiveAdDidStall:(id<FADAdInterface>)ad {
  // Called if the native ad contains a video content and when it gets stalled for some reason.
  GADMediationAdapterLineLog(@"The FiveAd native ad did stall.");
}

- (void)fiveAdDidRecover:(id<FADAdInterface>)ad {
  // Called when the native ad's video content recover from stalling.
  GADMediationAdapterLineLog(@"The FiveAd native ad did recover.");
}

@end
