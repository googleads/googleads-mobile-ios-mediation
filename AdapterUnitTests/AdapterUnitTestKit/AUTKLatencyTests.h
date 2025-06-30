#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

/// Test retrieving adapter version latency. If it exceeds `AUTKSyncMethodTimeout` then treat it as
/// failure.
void AUTKTestAdapterVersionLatency(Class<GADMediationAdapter> adapterClass);

/// Test retrieving ad SDK version latency. If it exceeds `AUTKSyncMethodTimeout` then treat it as
/// failure.
void AUTKTestAdSDKVersionLatency(Class<GADMediationAdapter> adapterClass);

NS_ASSUME_NONNULL_END
