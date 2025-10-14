#import "AUTTestUtils.h"

void AUTAssertEqualVersion(GADVersionNumber version1, GADVersionNumber version2) {
  XCTAssertEqual(version1.majorVersion, version2.majorVersion);
  XCTAssertEqual(version1.minorVersion, version2.minorVersion);
  XCTAssertEqual(version1.patchVersion, version2.patchVersion);
}

id _Nullable AUTValueForKeyIfIsKindOfClass(id _Nonnull object, NSString *_Nonnull aKey,
                                           Class _Nonnull aClass) {
  id value;
  @try {
    value = [object valueForKey:aKey];
    if (![value isKindOfClass:aClass]) {
      NSString *classString = NSStringFromClass([value class]);
      NSString *exceptionName = @"ValueIsNotKindOfClass";
      NSString *exceptionReason = [NSString
          stringWithFormat:
              @"For the key `%@`, the object `%@` has a value which is `%@` class, not `%@` class.",
              aKey, object, classString, NSStringFromClass(aClass)];
      @throw [NSException exceptionWithName:exceptionName reason:exceptionReason userInfo:nil];
    }
  } @catch (NSException *exception) {
    XCTFail(@"AUTValueForKeyIfIsKindOfClass failed for reason: %@", exception.reason);
  }
  return value;
}
