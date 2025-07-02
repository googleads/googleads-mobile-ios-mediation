#import "GADMediationAdapterInMobi.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTInMobiAdapterLatencyTests : XCTestCase
@end

@implementation AUTInMobiAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterInMobi class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterInMobi class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterInMobi class]);
}

@end
