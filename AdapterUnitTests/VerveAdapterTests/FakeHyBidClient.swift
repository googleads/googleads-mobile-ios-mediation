import Foundation
import GoogleMobileAds
import HyBid

@testable import VerveAdapter

final class FakeHyBidClient: NSObject, HybidClient {

  var shouldInitializationSucceed = true
  var shouldGetBannerSizeSucceed = true
  var shouldAdLoadSucceed = true
  var shouldPresentationSucceed = true
  var shouldNativeAssetFetchSucceed = true

  var bannerDelegate: HyBidAdViewDelegate?
  var interstitialDelegate: HyBidInterstitialAdDelegate?
  var rewardedAdDelegate: HyBidRewardedAdDelegate?
  var nativeDelegate: HyBidNativeAdDelegate?

  func version() -> String {
    return "1.2.3"
  }

  func initialize(
    with appToken: String,
    COPPA: Bool?,
    TFUA: Bool?,
    completionHandler: @escaping (VerveAdapterError?) -> Void
  ) {
    if shouldInitializationSucceed {
      completionHandler(nil)
    } else {
      completionHandler(
        VerveAdapterError(
          errorCode: .failedToInitializeHyBidSDK, description: "Failed to initialize."))
    }
  }

  func collectSignals() -> String {
    return "signals"
  }

  func isValidBannerSize(_ size: CGSize) -> Bool {
    return shouldGetBannerSizeSucceed
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    size: CGSize,
    delegate: Any
  ) throws(VerveAdapterError) {
    guard let delegate = delegate as? HyBidAdViewDelegate else { return }
    bannerDelegate = delegate

    if shouldAdLoadSucceed {
      delegate.adViewDidLoad(HyBidAdView(size: .size_320x50))
    } else {
      delegate.adView(
        HyBidAdView(size: .size_320x50),
        didFailWithError: NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
    }
  }

  func loadRTBInterstitialAd(
    with bidResponse: String,
    delegate: Any
  ) {
    guard let delegate = delegate as? HyBidInterstitialAdDelegate else { return }
    interstitialDelegate = delegate

    if shouldAdLoadSucceed {
      delegate.interstitialDidLoad()
    } else {
      delegate.interstitialDidFailWithError(
        NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
    }
  }

  func presentInterstitialAd(from viewController: UIViewController) throws(VerveAdapterError) {
    if !shouldPresentationSucceed {
      throw VerveAdapterError(errorCode: .notReadyForPresentation, description: "")
    }
  }

  func loadRTBRewardedAd(with bidResponse: String, delegate: Any) {
    guard let delegate = delegate as? HyBidRewardedAdDelegate else { return }
    rewardedAdDelegate = delegate

    if shouldAdLoadSucceed {
      delegate.rewardedDidLoad()
    } else {
      delegate.rewardedDidFailWithError(
        NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
    }
  }

  func presentRewardedAd(from viewController: UIViewController) throws(VerveAdapterError) {
    if !shouldPresentationSucceed {
      throw VerveAdapterError(errorCode: .notReadyForPresentation, description: "")
    }
  }

  func loadRTBNativeAd(with bidResponse: String, delegate: Any) {
    guard let delegate = delegate as? HyBidNativeAdLoaderDelegate else { return }
    nativeDelegate = delegate as? HyBidNativeAdDelegate

    if shouldAdLoadSucceed {
      delegate.nativeLoaderDidLoad(with: HyBidNativeAd())
    } else {
      delegate.nativeLoaderDidFailWithError(
        NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
    }
  }

  func fetchAssets(
    for nativeAd: Any,
    delegate: Any
  ) {
    guard let nativeAd = nativeAd as? HyBidNativeAd,
      let delegate = delegate as? HyBidNativeAdFetchDelegate
    else { return }

    if shouldNativeAssetFetchSucceed {
      delegate.nativeAdDidFinishFetching(nativeAd)
    } else {
      delegate.nativeAd(
        nativeAd,
        didFailFetchingWithError: NSError(
          domain: "com.test.verveadapter", code: 12345, userInfo: nil))
    }
  }

}
