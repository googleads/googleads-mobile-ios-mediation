#import "GADMediationAdapterFyber.h"

#import <XCTest/XCTest.h>
#import <AdapterUnitTestKit/AUTKLatencyTests.h>

@interface AUTDTExchangeAdapterLatencyTests : XCTestCase
@end

@implementation AUTDTExchangeAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterFyber class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterFyber class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterFyber class]);
}

@end
