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
static NSString *const GADMAdapterIronSourceMediationName = @"AdMob";
static NSString *const GADMAdapterIronSourceAdapterVersion = @"7.2.2.1.0";
static NSString *const GADMIronSourceDefaultInstanceId = @"0";
static NSString *const GADMAdapterIronSourceInternalVersion = @"310";

// IronSource parameters keys.
static NSString *const GADMAdapterIronSourceAppKey = @"appKey";
static NSString *const GADMAdapterIronSourceIsTestEnabled = @"isTestEnabled";
static NSString *const GADMAdapterIronSourceInstanceId = @"instanceId";

// IronSource instance states.
typedef NSString *InstanceState NS_STRING_ENUM;
static InstanceState const GADMAdapterIronSourceInstanceStateLocked = @"LOCKED";
static InstanceState const GADMAdapterIronSourceInstanceStateStart = @"START";
static InstanceState const GADMAdapterIronSourceInstanceStateCanLoad = @"CANLOAD";

// IronSource mediation adapter error domain.
static NSString *const GADMAdapterIronSourceErrorDomain = @"com.google.mediation.IronSource";
