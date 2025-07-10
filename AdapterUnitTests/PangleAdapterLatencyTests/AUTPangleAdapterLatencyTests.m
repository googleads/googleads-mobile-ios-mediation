#import "GADMediationAdapterPangle.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTPangleAdapterLatencyTests : XCTestCase
@end

@implementation AUTPangleAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterPangle class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterPangle class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterPangle class]);
}

@end
