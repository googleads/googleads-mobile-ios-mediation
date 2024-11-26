#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "GADMAdapterIronSourceUtils.h"
#import "GADMAdapterIronSourceConstants.h"
#import <IronSource/IronSource.h>

@interface AUTIronSourceRtbBannerAdTests : XCTestCase

@property(nonatomic, strong) id mockAdConfiguration;
@property(nonatomic, strong) GADMAdapterIronSourceRtbBannerAd *adapter;
@property(nonatomic, strong) id mockBannerAdEventDelegate;
@property(nonatomic, strong) id mockBannerAd;
@property (nonatomic, copy) GADMediationBannerLoadCompletionHandler BannerAdLoadCompletionHandler;
@end

@implementation AUTIronSourceRtbBannerAdTests

- (void)setUp {
    [super setUp];
    self.adapter = [[GADMAdapterIronSourceRtbBannerAd alloc] init];
    // Create a mock for the GADMediationBannerAdEventDelegate protocol
    self.mockBannerAdEventDelegate = OCMProtocolMock(@protocol(GADMediationBannerAdEventDelegate));
    //self.adapter.bannerAdEventDelegate = self.mockBannerAdEventDelegate;
    self.mockBannerAd = OCMClassMock([ISABannerAdView class]);

}

- (void)testBannerAdDidLoad {
    // Given
    __block BOOL completionHandlerCalled = NO;
    GADMediationBannerLoadCompletionHandler completionHandler = ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> ad, NSError *error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        completionHandlerCalled = YES;
        return self.mockBannerAdEventDelegate;
    };
    
    self.adapter.bannerAdLoadCompletionHandler = completionHandler;
    OCMExpect([self.mockBannerAd setDelegate:self.adapter]);

    // When
    [self.adapter bannerAdDidLoad:self.mockBannerAd];
    
    // Then
    XCTAssertTrue(completionHandlerCalled, @"Completion handler should be called");
    XCTAssertEqual(self.adapter.bannerAdEventDelegate, self.mockBannerAdEventDelegate, @"Banner ad event delegate should be set correctly");
    XCTAssertEqual(self.adapter.view, self.mockBannerAd, @"The Banner ad should be set correctly.");
    OCMVerifyAll(self.mockBannerAd);
}

- (void)testBannerAdDidLoadWithoutLoadCompletionHandler {
    // When
    [self.adapter bannerAdDidLoad:self.mockBannerAd];
    
    // Then
    XCTAssertNil(self.adapter.biddingISABannerAd, @"The Banner ad should remain nil");
    XCTAssertNil(self.adapter.bannerAdEventDelegate, @"Banner ad event delegate should remain nil");
}

// Test case for rewardedAdDidFailToLoadWithError when completion handler is set
- (void)testBannerAdDidFailToLoadWithError {
    // Given
    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain" code:1 userInfo:nil];

    GADMediationBannerLoadCompletionHandler mockCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> ad, NSError *error) {
        // Then
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, testError);
        return nil;
    };

    self.adapter.bannerAdLoadCompletionHandler = mockCompletionHandler;

    // When
    [self.adapter bannerAdDidFailToLoadWithError:testError];
}

- (void)testBannerAdDidShow {
    // Given
    GADMediationBannerLoadCompletionHandler completionHandler = ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> ad, NSError *error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        return self.mockBannerAdEventDelegate;
    };
    self.adapter.bannerAdLoadCompletionHandler = completionHandler;
    [self.adapter bannerAdDidLoad:self.mockBannerAd];
    
    // When
    [self.adapter bannerAdViewDidShow:self.mockBannerAd];

    // Then
    OCMExpect([self.adapter.bannerAdEventDelegate reportImpression]);
}

- (void)testBannerAdDidShowWithNilDelegate {
    // When
    [self.adapter bannerAdViewDidShow:self.mockBannerAd];

    // Then
    XCTAssertTrue(true);
}

- (void)testBannerAdDidClick {
    // Given
    GADMediationBannerLoadCompletionHandler completionHandler = ^id<GADMediationBannerAdEventDelegate>(id<GADMediationBannerAd> ad, NSError *error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        return self.mockBannerAdEventDelegate;
    };
    
    self.adapter.bannerAdLoadCompletionHandler = completionHandler;
    
    [self.adapter bannerAdDidLoad:self.mockBannerAd];
    
    // When
    [self.adapter bannerAdViewDidClick:self.mockBannerAd];

    // Then
    OCMExpect([self.adapter.bannerAdEventDelegate reportClick]);
}

- (void)testBannerAdDidClicWithNilDelegate {
    // When
    [self.adapter bannerAdViewDidClick:self.mockBannerAd];

    // Then
    XCTAssertTrue(true);
}

@end
