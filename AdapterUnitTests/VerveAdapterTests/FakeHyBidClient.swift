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

  var interstitialDelegate: HyBidInterstitialAdDelegate?
  var rewardedAdDelegate: HyBidRewardedAdDelegate?

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

  func getBannerSize(_ size: CGSize) throws(VerveAdapterError) -> HyBidAdSize {
    if shouldGetBannerSizeSucceed {
      return .size_320x100
    }
    throw VerveAdapterError(errorCode: .unsupportedBannerSize, description: "")
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    size: CGSize,
    delegate: any HyBidAdViewDelegate
  ) throws(VerveAdapterError) {
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
    delegate: any HyBidInterstitialAdDelegate
  ) {
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

  func loadRTBRewardedAd(with bidResponse: String, delegate: any HyBidRewardedAdDelegate) {
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

  func loadRTBNativeAd(with bidResponse: String, delegate: any HyBidNativeAdLoaderDelegate) {
    if shouldAdLoadSucceed {
      delegate.nativeLoaderDidLoad(with: HyBidNativeAd())
    } else {
      delegate.nativeLoaderDidFailWithError(
        NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
    }
  }

  func fetchAssets(
    for nativeAd: HyBidNativeAd,
    delegate: any HyBidNativeAdFetchDelegate
  ) {
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
