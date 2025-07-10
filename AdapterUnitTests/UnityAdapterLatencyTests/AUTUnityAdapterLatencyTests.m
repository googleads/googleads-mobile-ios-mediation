#import "GADMediationAdapterUnity.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTUnityAdapterLatencyTests : XCTestCase
@end

@implementation AUTUnityAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterUnity class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterUnity class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterUnity class]);
}

@end
