#import <Foundation/Foundation.h>

/// Account ID for InMobi.
static NSString *_Nonnull const AUTInMobiAccountID = @"12345";

/// Placement ID for InMobi.
static NSString *_Nonnull const AUTInMobiPlacementID = @"67890";

/// Keywords for InMobi.
static NSString *_Nonnull const AUTInMobiKeywords = @"InMobiKeywords";

/**
 * Mocks GADMAdapterInMobiInitializer.sharedInstance.
 */
void AUTMockGADMAdapterInMobiInitializer();

/**
 * Mocks IMSDKMock init to call its completion handler immidiately.
 */
void AUTMockIMSDKInit();

/**
 * Returns a native ad content string using the parameters.
 */
NSString *_Nonnull AUTNativeAdContentString(NSString *_Nullable landingPageURLString,
                                            NSString *_Nullable iconURLString,
                                            NSString *_Nullable price);