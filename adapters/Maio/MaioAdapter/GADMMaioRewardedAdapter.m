//
//  GADMMaioRewardedAdapter.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioRewardedAdapter.h"
#import "GADMMaioConstants.h"
#import "GADMMaioDelegateAggregate.h"
#import "GADMMaioError.h"
#import "GADMMaioMaioInstanceRepository.h"
#import "GADMMaioParameter.h"

@interface GADMMaioRewardedAdapter () <MaioDelegate>

/// Connector from Google Mobile Ads SDK to receive reward-based video ad
/// configurations.
@property(nonatomic, weak) id<GADMRewardBasedVideoAdNetworkConnector>
    rewardBasedVideoAdConnector;

@property(nonatomic, strong) NSString *mediaId;
@property(nonatomic, strong) NSString *zoneId;

@property(nonatomic) BOOL isLoading;

@end

@implementation GADMMaioRewardedAdapter

#pragma mark - GADMRewardBasedVideoAdNetworkAdapter

/// Returns a version string for the adapter. It can be any string that uniquely
/// identifies the version of your adapter. For example, "1.0", or simply a date
/// such as "20110915".
+ (NSString *)adapterVersion {
  return GADMMaioAdapterVersion;
}

/// The extras class that is used to specify additional parameters for a request
/// to this ad network. Returns Nil if the network does not have extra settings
/// for publishers to send.
+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

/// Returns an initialized instance of the adapter. The adapter must only
/// maintain a weak reference to the provided connector.
- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
    (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  if (!connector)
    return nil;

  self = [super init];
  if (self) {
    _rewardBasedVideoAdConnector = connector;
  }
  return self;
}

/// Tells the adapter to set up reward based video ads. The adapter should
/// notify the Google Mobile Ads SDK whether set up has succeeded or failed
/// using callbacks provided in the connector. When set up fails, the Google
/// Mobile Ads SDK may try to set up the adapter again.
- (void)setUp {
  GADMMaioMaioInstanceRepository *repository =
      [GADMMaioMaioInstanceRepository new];
  // Custom Event パラメータ（mediaId, zoneId）をロード。
  GADMMaioParameter *parameter =
      [self.class loadCustomEventParametersServerFromConnector:
                      _rewardBasedVideoAdConnector];
  if (!parameter.mediaId) {
    NSError *error =
        [GADMMaioError errorWithDescription:@"Media ID cannot be nil."];
    [_rewardBasedVideoAdConnector adapter:self
        didFailToSetUpRewardBasedVideoAdWithError:error];
    return;
  }
  _mediaId = parameter.mediaId;
  _zoneId = parameter.zoneId;

  [[GADMMaioDelegateAggregate sharedInstance].delegates addObject:self];
  if (![repository isInitializedWithMediaId:_mediaId]) {
    [Maio setAdTestMode:_rewardBasedVideoAdConnector.testMode];
    [repository addMaioInstance:
                    [Maio startWithNonDefaultMediaId:_mediaId
                                            delegate:[GADMMaioDelegateAggregate
                                                         sharedInstance]]];
  } else {
    [_rewardBasedVideoAdConnector adapterDidSetUpRewardBasedVideoAd:self];
  }
}

/// Tells the adapter to request a reward based video ad. This method is called
/// after the adapter has been set up. The adapter should notify the Google
/// Mobile Ads SDK if the request succeeds or fails using callbacks provided in
/// the connector.
- (void)requestRewardBasedVideoAd {
  GADMMaioMaioInstanceRepository *repository =
      [GADMMaioMaioInstanceRepository new];
  MaioInstance *maioInstance = [repository maioInstanceByMediaId:_mediaId];
  self.isLoading = YES;

  if ([repository isInitializedWithMediaId:_mediaId]) {
    // ゾーンID が変更（直前とは異なる AdUnitID
    // を使用）されるケースがあるので、Custom Event パラメータ（mediaId,
    // zoneId）を再ロード。
    GADMMaioParameter *parameter =
        [self.class loadCustomEventParametersServerFromConnector:
                        _rewardBasedVideoAdConnector];
    _zoneId = parameter.zoneId;

    if ([maioInstance canShowAtZoneId:_zoneId]) {
      [self maioDidChangeCanShow:_zoneId newValue:YES];
    } else {
      NSString *description = [NSString
          stringWithFormat:@"%@ failed to receive reward based video ad.",
                           NSStringFromClass([Maio class])];
      [self notifyThatDidFailToLoadAdWwithDescription:description];
    }
  }
}

/// Tells the adapter to present the reward based video ad with the provided
/// view controller. This method is only called after the adapter successfully
/// requested an ad.
- (void)presentRewardBasedVideoAdWithRootViewController:
    (UIViewController *)viewController {
  GADMMaioMaioInstanceRepository *repository =
      [GADMMaioMaioInstanceRepository new];
  MaioInstance *maioInstance = [repository maioInstanceByMediaId:_mediaId];

  // GADMAdapterUnity.m の実装に倣って、ここで adapterDidOpenRewardBasedVideoAd
  // を呼ぶ。
  // https://github.com/googleads/googleads-mobile-ios-mediation/blob/02b9d81728ac74b20fe8c0759685bb255eb72e09/adapters/Unity/Source/GADMAdapterUnity.m
  [_rewardBasedVideoAdConnector adapterDidOpenRewardBasedVideoAd:self];

  [maioInstance showAtZoneId:_zoneId vc:viewController];
}

