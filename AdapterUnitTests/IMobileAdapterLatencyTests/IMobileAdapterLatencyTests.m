#import "GADMediationAdapterIMobile.h"

#import <XCTest/XCTest.h>
#import <AdapterUnitTestKit/AUTKLatencyTests.h>

@interface AUTIMobileAdapterLatencyTests : XCTestCase
@end

@implementation AUTIMobileAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterIMobile class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterIMobile class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterIMobile class]);
}

@end
