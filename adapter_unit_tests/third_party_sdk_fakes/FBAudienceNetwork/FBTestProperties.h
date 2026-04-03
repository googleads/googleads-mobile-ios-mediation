#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Returns a fake error object.
 */
NSError *_Nonnull FBFakeError();

/**
 * A singleton object that contains test properties and methods.
 */
@interface FBTestProperties : NSObject

/**
 * The shared test properties instance.
 */
@property(class, atomic, readonly, strong, nonnull) FBTestProperties *sharedInstance;

/**
 * Whether the ad should load successfully.
 */
@property(nonatomic) BOOL shouldAdLoadSucceed;

/**
 * Whether rewarded video ad initiatialize successfully.
 */
@property(nonatomic) BOOL shouldRewardedVideoAdInitializationSucceed;

/**
 * FBNativeAdBase's class initializer instantiates either FBNativeAd or FBNativeBannerAd based on
 * given placement ID. Since we do not know how the actual Meta Audience Network decides which to
 * instantiate, we use this property to control the behavior. Set this property to `YES` to
 * instantiate FBNativeAd, and set this property to `NO` to instantiate FBNativeBannerAd.
 */
@property(nonatomic) BOOL shouldFBNativeAdBaseInstantiateNativeAd;

/**
 * Whether Facebook ad should initialize successfully.
 */
@property(nonatomic, assign) BOOL shouldFBAdInitializationSucceed;

/**
 * A message related to Facebook ad init result.
 */
@property(nonatomic, assign, nonnull) NSString *FBAdInitializationResultMessage;

/**
 * A bidder token which returned from FBAdSettings.
 */
@property(nonatomic, assign, nonnull) NSString *bidderToken;

/**
 * The native ad's headline.
 */
@property(nonatomic, copy, nullable) NSString *nativeAdHeadline;

/**
 * The native ad's advertiser name.
 */
@property(nonatomic, copy, nullable) NSString *nativeAdAdvertiserName;

/**
 * The native ad's social context.
 */
@property(nonatomic, copy, nullable) NSString *nativeAdSocialContext;

/**
 * The native ad's call to action.
 */
@property(nonatomic, copy, nullable) NSString *nativeAdCallToAction;

/**
 * The native ad's body text.
 */
@property(nonatomic, copy, nullable) NSString *nativeAdBodyText;

/**
 * The native ad's ad icon image.
 */
@property(nonatomic, copy, nullable) UIImage *nativeAdIconImage;

/**
 * Resets all the properties to their default values.
 */
- (void)resetToDefault;

@end