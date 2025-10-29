#import "GADInMobiExtras.h"

#import <CoreLocation/CoreLocation.h>
#import <InMobiSDK/InMobiSDK-Swift.h>
#import <XCTest/XCTest.h>

@interface AUTInMobiNetworkExtrasTest : XCTestCase
@end

@implementation AUTInMobiNetworkExtrasTest

- (void)testSetLocationWithCity {
  NSString *expectedCity = @"city";
  NSString *expectedState = @"state";
  NSString *expectedCountry = @"country";

  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setLocationWithCity:expectedCity state:expectedState country:expectedCountry];

  XCTAssertEqualObjects(extras.city, expectedCity);
  XCTAssertEqualObjects(extras.state, expectedState);
  XCTAssertEqualObjects(extras.country, expectedCountry);
}

- (void)testSetLocation {
  CLLocationManager *manager = [[CLLocationManager alloc] init];
  CLLocation *expectedLocation = manager.location;

  GADInMobiExtras *extras = [[GADInMobiExtras alloc] init];
  [extras setLocation:expectedLocation];

  XCTAssertEqualObjects(extras.location, expectedLocation);
}

@end
