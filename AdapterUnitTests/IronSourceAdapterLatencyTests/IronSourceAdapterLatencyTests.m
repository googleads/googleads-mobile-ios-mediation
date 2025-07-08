#import "GADMediationAdapterIronSource.h"

#import <AdapterUnitTestKit/AUTKLatencyTests.h>
#import <XCTest/XCTest.h>

@interface AUTIronSourceAdapterLatencyTests : XCTestCase
@end

@implementation AUTIronSourceAdapterLatencyTests

- (void)testAdapterVersionLatency {
  AUTKTestAdapterVersionLatency([GADMediationAdapterIronSource class]);
}

- (void)testAdSDKVersionLatency {
  AUTKTestAdSDKVersionLatency([GADMediationAdapterIronSource class]);
  AUTKTestAdSDKVersionLatency([GADMediationAdapterIronSource class]);
}

@end
