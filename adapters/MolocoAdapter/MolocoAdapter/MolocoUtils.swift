import Foundation
import GoogleMobileAds

/// Contains uitlity methods for Moloco adapter.
final class MolocoUtils {

  static func error(
    code: MolocoAdapterErrorCode, description: String
  ) -> NSError {
    let userInfo = ["description": description]
    return NSError(
      domain: MolocoConstants.adapterErrorDomain, code: code.rawValue, userInfo: userInfo)
  }

  static func log(_ logMessage: String) {
    NSLog("GADMediationAdapterMoloco - \(logMessage)")
  }

  static func getAdUnitId(from adConfiguration: GADMediationAdConfiguration) -> String? {
    adConfiguration.isTestRequest
      ? MolocoConstants.molocoTestAdUnitName
      : adConfiguration.credentials.settings[MolocoConstants.adUnitIdKey] as? String
  }
}
