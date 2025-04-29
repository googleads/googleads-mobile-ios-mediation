//
//  MolocoNativeFactory.swift
//  MolocoAdapter
//
//  Created by Vishal Dhiman on 1/28/25.
//

import Foundation
import MolocoSDK

/// Protocol for a factory of Moloco Native ads.
public protocol MolocoNativeFactory {

  @MainActor
  @available(iOS 13.0, *)
  func createNativeAd(for adUnit: String, delegate: MolocoNativeAdDelegate, watermarkData: Data?)
    -> MolocoNativeAd?

}
