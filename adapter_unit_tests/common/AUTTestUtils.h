#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

/**
 * Default timeout for XC expectation.
 */
static NSTimeInterval const AUTExpectationTimeout = 120.0;

/**
 * Asserts that two versions have the same value.
 */
void AUTAssertEqualVersion(GADVersionNumber version1, GADVersionNumber version2);

/**
 * Returns the given object's value for the key. If an exception is thrown, then it invokes
 * XCTFails.
 */
id _Nullable AUTValueForKeyIfIsKindOfClass(id _Nonnull object, NSString *_Nonnull aKey,
                                           Class _Nonnull aClass);
