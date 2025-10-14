#import "AUTInMobiUtils.h"

#import <XCTest/XCTest.h>

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>

#import <OCMock/OCMock.h>

#import "GADMAdapterInMobiDelegateManager.h"
#import "GADMAdapterInMobiInitializer.h"
#import "NativeAdKeys.h"

void AUTMockGADMAdapterInMobiInitializer() {
  id mockInitializer = OCMClassMock([GADMAdapterInMobiInitializer class]);
  GADMAdapterInMobiInitializer *initializer = [[GADMAdapterInMobiInitializer alloc] init];
  OCMStub([mockInitializer sharedInstance]).andReturn(initializer);

  id mockManager = OCMClassMock([GADMAdapterInMobiDelegateManager class]);
  GADMAdapterInMobiDelegateManager *manager = [[GADMAdapterInMobiDelegateManager alloc] init];
  OCMStub([mockManager sharedInstance]).andReturn(manager);
}

void AUTMockIMSDKInit() {
  id IMSDKMock = OCMClassMock([IMSdk class]);
  OCMStub(ClassMethod([IMSDKMock initWithAccountID:OCMOCK_ANY
                                 consentDictionary:OCMOCK_ANY
                              andCompletionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^completionBlock)(NSError *_Nullable);
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(nil);
      });
}

NSString *_Nonnull AUTNativeAdContentString(NSString *_Nullable landingPageURLString,
                                            NSString *_Nullable iconURLString,
                                            NSString *_Nullable price) {
  NSMutableDictionary<NSString *, id> *contentDictionary = [[NSMutableDictionary alloc] init];
  if (landingPageURLString) {
    [contentDictionary setValue:landingPageURLString forKey:LANDING_URL];
  }
  if (iconURLString) {
    [contentDictionary setValue:@{URL : iconURLString} forKey:ICON];
  }
  if (price) {
    [contentDictionary setValue:price forKey:PRICE];
  }
  NSError *error = nil;
  NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDictionary
                                                        options:0
                                                          error:&error];
  if (error) {
    XCTFail(@"Failed to serialize the content dictionary to content string.");
  }
  return [[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding];
}
