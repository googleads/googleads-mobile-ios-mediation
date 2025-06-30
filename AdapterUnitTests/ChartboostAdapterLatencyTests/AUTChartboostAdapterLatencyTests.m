#import "GADMediationAdapterChartboost.h"

#import <XCTest/XCTest.h>
#import <AdapterUnitTestKit/AUTKLatencyTests.h>

@interface AUTChartboostAdapterLatencyTests : XCTestCase
@end

@implementation AUTChartboostAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterChartboost class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterChartboost class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterChartboost class]);
}

@end
