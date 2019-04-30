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

#import "GADMAdapterMaioRewardedAd.h"
#import "GADMAdapterMaioAdsManager.h"
#import "GADMMaioConstants.h"
#import "GADMMaioError.h"

@interface GADMAdapterMaioRewardedAd () <MaioDelegate>

@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, copy) NSString *mediaId;
@property(nonatomic, copy) NSString *zoneId;

@end

@implementation GADMAdapterMaioRewardedAd

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.completionHandler = completionHandler;
  _mediaId = adConfiguration.credentials.settings[kGADMMaioAdapterMediaId];
  _zoneId = adConfiguration.credentials.settings[kGADMMaioAdapterZoneId];

  if (!self.mediaId) {
    NSError *error = [GADMMaioError errorWithDescription:@"Media ID cannot be nil."];
    completionHandler(nil, error);
    return;
  }

  GADMAdapterMaioAdsManager *adManager =
      [GADMAdapterMaioAdsManager getMaioAdsManagerByMediaId:_mediaId];
  // MaioInstance生成時にテストモードかどうかを指定する
  [Maio setAdTestMode:adConfiguration.isTestRequest];

  GADMAdapterMaioRewardedAd *__weak weakSelf = self;
  [adManager initializeMaioSDKWithCompletionHandler:^(NSError *error) {
    if (error) {
      self.completionHandler(nil, error);
    } else {
      // 生成済みのinstanceを得た場合、testモードを上書きする必要がある
      [adManager setAdTestMode:adConfiguration.isTestRequest];
      NSError *error = [adManager loadAdForZoneId:weakSelf.zoneId delegate:self];
      if (error) {
        self.completionHandler(nil, error);
      }
    }
  }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  GADMAdapterMaioAdsManager *adManager =
      [GADMAdapterMaioAdsManager getMaioAdsManagerByMediaId:_mediaId];
  [adManager showAdForZoneId:self.zoneId rootViewController:viewController];
}

#pragma mark - MaioDelegate

/**
 *  全てのゾーンの広告表示準備が完了したら呼ばれます。
 */
- (void)maioDidInitialize {
  // noop
}

/**
 *  広告の配信可能状態が変更されたら呼ばれます。
 *
 *  @param zoneId   広告の配信可能状態が変更されたゾーンの識別子
 *  @param newValue 変更後のゾーンの状態。YES なら配信可能
 */
- (void)maioDidChangeCanShow:(NSString *)zoneId newValue:(BOOL)newValue {
  if (!newValue) {
    return;
  }
  self.adEventDelegate = self.completionHandler(self, nil);
}

/**
 *  広告が再生される直前に呼ばれます。
 *  最初の再生開始の直前にのみ呼ばれ、リプレイ再生の直前には呼ばれません。
 *
 *  @param zoneId  広告が表示されるゾーンの識別子
 */
- (void)maioWillStartAd:(NSString *)zoneId {
  [self.adEventDelegate didStartVideo];
}

/**
 *  広告の再生が終了したら呼ばれます。
 *  最初の再生終了時にのみ呼ばれ、リプレイ再生の終了時には呼ばれません。
 *
 *  @param zoneId  広告を表示したゾーンの識別子
 *  @param playtime 動画の再生時間（秒）
 *  @param skipped  動画がスキップされていたら YES、それ以外なら NO
 *  @param rewardParam
 * ゾーンがリワード型に設定されている場合、予め管理画面にて設定してある任意の文字列パラメータが渡されます。それ以外の場合は
 * nil
 */
- (void)maioDidFinishAd:(NSString *)zoneId
               playtime:(NSInteger)playtime
                skipped:(BOOL)skipped
            rewardParam:(NSString *)rewardParam {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = self.adEventDelegate;
  [strongAdEventDelegate didEndVideo];
  if (!skipped) {
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:rewardParam ?: @""
                                                     rewardAmount:[NSDecimalNumber one]];
    [strongAdEventDelegate didRewardUserWithReward:reward];
  }
}

/**
 *  広告がクリックされ、ストアや外部リンクへ遷移した時に呼ばれます。
 *
 *  @param zoneId  広告を表示したゾーンの識別子
 */
- (void)maioDidClickAd:(NSString *)zoneId {
  [self.adEventDelegate reportClick];
}

/**
 *  広告が閉じられた際に呼ばれます。
 *
 *  @param zoneId  広告を表示したゾーンの識別子
 */
- (void)maioDidCloseAd:(NSString *)zoneId {
  [self.adEventDelegate didDismissFullScreenView];
}

/**
 *  SDK でエラーが生じた際に呼ばれます。
 *
 *  @param zoneId  エラーに関連するゾーンの識別子
 *  @param reason   エラーの理由を示す列挙値
 */
- (void)maioDidFail:(NSString *)zoneId reason:(MaioFailReason)reason {
  // 再生エラー等、ロードと無関係なエラーは通知しない。
  NSError *errorWithDescription =
      [GADMMaioError errorWithDescription:[GADMMaioError stringFromFailReason:reason]];
  self.completionHandler(nil, errorWithDescription);
}

@end
