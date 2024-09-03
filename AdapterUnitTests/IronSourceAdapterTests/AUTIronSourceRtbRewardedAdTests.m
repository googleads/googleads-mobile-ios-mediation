//
//  AUTIronSourceRtbRewardedAdTests.m
//  IronSourceAdapterTests
//
//  Created by Jonathan Benedek on 29/08/2024.
//

// GADMAdapterIronSourceRtbRewardedAdTests.m
// ISMedAdaptersTests

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "GADMAdapterIronSourceRtbRewardedAd.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMAdapterIronSourceConstants.h"
#import <OCMock/OCMock.h>

@interface AUTIronSourceRtbRewardedAdTests : XCTestCase
typedef void (^GADMediationAdapterSetUpCompletionBlock)(NSError *_Nullable error);
@property (nonatomic, strong) GADMAdapterIronSourceRtbRewardedAd *rewardedAd;
@property (nonatomic, strong) GADMediationAdapterIronSource *mediationAdapter;
@property (nonatomic, strong) GADMediationRewardedAdConfiguration *mockAdConfiguration;
@property (nonatomic, strong) GADMediationServerConfiguration *mockInitConfiguration;


@property (nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property (nonatomic, copy) GADMediationAdapterSetUpCompletionBlock initCompletionHandler;
@property(nonatomic, strong) GADMAdapterIronSourceRtbRewardedAd *adapter;
@property(nonatomic, strong) id mockBiddingISARewardedAd;
@property(nonatomic, strong) id mockRewardedAdEventDelegate;
@property (nonatomic, strong) id mockCredentials;
@end

@implementation AUTIronSourceRtbRewardedAdTests

- (void)setUp {
    [super setUp];
    self.rewardedAd = [[GADMAdapterIronSourceRtbRewardedAd alloc] init];
    self.adapter = [[GADMAdapterIronSourceRtbRewardedAd alloc] init];
    self.mockBiddingISARewardedAd = OCMClassMock([ISARewardedAd class]);
    self.mockRewardedAdEventDelegate = OCMProtocolMock(@protocol(GADMediationRewardedAdEventDelegate));
    self.adapter.rewardedAdEventDelegate = self.mockRewardedAdEventDelegate;
}

- (void)tearDown {
    self.rewardedAd = nil;
    self.mockAdConfiguration = nil;
    self.mockCredentials = nil;
    self.completionHandler = nil;
    self.adapter.rewardedAdLoadCompletionHandler = nil;
    self.adapter.biddingISARewardedAd = nil;
    [super tearDown];
}

- (void)testLoadRewardedAdForConfigurationWithInvalidApplicationKey {
    // Arrange
    id mockAdConfiguration = OCMClassMock([GADMediationRewardedAdConfiguration class]);
    id mockCredentials = OCMClassMock([GADMediationCredentials class]);

    // Create a dictionary with invalid credentials
    NSDictionary *credentials = @{ @"invalid_key": @"invalid_value" };
    

    // Stub the `credentials` and `settings` methods
    OCMStub([mockAdConfiguration credentials]).andReturn(mockCredentials);
    NSDictionary *expectedSettings = @{ @"key1": @"value1", @"key2": @"value2" };
    OCMStub([mockCredentials settings]).andReturn(expectedSettings);
    
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Completion handler called"];
    
    // Define the completion handler block
    GADMediationRewardedLoadCompletionHandler completionHandler = ^id<GADMediationRewardedAdEventDelegate> (id<GADMediationRewardedAd> _Nullable ad, NSError * _Nullable error) {
        // Assert that the completion handler is called with the correct error
        XCTAssertNil(ad);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, @"com.google.mediation.IronSource");
        XCTAssertEqual(error.code, GADMAdapterIronSourceErrorInvalidServerParameters);
        [completionExpectation fulfill];
        return nil;
    };
    
    // Act
    [self.adapter loadRewardedAdForConfiguration:mockAdConfiguration completionHandler:completionHandler];
    
    // Wait for the completion handler to be called
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRewardedAdDidLoad {
    // Given
    GADMediationRewardedLoadCompletionHandler completionHandler = ^id<GADMediationRewardedAdEventDelegate>(id<GADMediationRewardedAd> ad, NSError *error) {
        XCTAssertNotNil(ad);
        XCTAssertNil(error);
        return nil;
    };
    
    self.adapter.rewardedAdLoadCompletionHandler = completionHandler;
    
    // When
    [self.adapter rewardedAdDidLoad:self.mockBiddingISARewardedAd];
    
    // Then
    XCTAssertEqual(self.adapter.biddingISARewardedAd, self.mockBiddingISARewardedAd, @"The rewarded ad should be set correctly.");
}

- (void)testRewardedAdDidLoadWithoutRewardedAdLoadCompletionHandler {
    // When
    [self.adapter rewardedAdDidLoad:self.mockBiddingISARewardedAd];
    
    // Then
    XCTAssertEqual(self.adapter.rewardedAdLoadCompletionHandler, nil, @"The rewarded ad should be nil.");
}

// Test case for rewardedAdDidFailToLoadWithError when completion handler is set
- (void)testRewardedAdDidFailToLoadWithError {
    // Given
    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain" code:1 userInfo:nil];

    // Create a mock completion handler
    GADMediationRewardedLoadCompletionHandler mockCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(id<GADMediationRewardedAd> ad, NSError *error) {
        // Then
        XCTAssertNil(ad);
        XCTAssertEqualObjects(error, testError);
        return nil;
    };

    // Assign the mock completion handler to the adapter
    self.adapter.rewardedAdLoadCompletionHandler = mockCompletionHandler;

    // When
    [self.adapter rewardedAdDidFailToLoadWithError:testError];
}

- (void)testRewardedAdDidShow {
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);

    // Set expectations
    OCMExpect([self.mockRewardedAdEventDelegate willPresentFullScreenView]);
    OCMExpect([self.mockRewardedAdEventDelegate didStartVideo]);
    OCMExpect([self.mockRewardedAdEventDelegate reportImpression]);

    // Call the method to test
    [self.adapter rewardedAdDidShow:mockRewardedAd];

    // Verify all expected methods were called
    OCMVerifyAll(self.mockRewardedAdEventDelegate);
}

