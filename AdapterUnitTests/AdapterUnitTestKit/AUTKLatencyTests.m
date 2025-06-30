#import "AUTKLatencyTests.h"

#import "AUTKConstants.h"

void AUTKTestAdapterVersionLatency(Class<GADMediationAdapter> adapterClass) {
  CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
  [adapterClass adapterVersion];
  CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
  NSTimeInterval latency = endTime - startTime;
  NSLog(@"%@ adapter version latency: %f ms", adapterClass, latency * 1000);
  XCTAssertTrue(latency <= AUTKSyncMethodTimeout);
}

void AUTKTestAdSDKVersionLatency(Class<GADMediationAdapter> adapterClass) {
  CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
  [adapterClass adSDKVersion];
  CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
  NSTimeInterval latency = endTime - startTime;
  NSLog(@"%@ ad SDK version latency: %f ms", adapterClass, latency * 1000);
  XCTAssertTrue(latency <= AUTKSyncMethodTimeout);
}
