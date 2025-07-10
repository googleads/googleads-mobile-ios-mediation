#import "GADMediationAdapterMyTarget.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTMyTargetAdapterLatencyTests : XCTestCase
@end

@implementation AUTMyTargetAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterMyTarget class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterMyTarget class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterMyTarget class]);
}

@end
