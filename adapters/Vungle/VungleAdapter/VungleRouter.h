#import <Foundation/Foundation.h>
#import <VungleSDK/VungleSDK.h>

#import "VungleAdNetworkExtras.h"

@protocol VungleDelegate<NSObject>
- (void)initialized:(BOOL)isSuccess error:(NSError *)error;
- (void)adAvailable;
- (void)willShowAd;
- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
@property(readonly, strong) NSString *desiredPlacement;
@property(readonly, assign) BOOL waitingInit;
@end

@interface VungleRouter : NSObject<VungleSDKDelegate>
@property(readonly) BOOL isInitialising;
typedef void (^ParameterCB)(NSDictionary *error, NSString *appId);

+ (NSString *)adapterVersion;
+ (VungleRouter *)sharedInstance;
+ (void)parseServerParameters:(NSDictionary *)serverParameters
                networkExtras:(VungleAdNetworkExtras *)networkExtras
                       result:(ParameterCB)result;
+ (NSString *)findPlacement:(NSDictionary *)serverParameters
              networkExtras:(VungleAdNetworkExtras *)networkExtras;

- (void)initWithAppId:(NSString *)appId;
- (BOOL)playAd:(UIViewController *)viewController
      delegate:(id<VungleDelegate>)delegate
        extras:(VungleAdNetworkExtras *)extras;
- (void)loadAd:(NSString *)placement;
- (void)addDelegate:(id<VungleDelegate>)delegate;
- (void)removeDelegate:(id<VungleDelegate>)delegate;
@end
