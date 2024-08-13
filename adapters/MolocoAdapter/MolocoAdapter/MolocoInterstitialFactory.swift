import Foundation
import MolocoSDK

/// Protocol for a factory of Moloco interstitial ads.
public protocol MolocoInterstitialFactory {

  @available(iOS 13.0, *)
  func createInterstitial(for adUnit: String, delegate: any MolocoSDK.MolocoInterstitialDelegate)
    -> (any MolocoSDK.MolocoInterstitial)?
}
