#import <Foundation/Foundation.h>
#import <VungleSDK/VungleSDK.h>

#import "VungleAdNetworkExtras.h"

@protocol VungleDelegate <NSObject>
- (void)initialized:(BOOL)isSuccess error:(NSError *)error;
- (void)adAvailable;
- (void)adNotAvailable:(NSError *)error;
- (void)willShowAd;
- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
@property(readonly, strong) NSString *desiredPlacement;
@end

@interface VungleRouter : NSObject <VungleSDKDelegate>
@property(readonly) BOOL isInitialising;
+ (VungleRouter *)sharedInstance;

- (void)initWithAppId:(NSString *)appId delegate:(id<VungleDelegate>)delegate;
- (BOOL)playAd:(UIViewController *)viewController
      delegate:(id<VungleDelegate>)delegate
        extras:(VungleAdNetworkExtras *)extras;
- (NSError *)loadAd:(NSString *)placement withDelegate:(id<VungleDelegate>)delegate;
@end
