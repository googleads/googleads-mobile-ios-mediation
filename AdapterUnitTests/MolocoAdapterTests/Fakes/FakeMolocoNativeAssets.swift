// Copyright 2024 Google LLC.
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

import Foundation
import MolocoAdapter
import MolocoSDK
import UIKit

  /// A fake implementation of MolocoNativeAdAssests that creates a FakeMolocoNativeAdAssests.
final class FakeMolocoNativeAdAssests: MolocoNativeAdAssests {
  var appIcon: UIImage? {
    return UIImage()
  }
  
  var mainImage: UIImage? {
    return UIImage()
  }
  
  var title: String = FakeAssetValues.title
  
  var description: String = FakeAssetValues.description
  
  var sponsorText: String = FakeAssetValues.sponsorText
  
  var ctaTitle: String = FakeAssetValues.ctaTitle
  
  var rating: Double = FakeAssetValues.rating
  
  var videoView: UIView? {
    UIView()
  }
}

class FakeAssetValues {
  static var title = "FakeTitle"
  static var description = "FakeDesc"
  static var sponsorText = "FakeSponsor"
  static var ctaTitle = "FakeCtaTitle"
  static var rating = 4.5
}
