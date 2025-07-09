#import "GADMediationAdapterMintegral.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTMintegralAdapterLatencyTests : XCTestCase
@end

@implementation AUTMintegralAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterMintegral class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterMintegral class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterMintegral class]);
}

@end
