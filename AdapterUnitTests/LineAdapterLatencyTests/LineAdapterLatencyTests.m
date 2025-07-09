#import "GADMediationAdapterLine.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTLineAdapterLatencyTests : XCTestCase
@end

@implementation AUTLineAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterLine class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterLine class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterLine class]);
}

@end
