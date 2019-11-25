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
- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error;
- (void)adAvailable;
- (void)adNotAvailable:(nonnull NSError *)error;
- (void)willShowAd;
- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
@property(nonatomic, strong, nullable) NSString *desiredPlacement;
@property(nonatomic, assign) VungleNetworkAdapterAdType adapterAdType;
@optional
@property(nonatomic, assign) BannerRouterDelegateState bannerState;
@end

@interface GADMAdapterVungleRouter : NSObject <VungleSDKDelegate>
@property(readonly) BOOL isInitialising;
+ (nonnull GADMAdapterVungleRouter *)sharedInstance;

- (void)initWithAppId:(nonnull NSString *)appId delegate:(nullable id<VungleDelegate>)delegate;
- (BOOL)playAd:(nonnull UIViewController *)viewController
      delegate:(nonnull id<VungleDelegate>)delegate
        extras:(nullable VungleAdNetworkExtras *)extras;
- (nullable NSError *)loadAd:(nonnull NSString *)placement
                withDelegate:(nonnull id<VungleDelegate>)delegate;
- (void)removeDelegate:(nonnull id<VungleDelegate>)delegate;
- (BOOL)hasDelegateForPlacementID:(nonnull NSString *)placementID
                      adapterType:(VungleNetworkAdapterAdType)adapterType;
- (nullable UIView *)renderBannerAdInView:(nonnull UIView *)bannerView
                                 delegate:(nonnull id<VungleDelegate>)delegate
                                   extras:(nullable VungleAdNetworkExtras *)extras
                           forPlacementID:(nonnull NSString *)placementID;
- (void)completeBannerAdViewForPlacementID:(nullable NSString *)placementID;
- (BOOL)canRequestBannerAdForPlacementID:(nonnull NSString *)placmentID;
@end
