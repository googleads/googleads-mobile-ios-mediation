import Foundation

/// Error codes for different possible errors that can occur in Moloco adapter.
// TODO: add more error code, if needed. Make sure the adapter error code does not conflict with partner's error code.
enum MolocoAdapterErrorCode: Int {
  /// Missing server parameters.
  case invalidServerParameters = 101
}
