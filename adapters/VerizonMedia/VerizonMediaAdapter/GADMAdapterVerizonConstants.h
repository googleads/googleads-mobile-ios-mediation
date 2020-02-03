// Copyright 2019 Google LLC.
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

#import <Foundation/Foundation.h>

/// Verizon Media mediation network adapter version.
static NSString *const _Nonnull kGADMAdapterVerizonMediaVersion = @"1.3.1.0";

/// Verizon Media mediation adapter error domain.
static NSString *const _Nonnull kGADMAdapterVerizonMediaErrorDomain =
    @"com.google.mediation.verizonmedia";

/// Verizon Media mediation adapter legacy position server parameter key.
static NSString *const _Nonnull kGADNexagePosition = @"position";

/// Verizon Media mediation adapter legacy dcn server parameter key.
static NSString *const _Nonnull kGADNexageDCN = @"dcn";

/// Verizon Media mediation adapter position server parameter key.
static NSString *const _Nonnull kGADMAdapterVerizonMediaPosition = @"placement_id";

/// Verizon Media mediation adapter dcn server parameter key.
static NSString *const _Nonnull kGADMAdapterVerizonMediaDCN = @"site_id";

/// Verizon Media mediation adapter site ID key.
static NSString *const _Nonnull kGADMAdapterVerizonMediaSiteID = @"VerizonSiteID";
