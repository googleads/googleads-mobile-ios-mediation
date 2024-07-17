import Foundation
import MolocoSDK

/// Protocol for Moloco SDK initiazation.
public protocol MolocoInitializer {

  @available(iOS 13.0, *)
  func initialize(
    initParams: MolocoSDK.MolocoInitParams, completion: ((Bool, (any Error)?) -> Void)?)

  func isInitialized() -> Bool
}
