// Copyright 2017 Google LLC
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

#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@implementation GADMAdapterMyTargetExtras {
  NSMutableDictionary<NSString *, NSString *> *_Nullable _parameters;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    _isDebugMode = YES;
  }
  return self;
}

- (void)setParameter:(nullable NSString *)parameter forKey:(nonnull NSString *)key {
  if (!key) return;
  @synchronized(self) {
    if (!_parameters) {
      _parameters = [NSMutableDictionary<NSString *, NSString *> new];
    }
    if (parameter) {
      GADMAdapterMyTargetMutableDictionarySetObjectForKey(_parameters, key, parameter.copy);
    } else {
      GADMAdapterMyTargetMutableDictionaryRemoveObjectForKey(_parameters, key);
    }
  }
}

- (nullable NSDictionary<NSString *, NSString *> *)parameters {
  @synchronized(self) {
    return (_parameters && _parameters.count > 0) ? _parameters.copy : nil;
  }
}

@end