- (void)testRewardedAdDidShowWithNilDelegate {
    // Given
    self.adapter.rewardedAdEventDelegate = nil;
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);

    //Then
    XCTAssertNoThrow([self.adapter rewardedAdDidShow:mockRewardedAd]);
}

- (void)testRewardedAdDidFailToShowWithError {
    // Given
    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain" code:1 userInfo:nil];
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);
    
    OCMExpect([self.mockRewardedAdEventDelegate didFailToPresentWithError:testError]);

    // When
    [self.adapter rewardedAd:mockRewardedAd didFailToShowWithError:testError];

    // Then
    OCMVerifyAll(self.mockRewardedAdEventDelegate);
}

- (void)testRewardedAdDidFailToShowWithErrorWithNilDelegate {
    // Set the delegate to nil
    self.adapter.rewardedAdEventDelegate = nil;
    NSError *testError = [NSError errorWithDomain:@"TestErrorDomain" code:1 userInfo:nil];
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);

    // Call the method to test
    [self.adapter rewardedAd:mockRewardedAd didFailToShowWithError:testError];

    // Since the delegate is nil, no further action is necessary
    XCTAssertTrue(true); // Reaching this point without crashing means success
}

- (void)testRewardedAdDidClick {
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);

    // Set expectation for the delegate method
    OCMExpect([self.mockRewardedAdEventDelegate reportClick]);

    // Call the method to test
    [self.adapter rewardedAdDidClick:mockRewardedAd];

    // Verify all expectations
    OCMVerifyAll(self.mockRewardedAdEventDelegate);
}

// Test case for rewardedAdDidClick: when event delegate is nil
- (void)testRewardedAdDidClickWithNilDelegate {
    // Set the delegate to nil
    self.adapter.rewardedAdEventDelegate = nil;
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);

    // Call the method to test
    [self.adapter rewardedAdDidClick:mockRewardedAd];

    // Since the delegate is nil, no further action is necessary
    XCTAssertTrue(true); // Reaching this point without crashing means success
}

- (void)testRewardedAdDidDismiss {
    // Given
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);
    
    OCMExpect([self.mockRewardedAdEventDelegate willDismissFullScreenView]);
    OCMExpect([self.mockRewardedAdEventDelegate didDismissFullScreenView]);
    
    // When
    [self.adapter rewardedAdDidDismiss:mockRewardedAd];

    // Then

    OCMVerifyAll(self.mockRewardedAdEventDelegate);
}

// Test case for rewardedAdDidDismiss: when event delegate is nil
- (void)testRewardedAdDidDismissWithNilDelegate {
    // Given
    self.adapter.rewardedAdEventDelegate = nil;
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);

    // When
    [self.adapter rewardedAdDidDismiss:mockRewardedAd];

    // Then
    XCTAssertTrue(true);
}

// Test case for rewardedAdDidUserEarnReward: when event delegate is set
- (void)testRewardedAdDidUserEarnReward {
    // Given
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);

    OCMExpect([self.mockRewardedAdEventDelegate didRewardUser]);
    OCMExpect([self.mockRewardedAdEventDelegate didEndVideo]);
    
    // When
    [self.adapter rewardedAdDidUserEarnReward:mockRewardedAd];

    // Then
    OCMVerifyAll(self.mockRewardedAdEventDelegate);
}

// Test case for rewardedAdDidUserEarnReward: when event delegate is nil
- (void)testRewardedAdDidUserEarnRewardWithNilDelegate {
    // Given
    self.adapter.rewardedAdEventDelegate = nil;
    ISARewardedAd *mockRewardedAd = OCMClassMock([ISARewardedAd class]);

    // When
    [self.adapter rewardedAdDidUserEarnReward:mockRewardedAd];

    // Then
    XCTAssertTrue(true); // Reaching this point without crashing means success
}

@end
