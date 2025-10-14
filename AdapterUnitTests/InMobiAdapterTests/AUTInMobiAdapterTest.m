#import "GADMAdapterInMobi.h"

#import <XCTest/XCTest.h>

@interface AUTInMobiAdapterTest : XCTestCase
@end

@implementation AUTInMobiAdapterTest

- (void)testDoesNotConformToGADMAdNetowrkAdapterProtocol {
  GADMAdapterInMobi *adapter = [[GADMAdapterInMobi alloc] init];
  XCTAssertFalse([adapter conformsToProtocol:@protocol(GADMAdNetworkAdapter)]);
}

- (void)testMainAdapterClass {
  SEL mainAdapterClassSelector = NSSelectorFromString(@"mainAdapterClass");
  XCTAssertTrue([GADMAdapterInMobi respondsToSelector:mainAdapterClassSelector]);

  Class adapterClass = [GADMAdapterInMobi class];
  IMP imp = [adapterClass methodForSelector:mainAdapterClassSelector];
  Class (*func)(id, SEL) = (void *)imp;
  Class mainAdapterClass = func(adapterClass, mainAdapterClassSelector);
  id mainAdapter = [[mainAdapterClass alloc] init];
  XCTAssertTrue([mainAdapter conformsToProtocol:@protocol(GADMediationAdapter)]);
}

@end
