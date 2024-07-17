import Foundation
import GoogleMobileAds

/// Loads native ads on Moloco ads SDK.
final class NativeAdLoader: NSObject {

  /// The native ad configuration.
  private let adConfiguration: GADMediationNativeAdConfiguration

  /// The ad event delegate which is used to report native related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: GADMediationNativeAdEventDelegate?

  init(
    adConfiguration: GADMediationNativeAdConfiguration,
    loadCompletionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    super.init()
  }

  func loadAd() {
    // TODO: implement and make sure to call |nativeAdLoadCompletionHandler| after loading an ad.
  }

}

// MARK: - GADMediationNativeAd

extension NativeAdLoader: GADMediationNativeAd {

  // TODO: implement computed properties and methods below. Implement more optional methods from |GADMediationNativeAd|, if needed.

  var headline: String? {
    return nil
  }

  var images: [GADNativeAdImage]? {
    return nil
  }

  var body: String? {
    return nil
  }

  var icon: GADNativeAdImage? {
    return nil
  }

  var callToAction: String? {
    return nil
  }

  var starRating: NSDecimalNumber? {
    return nil
  }

  var store: String? {
    return nil
  }

  var price: String? {
    return nil
  }

  var advertiser: String? {
    return nil
  }

  var extraAssets: [String: Any]? {
    return nil
  }

  var hasVideoContent: Bool {
    // TODO: implement
    return true
  }

  func handlesUserClicks() -> Bool {
    // TODO: implement
    return true
  }

  func handlesUserImpressions() -> Bool {
    // TODO: implement
    return true
  }

}

// MARK: - <OtherProtocol>
// TODO: extend and implement any other protocol, if any.
