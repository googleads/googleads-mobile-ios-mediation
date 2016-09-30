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

@import Foundation;

/// A weak reference to an object, with stable equality so that it can be stored in collections such
/// as NSSet.
@interface GADMAdapterChartboostWeakReference : NSObject

/// The referenced object.
@property(nonatomic, readonly, weak) id weakObject;

/// Returns whether a GADMAdapterChartboostWeakReference to |anObject| exists in |set|.
+ (BOOL)set:(NSSet *)set containsObject:(id)anObject;

/// Designated initializer. Returns a weak reference to the given object.
- (instancetype)initWithObject:(id)anObject NS_DESIGNATED_INITIALIZER;

/// Unavailable. Use initWithObject:.
- (instancetype)init NS_UNAVAILABLE;

@end
