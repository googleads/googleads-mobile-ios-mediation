#import <Foundation/Foundation.h>

#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBAdInitResults.h"
#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBAdInitSettings.h"

/**
 * Fake FBAudienceNetworkAds interface. This header contains subset of properties and methods of
 * actual public header.
 */
@interface FBAudienceNetworkAds : NSObject

/**
 * Initialize Audience Network SDK at any given point of time. It will be called automatically with
 * default settigs when you first touch AN related code otherwise.
 *
 * @param settings The settings to initialize with.
 * @param completionHandler The block which will be called when initialization finished.
 */
+ (void)initializeWithSettings:(nullable FBAdInitSettings *)settings
             completionHandler:(nullable void (^)(FBAdInitResults *results))completionHandler;

@end
