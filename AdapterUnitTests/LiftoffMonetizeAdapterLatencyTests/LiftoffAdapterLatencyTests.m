#import "GADMediationAdapterVungle.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTVungleAdapterLatencyTests : XCTestCase
@end

@implementation AUTVungleAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterVungle class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterVungle class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterVungle class]);
}

@end
