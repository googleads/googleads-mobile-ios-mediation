#import "GADMediationAdapterMaio.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTMaioAdapterLatencyTests : XCTestCase
@end

@implementation AUTMaioAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterMaio class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterMaio class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterMaio class]);
}

@end
