// Copyright 2023 Google LLC
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

#import <FiveAd/FiveAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADMediationAdapterLine.h"
#import "GADMediationAdapterLineExtras.h"

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMediationAdapterLineErrorWithCodeAndDescription(
    GADMediationAdapterLineErrorCode code, NSString *_Nonnull description);

/// Returns an NSError with Five Ad error code |code|.
NSError *_Nonnull GADMediationAdapterLineErrorWithFiveAdErrorCode(FADErrorCode code);

/// Logs with GADMediationAdapterLine Prefix.
void GADMediationAdapterLineLog(NSString *_Nonnull format, ...);

/// Adds |object| to |set| if |object| is not nil.
void GADMediationAdapterLineMutableSetAddObject(NSMutableSet *_Nullable set,
                                                NSObject *_Nonnull object);

/// Returns the slot ID from the credentials. It may return nil if it encounters an error.
NSString *_Nullable GADMediationAdapterLineSlotID(GADMediationCredentials *_Nonnull credentials,
                                                  NSError *_Nullable *_Nonnull errorPtr);

/// Registers Five Ad SDK with the credentials array. If it was previously registered, then it will
/// just return.
NSError *_Nullable GADMediationAdapterLineRegisterFiveAd(
    NSArray<GADMediationCredentials *> *_Nonnull credentialsArray);

/// Returns whether ad should start with aduio.
/// - It returns true when the extra's adAudio is GADMediationAdapterLineAdAudioUnmuted.
/// - It returns false when the extra's adAudio is GADMediationAdapterLineAdAudioMuted.
/// - If the extras is nil or the the extra's adAudio is GADMediationAdapterLineAdAudioUnset, its
/// return value depends on GADMobileAds.sharedInstance.applicationMuted.
BOOL GADMediationAdapterLineShouldEnableAudio(GADExtras *_Nullable extras);

/// Returns FADAdLoader for the registered FADConfig. If FADConfig hasn't been registered, then it
/// returns nil.
FADAdLoader *_Nullable GADMediationAdapterLineFADAdLoaderForRegisteredConfig(
    NSError *_Nullable *_Nullable errorPtr);

/// Watermark string from ad configuraiton.
NSString *_Nullable GADMediationAdapterLineWatermarkStringFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfiguration);


#ifdef DEBUG
/// Unregister FiveAd setup in the adapter. This must be used only in test mode, if needed.
void GADMediationAdapterLineUnregisterFiveAd(void);
#endif
