#import <Foundation/Foundation.h>

typedef NSString *FBAdExperienceType NS_STRING_ENUM;
extern FBAdExperienceType const FBAdExperienceTypeRewarded;
extern FBAdExperienceType const FBAdExperienceTypeInterstitial;
extern FBAdExperienceType const FBAdExperienceTypeRewardedInterstitial;

/**
 * Fake FBAdExperienceConfig interface. This header contains subset of properties and methods of
 * actual public header.
 */
@interface FBAdExperienceConfig : NSObject <NSCopying>

/**
 * Ad experience type to set up.
 */
@property(nonatomic, nonnull) FBAdExperienceType adExperienceType;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

/**
 * Creates an FBAdExperienceConfig with a specified type of experience.
 */
- (nonnull instancetype)initWithAdExperienceType:(nonnull FBAdExperienceType)adExperienceType;

@end