/// Tells the adapter to remove itself as a delegate or notification observer
/// from the underlying ad network SDK.
- (void)stopBeingDelegate {
  [[GADMMaioDelegateAggregate sharedInstance].delegates removeObject:self];
}

#pragma mark - MaioDelegate

/**
 *  全てのゾーンの広告表示準備が完了したら呼ばれます。
 */
- (void)maioDidInitialize {
  [[GADMMaioMaioInstanceRepository new] setInitialized:YES mediaId:_mediaId];
  [_rewardBasedVideoAdConnector adapterDidSetUpRewardBasedVideoAd:self];
}

/**
 *  広告の配信可能状態が変更されたら呼ばれます。
 *
 *  @param zoneId   広告の配信可能状態が変更されたゾーンの識別子
 *  @param newValue 変更後のゾーンの状態。YES なら配信可能
 */
- (void)maioDidChangeCanShow:(NSString *)zoneId newValue:(BOOL)newValue {
  if (!newValue)
    return;
  if (_zoneId && ![_zoneId isEqualToString:zoneId])
    return;

  if (_isLoading) {
    [_rewardBasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
    _isLoading = NO;
  }
}

/**
 *  広告が再生される直前に呼ばれます。
 *  最初の再生開始の直前にのみ呼ばれ、リプレイ再生の直前には呼ばれません。
 *
 *  @param zoneId  広告が表示されるゾーンの識別子
 */
- (void)maioWillStartAd:(NSString *)zoneId {
  if (_zoneId && ![_zoneId isEqualToString:zoneId])
    return;

  [_rewardBasedVideoAdConnector adapterDidStartPlayingRewardBasedVideoAd:self];
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
  if (_zoneId && ![_zoneId isEqualToString:zoneId])
    return;
  [_rewardBasedVideoAdConnector adapterDidCompletePlayingRewardBasedVideoAd:self];
  if (!skipped) {
    GADAdReward *reward =
        [[GADAdReward alloc] initWithRewardType:rewardParam ?: @""
                                   rewardAmount:[NSDecimalNumber one]];
    [_rewardBasedVideoAdConnector adapter:self didRewardUserWithReward:reward];
  }
}

/**
 *  広告がクリックされ、ストアや外部リンクへ遷移した時に呼ばれます。
 *
 *  @param zoneId  広告を表示したゾーンの識別子
 */
- (void)maioDidClickAd:(NSString *)zoneId {
  if (_zoneId && ![_zoneId isEqualToString:zoneId])
    return;

  [_rewardBasedVideoAdConnector adapterDidGetAdClick:self];
  [_rewardBasedVideoAdConnector adapterWillLeaveApplication:self];
}

/**
 *  広告が閉じられた際に呼ばれます。
 *
 *  @param zoneId  広告を表示したゾーンの識別子
 */
- (void)maioDidCloseAd:(NSString *)zoneId {
  if (_zoneId && ![_zoneId isEqualToString:zoneId])
    return;

  [_rewardBasedVideoAdConnector adapterDidCloseRewardBasedVideoAd:self];
}

/**
 *  SDK でエラーが生じた際に呼ばれます。
 *
 *  @param zoneId  エラーに関連するゾーンの識別子
 *  @param reason   エラーの理由を示す列挙値
 */
- (void)maioDidFail:(NSString *)zoneId reason:(MaioFailReason)reason {
  if (_zoneId && ![_zoneId isEqualToString:zoneId])
    return;

  // 再生エラー等、ロードと無関係なエラーは通知しない。
  [self notifyThatDidFailToLoadAdWwithDescription:
            [GADMMaioError stringFromFailReason:reason]];
}

#pragma mark - private methods

/**
 *  Maio 用の Custom Event パラメータをロードします。
 */
+ (id)loadCustomEventParametersServerFromConnector:
    (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  NSString *mediaId = [connector credentials][GADMMaioAdapterMediaId];
  NSString *zoneId = [connector credentials][GADMMaioAdapterZoneId];
  NSLog(@"mediaId: %@ zoneId: %@", mediaId, zoneId);

  return [[GADMMaioParameter alloc] initWithMediaId:mediaId zoneId:zoneId];
}

/**
 *  動画広告のロードに失敗した事をコネクタに通知します。
 */
- (void)notifyThatDidFailToLoadAdWwithDescription:(NSString *)description {
  if (_isLoading) {
    NSError *errorWithDescription =
        [GADMMaioError errorWithDescription:description];
    if (_rewardBasedVideoAdConnector) {
      [_rewardBasedVideoAdConnector adapter:self
          didFailToLoadRewardBasedVideoAdwithError:errorWithDescription];
    }
    _isLoading = NO;
  }
}

@end
