//
//  GADMMaioInterstitialAdapter.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioInterstitialAdapter.h"
#import "GADMAdapterMaioAdsManager.h"
#import "GADMMaioConstants.h"
#import "GADMMaioError.h"

@import Maio;

@interface GADMMaioInterstitialAdapter () <MaioDelegate>

@property(nonatomic, weak) id<GADMAdNetworkConnector> interstitialAdConnector;

@property(nonatomic, strong) NSString *mediaId;
@property(nonatomic, strong) NSString *zoneId;

@end

@implementation GADMMaioInterstitialAdapter

#pragma mark - GADMAdNetworkAdapter

/// Returns a version string for the adapter. It can be any string that uniquely
/// identifies the version of your adapter. For example, "1.0", or simply a date
/// such as "20110915".
+ (NSString *)adapterVersion {
  return kGADMMaioAdapterVersion;
}

/// The extras class that is used to specify additional parameters for a request
/// to this ad network. Returns Nil if the network does not have extra settings
/// for publishers to send.
+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

/// Designated initializer. Implementing classes can and should keep the
/// connector in an instance variable. However you must never retain the
/// connector, as doing so will create a circular reference and cause memory
/// leaks.
- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }

  self = [super init];
  if (self) {
    self.interstitialAdConnector = connector;
  }
  return self;
}

/// Asks the adapter to initiate a banner ad request. The adapter does not need
/// to return anything. The assumption is that the adapter will start an
/// asynchronous ad fetch over the network. Your adapter may act as a delegate
/// to your SDK to listen to callbacks. If your SDK does not support the given
/// ad size, or does not support banner ads, call back to the adapter:didFailAd:
/// method of the connector.
- (void)getBannerWithSize:(GADAdSize)adSize {
  // not supported bunner
  NSString *description = [NSString stringWithFormat:@"%@ is not supported banner.", self.class];
  [self.interstitialAdConnector adapter:self
                              didFailAd:[GADMMaioError errorWithDescription:description]];
}

/// Asks the adapter to initiate an interstitial ad request. The adapter does
/// not need to return anything. The assumption is that the adapter will start
/// an asynchronous ad fetch over the network. Your adapter may act as a
/// delegate to your SDK to listen to callbacks. If your SDK does not support
/// interstitials, call back to the adapter:didFailInterstitial: method of the
/// connector.
- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = self.interstitialAdConnector;
  NSDictionary *param = [strongConnector credentials];
  if (!param) {
    return;
  }
  self.mediaId = param[kGADMMaioAdapterMediaId];
  self.zoneId = param[kGADMMaioAdapterZoneId];
  GADMAdapterMaioAdsManager *adManager =
      [GADMAdapterMaioAdsManager getMaioAdsManagerByMediaId:self.mediaId];

  // MaioInstance生成時にテストモードかどうかを指定する
  [adManager setAdTestMode:strongConnector.testMode];

  GADMMaioInterstitialAdapter *__weak weakSelf = self;
  [adManager initializeMaioSDKWithCompletionHandler:^(NSError *error) {
    if (error) {
      [weakSelf.interstitialAdConnector adapter:weakSelf didFailAd:error];
    } else {
      // 生成済みのinstanceを得た場合、testモードを上書きする必要がある
      [adManager setAdTestMode:weakSelf.interstitialAdConnector.testMode];
      NSError *error = [adManager loadAdForZoneId:weakSelf.zoneId delegate:weakSelf];
      if (error) {
        [self.interstitialAdConnector adapter:self didFailAd:error];
      }
    }
  }];
}

/// When called, the adapter must remove itself as a delegate or notification
/// observer from the underlying ad network SDK. You should also call this
/// method in your adapter dealloc, so when your adapter goes away, your SDK
/// will not call a freed object. This function should be idempotent and should
/// not crash regardless of when or how many times the method is called.
- (void)stopBeingDelegate {
}

/// Some ad transition types may cause issues with particular Ad SDKs. The
/// adapter may decide whether the given animation type is OK. Defaults to YES.
- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  // default value
  return YES;
}

/// Present an interstitial using the supplied UIViewController, by calling
/// presentViewController:animated:completion:.
///
/// Your interstitial should not immediately present itself when it is received.
/// Instead, you should wait until this method is called on your adapter to
/// present the interstitial.
///
/// Make sure to call adapterWillPresentInterstitial: on the connector when the
/// interstitial is about to be presented, and adapterWillDismissInterstitial:
/// and adapterDidDismissInterstitial: when the interstitial is being dismissed.
- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [self.interstitialAdConnector adapterWillPresentInterstitial:self];
  GADMAdapterMaioAdsManager *adManager =
      [GADMAdapterMaioAdsManager getMaioAdsManagerByMediaId:self.mediaId];
  [adManager showAdForZoneId:self.zoneId rootViewController:rootViewController];
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
  if (!newValue) return;

  [self.interstitialAdConnector adapterDidReceiveInterstitial:self];
}

/**
 *  広告が再生される直前に呼ばれます。
 *  最初の再生開始の直前にのみ呼ばれ、リプレイ再生の直前には呼ばれません。
 *
 *  @param zoneId  広告が表示されるゾーンの識別子
 */
- (void)maioWillStartAd:(NSString *)zoneId {
  // NOOP
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
  // NOOP
}

/**
 *  広告がクリックされ、ストアや外部リンクへ遷移した時に呼ばれます。
 *
 *  @param zoneId  広告がクリックされたゾーンの識別子
 */
- (void)maioDidClickAd:(NSString *)zoneId {
  [self.interstitialAdConnector adapterDidGetAdClick:self];
  [self.interstitialAdConnector adapterWillLeaveApplication:self];
}

/**
 *  広告が閉じられた際に呼ばれます。
 *
 *  @param zoneId  広告が閉じられたゾーンの識別子
 */
- (void)maioDidCloseAd:(NSString *)zoneId {
  [self.interstitialAdConnector adapterWillDismissInterstitial:self];
  [self.interstitialAdConnector adapterDidDismissInterstitial:self];
}

/**
 *  SDK でエラーが生じた際に呼ばれます。
 *
 *  @param zoneId  エラーに関連するゾーンの識別子
 *  @param reason   エラーの理由を示す列挙値
 */
- (void)maioDidFail:(NSString *)zoneId reason:(MaioFailReason)reason {
  NSString *error = [GADMMaioError stringFromFailReason:reason];
  [self.interstitialAdConnector adapter:self didFailAd:[GADMMaioError errorWithDescription:error]];
}

#pragma mark - private methods

@end
