## Moloco iOS Mediation Adapter Changelog

#### Next version
- First version. Has bidding support for banner, interstitial and rewarded formats.
- Updated some protocol methods to use MainActor and wrapped the code that needs to run on the main thread with DispatchQueue.main.async to suppress the "Main actor-isolated instance method" warning, which will be treated as an error starting in Swift 6.