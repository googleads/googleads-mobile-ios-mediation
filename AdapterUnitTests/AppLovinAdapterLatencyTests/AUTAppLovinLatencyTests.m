#import "GADMediationAdapterAppLovin.h"

#import <XCTest/XCTest.h>
#import <AdapterUnitTestKit/AUTKLatencyTests.h>

#import "GADMAdapterAppLovinConstant.h"

@interface AUTAppLovinLatencyTests : XCTestCase
@end

@implementation AUTAppLovinLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterAppLovin class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterAppLovin class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterAppLovin class]);
}

@end
