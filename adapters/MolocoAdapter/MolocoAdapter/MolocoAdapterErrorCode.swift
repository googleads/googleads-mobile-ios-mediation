import Foundation

/// Error codes for different possible errors that can occur in Moloco adapter.
///
/// Make sure the adapter error code does not conflict with partner's error code.
public enum MolocoAdapterErrorCode: Int {
  case adServingNotSupported = 101
  case invalidAppId = 102
  case invalidAdUnitId = 103
}
