// Copyright 2019 Google Inc.
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

// IronSource internal reporting const.
static NSString *const kGADMAdapterIronSourceMediationName = @"AdMob";
static NSString *const kGADMAdapterIronSourceAdapterVersion = @"6.8.4.1";
static NSString *const kGADMIronSourceDefaultInstanceId = @"0";
static NSString *const kGADMAdapterIronSourceInternalVersion = @"310";

// IronSource parameters keys.
static NSString *const kGADMAdapterIronSourceAppKey = @"appKey";
static NSString *const kGADMAdapterIronSourceIsTestEnabled = @"isTestEnabled";
static NSString *const kGADMAdapterIronSourceInstanceId = @"instanceId";

// IronSource instance states
typedef NSString *InstanceState NS_STRING_ENUM;
static InstanceState const kInstanceStateLocked = @"LOCKED";
static InstanceState const kInstanceStateStart = @"START";
static InstanceState const kInstanceStateCanLoad = @"CANLOAD";
