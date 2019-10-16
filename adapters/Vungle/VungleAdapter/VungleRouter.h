#import <Foundation/Foundation.h>
#import <VungleSDK/VungleSDK.h>
#import "VungleAdNetworkExtras.h"

typedef NS_ENUM(NSUInteger, VungleNetworkAdapterAdType) { Unknown, Rewarded, Interstitial, MREC };

typedef NS_ENUM(NSUInteger, BannerRouterDelegateState) {
  BannerRouterDelegateStateRequesting,
  BannerRouterDelegateStateCached,
  BannerRouterDelegateStatePlaying,
  BannerRouterDelegateStateClosing,
  BannerRouterDelegateStateClosed
};

@protocol VungleDelegate<NSObject>
- (void)initialized:(BOOL)isSuccess error:(NSError *)error;
- (void)adAvailable;
- (void)adNotAvailable:(NSError *)error;
- (void)willShowAd;
- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
@property(nonatomic, strong) NSString *desiredPlacement;
@property(nonatomic, assign) VungleNetworkAdapterAdType adapterAdType;
@optional
@property(nonatomic, assign) BannerRouterDelegateState bannerState;
@end

@interface VungleRouter : NSObject<VungleSDKDelegate>
@property(readonly) BOOL isInitialising;
+ (VungleRouter *)sharedInstance;

- (void)initWithAppId:(NSString *)appId delegate:(id<VungleDelegate>)delegate;
- (BOOL)playAd:(UIViewController *)viewController
      delegate:(id<VungleDelegate>)delegate
        extras:(VungleAdNetworkExtras *)extras;
- (NSError *)loadAd:(NSString *)placement withDelegate:(id<VungleDelegate>)delegate;
- (void)removeDelegate:(id<VungleDelegate>)delegate;
- (BOOL)hasDelegateForPlacementID:(NSString *)placementID
                      adapterType:(VungleNetworkAdapterAdType)adapterType;
- (UIView *)renderBannerAdInView:(UIView *)bannerView
                        delegate:(id<VungleDelegate>)delegate
                          extras:(VungleAdNetworkExtras *)extras
                  forPlacementID:(NSString *)placementID;
- (void)completeBannerAdViewForPlacementID:(NSString *)placementID;
- (BOOL)canRequestBannerAdForPlacementID:(NSString *)placmentID;
@end
