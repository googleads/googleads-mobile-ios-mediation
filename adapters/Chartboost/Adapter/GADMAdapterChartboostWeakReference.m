// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterChartboostWeakReference.h"

@interface GADMAdapterChartboostWeakReference ()

/// An identifier derived from the original pointer to the object, so that equality/inequality
/// remains stable if the object is deallocated.
@property(nonatomic, readonly, strong) NSValue *uniqueID;

@end

@implementation GADMAdapterChartboostWeakReference

+ (BOOL)set:(NSSet *)set containsObject:(id)anObject {
  return [set containsObject:[[GADMAdapterChartboostWeakReference alloc] initWithObject:anObject]];
}

- (instancetype)initWithObject:(id)anObject {
  if (!anObject) {
    return nil;
  }
  self = [super init];
  if (self) {
    _weakObject = anObject;
    _uniqueID = [NSValue valueWithPointer:(__bridge const void *)anObject];
  }
  return self;
}

- (NSUInteger)hash {
  return _uniqueID.pointerValue;
}

- (BOOL)isEqual:(id)anObject {
  if ([anObject isKindOfClass:[GADMAdapterChartboostWeakReference class]]) {
    return [_uniqueID isEqual:[anObject uniqueID]];
  }
  return NO;
}

- (NSString *)description {
  id strongObject = _weakObject;
  return [NSString stringWithFormat:@"<%@: %p weakObject:%@ uniqueID:%p>",
                                    NSStringFromClass([self class]), self, strongObject,
                                    _uniqueID.pointerValue];
}

@end
