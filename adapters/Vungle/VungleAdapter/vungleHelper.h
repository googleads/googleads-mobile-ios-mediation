#import <Foundation/Foundation.h>
#import <VungleSDK/VungleSDK.h>

#import "VungleAdNetworkExtras.h"

@protocol VungleDelegate <NSObject>
-(void)initialized:(BOOL)isSuccess error:(NSError *)error;
-(void)adAvailable;
-(void)willShowAd;
-(void)willLeaveApplication;
-(void)willCloseAd:(bool)completedView;
@property (readonly, strong) NSString * desiredPlacement;
@property (readonly, assign) BOOL waitingInit;
@end

@interface vungleHelper : NSObject<VungleSDKDelegate>
@property (readonly) BOOL isInitialising;

+ (NSString *)adapterVersion;

+ (vungleHelper*) sharedInstance;

-(void)initWithAppId:(NSString *)appId placements:(NSArray<NSString *>*)placements;
-(BOOL)playAd:(UIViewController *)viewController delegate:(id<VungleDelegate>)delegate extras:(VungleAdNetworkExtras *)extras;
-(void)loadAd:(NSString *)placement;
-(void)addDelegate:(id<VungleDelegate>)delegate;
-(void)removeDelegate:(id<VungleDelegate>)delegate;
@end
