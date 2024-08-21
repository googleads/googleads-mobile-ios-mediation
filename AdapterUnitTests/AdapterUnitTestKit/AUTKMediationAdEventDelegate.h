#import <GoogleMobileAds/GoogleMobileAds.h>

/// A delegate that conforms to GADMediationAdEventDelegate protocol. This object tracks the
/// invocations of the protocol methods.
@interface AUTKMediationAdEventDelegate : NSObject <GADMediationAdEventDelegate>

/// Counts the number of times report impression method was invoked.
@property(nonatomic) NSUInteger reportImpressionInvokeCount;

/// Counts the number of times report click method was invoked.
@property(nonatomic) NSUInteger reportClickInvokeCount;

/// Counts the number of times will present full screen view method was invoked.
@property(nonatomic) NSUInteger willPresentFullScreenViewInvokeCount;

/// An error object passed in for the did fail to present with error method.
///
/// It can be nil if the method was not invoked.
@property(nonatomic, nullable) NSError *didFailToPresentError;

/// Counts the number of times will dismiss full screen view method was invoked.
@property(nonatomic) NSUInteger willDismissFullScreenViewInvokeCount;

/// Counts the number of times did dismiss full screen view method was invoked.
@property(nonatomic) NSUInteger didDismissFullScreenViewInvokeCount;

@end

/// A delegate that conforms to GADMediationAppOpenAdEventDelegate protocol. This object tracks
/// the invocations of the protocol methods.
@interface AUTKMediationAppOpenAdEventDelegate
    : AUTKMediationAdEventDelegate <GADMediationAppOpenAdEventDelegate>
/// The app open ad associated with this event delegate.
@property(nonatomic, nullable) id<GADMediationAppOpenAd> appOpenAd;
@end

/// A delegate that conforms to GADMediationBannerAdEventDelegate protocol. This object tracks the
/// invocations of the protocol methods.
@interface AUTKMediationBannerAdEventDelegate
    : AUTKMediationAdEventDelegate <GADMediationBannerAdEventDelegate>
/// The banner ad associated with this event delegate.
@property(nonatomic, nullable) id<GADMediationBannerAd> bannerAd;
@end

/// A delegate that conforms to GADMediationInterstitialAdEventDelegate protocol. This object tracks
/// the invocations of the protocol methods.
@interface AUTKMediationInterstitialAdEventDelegate
    : AUTKMediationAdEventDelegate <GADMediationInterstitialAdEventDelegate>
/// The interstitial ad associated with this event delegate.
@property(nonatomic, nullable) id<GADMediationInterstitialAd> interstitialAd;
@end

/// A delegate that conforms to GADMediationRewardedAdEventDelegate protocol. This object tracks the
/// invocations of the protocol methods.
@interface AUTKMediationNativeAdEventDelegate
    : AUTKMediationAdEventDelegate <GADMediationNativeAdEventDelegate>

/// The native ad associated with this event delegate.
@property(nonatomic, nullable) id<GADMediationNativeAd> nativeAd;

/// Counts the number of times did play video method was invoked.
@property(nonatomic) NSUInteger didPlayVideoInvokeCount;

/// Counts the number of times did pause video method was invoked.
@property(nonatomic) NSUInteger didPauseVideoInvokeCount;

/// Counts the number of times did end video method was invoked.
@property(nonatomic) NSUInteger didEndVideoInvokeCount;

/// Counts the number of times did mute video method was invoked.
@property(nonatomic) NSUInteger didMuteVideoInvokeCount;

/// Counts the number of times did unmute video method was invoked.
@property(nonatomic) NSUInteger didUnmuteVideoInvokeCount;

@end

/// A delegate that conforms to GADMediationRewardedAdEventDelegate protocol. This object tracks the
/// invocations of the protocol methods.
@interface AUTKMediationRewardedAdEventDelegate
    : AUTKMediationAdEventDelegate <GADMediationRewardedAdEventDelegate>

/// The rewarded ad associated with this event delegate.
@property(nonatomic, nullable) id<GADMediationRewardedAd> rewardedAd;

/// Counts the number of times did reward user method was invoked.
@property(nonatomic) NSUInteger didRewardUserInvokeCount;

/// Counts the number of times did start video method was invoked.
@property(nonatomic) NSUInteger didStartVideoInvokeCount;

/// Counts the number of times did end video method was invoked.
@property(nonatomic) NSUInteger didEndVideoInvokeCount;

@end
