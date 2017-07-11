#import <Foundation/Foundation.h>
#import <VungleSDK/VungleSDK.h>

#import "VungleAdNetworkExtras.h"

typedef enum {
    InterstitialAdapter = 1 << 1,
    RewardBasedAdapter = 1 << 2
} Adapter;

@protocol VungleDelegate <NSObject>
-(void)initialized:(BOOL)isSuccess error:(NSError *)error;
-(void)adAvailable;
-(void)willShowAd;
-(void)willLeaveApplication;
-(void)willCloseAd:(bool)completedView;
@property (strong) NSString * desiredPlacement;
@end

@interface vungleHelper : NSObject<VungleSDKDelegate>
@property (strong) id<VungleDelegate> interstitialDelegate;
@property (strong) id<VungleDelegate> rewardDelegate;
@property (readonly) BOOL isInitialising;
@property (readonly) BOOL isInitialised;

+ (NSString *)adapterVersion;

+ (vungleHelper*) sharedInstance;

-(void)initWithAppId:(NSString *)appId placements:(NSArray<NSString *>*)placements adapter:(Adapter)adapter;
-(BOOL)isAdPlayableFor:(NSString *)placement;
-(BOOL)playAd:(UIViewController *)viewController adapter:(Adapter)adapter placement:(NSString *)placement extras:(VungleAdNetworkExtras *)extras;
-(void)loadAd:(Adapter)adapter placement:(NSString *)placement;
@end
