#import <Foundation/Foundation.h>

@interface DTBTestProperties : NSObject
@property(class, atomic, readonly, strong, nonnull) DTBTestProperties *sharedInstance;
@property(nonatomic, assign) BOOL shouldBannerAdLoadSucceed;
@property(nonatomic, assign) BOOL shouldInterstitialAdLoadSucceed;
@property(nonatomic, assign) BOOL isAdsReady;
@property(nonatomic, assign, nonnull) NSString *adSDKVersion;
@property(nonatomic, assign, nonnull) NSString *bidInfo;
@property(nonatomic, assign, nonnull) NSString *amznSlots;
- (void)resetToDefault;
@end