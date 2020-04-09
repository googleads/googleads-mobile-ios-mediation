// Copyright 2019 Google LLC
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

#import "GADMAdapterVungleBannerRequest.h"

@interface GADMAdapterVungleBannerRequest ()

@property(nonatomic, copy) NSString *placementID;
@property(nonatomic, copy) NSString *uniquePubRequestID;

@end

@implementation GADMAdapterVungleBannerRequest

- (nonnull instancetype)initWithPlacementID:(nonnull NSString *)placementID
                         uniquePubRequestID:(nullable NSString *)uniquePubRequestID {
  self = [super init];
  if (self) {
    _placementID = [placementID copy];
    _uniquePubRequestID = [uniquePubRequestID copy];
  }
  return self;
}

- (nonnull instancetype)init {
  return [self initWithPlacementID:@"" uniquePubRequestID:nil];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  GADMAdapterVungleBannerRequest *copy = [[[self class] alloc] init];
  if (copy) {
    copy.placementID = [self.placementID copyWithZone:zone];
    copy.uniquePubRequestID = [self.uniquePubRequestID copyWithZone:zone];
  }
  return copy;
}

- (BOOL)isEqualToBannerRequest:(GADMAdapterVungleBannerRequest *)bannerRequest {
  if (!bannerRequest) {
    return NO;
  }

  BOOL haveEqualPlacementIDs = [self.placementID isEqualToString:bannerRequest.placementID];
  BOOL haveEqualUniquePubRequestIDs = [self.uniquePubRequestID isEqualToString:bannerRequest.uniquePubRequestID];

  return haveEqualPlacementIDs && haveEqualUniquePubRequestIDs;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[GADMAdapterVungleBannerRequest class]]) {
    return NO;
  }

  return [self isEqualToBannerRequest:(GADMAdapterVungleBannerRequest *)object];
}

- (NSUInteger)hash {
  return [self.placementID hash] ^ [self.uniquePubRequestID hash];
}

@end
