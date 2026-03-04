#import <UIKit/UIKit.h>

#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/DTBiOSSDK/DTBMediationConstants.h"

@class DTBAdInterstitialDispatcher;

@protocol DTBAdInterstitialDispatcherDelegate <NSObject>
- (void)interstitialDidLoad:(nullable DTBAdInterstitialDispatcher *)interstitial;
- (void)interstitial:(nullable DTBAdInterstitialDispatcher *)interstitial
    didFailToLoadAdWithErrorCode:(DTBAdErrorCode)errorCode;
- (void)interstitialWillPresentScreen:(nullable DTBAdInterstitialDispatcher *)interstitial;
- (void)interstitialDidPresentScreen:(nullable DTBAdInterstitialDispatcher *)interstitial;
- (void)interstitialWillDismissScreen:(nullable DTBAdInterstitialDispatcher *)interstitial;
- (void)interstitialDidDismissScreen:(nullable DTBAdInterstitialDispatcher *)interstitial;
- (void)interstitialWillLeaveApplication:(nullable DTBAdInterstitialDispatcher *)interstitial;
- (void)showFromRootViewController:(nonnull UIViewController *)controller;
- (void)impressionFired;
@optional
- (void)videoPlaybackCompleted:(DTBAdInterstitialDispatcher *)interstitial;
- (void)adClicked;
@end

@interface DTBAdInterstitialDispatcher : NSObject
@property(nonatomic, weak) id<DTBAdInterstitialDispatcherDelegate> delegate;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDelegate:(id<DTBAdInterstitialDispatcherDelegate>)delegate;
- (void)fetchAd:(NSString *)bidInfo;
- (void)showFromController:(nonnull UIViewController *)controller;
- (void)interstitialWillAppear;
- (void)interstitialDidAppear;
- (void)interstitialWillDisappear;
- (void)interstitialDidDisappear;
@end
