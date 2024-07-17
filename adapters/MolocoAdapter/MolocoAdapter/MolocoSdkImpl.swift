import MolocoSDK

/// Implementation of protocols that calls corresponding Moloco SDK methods.
class MolocoSdkImpl: MolocoInitializer, MolocoInterstitialFactory {

  @available(iOS 13.0, *)
  func initialize(
    initParams: MolocoSDK.MolocoInitParams, completion: ((Bool, (any Error)?) -> Void)?
  ) {
    Moloco.shared.initialize(initParams: initParams, completion: completion)
  }

  func isInitialized() -> Bool {
    return Moloco.shared.state.isInitialized
  }

  @MainActor @available(iOS 13.0, *)
  func createInterstitial(for adUnit: String, delegate: (any MolocoSDK.MolocoInterstitialDelegate))
    -> (any MolocoSDK.MolocoInterstitial)?
  {
    Moloco.shared.createInterstitial(for: adUnit, delegate: delegate)
  }

}
