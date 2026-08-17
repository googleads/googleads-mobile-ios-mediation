#import <Foundation/Foundation.h>

/// Account ID for InMobi.
static NSString *_Nonnull const AUTInMobiAccountID = @"12345";

/// Placement ID for InMobi.
static NSString *_Nonnull const AUTInMobiPlacementID = @"67890";

/// Keywords for InMobi.
static NSString *_Nonnull const AUTInMobiKeywords = @"InMobiKeywords";

/// Sample watermark string for testing watermark data forwarding.
static NSString *_Nonnull const AUTInMobiTestWatermarkString =
    @"iVBORw0KGgoAAAANSUhEUgAAACsAAAAWBAMAAACrl3iAAAAABlBMVEUAAAD+"
    @"AciWmZzWAAAAAnRSTlMAApidrBQAAAB/SURBVBjTbZDREcAwCEJ1A/"
    @"aftlVQvF79SPQk+kLEfySDiatAd98TgKtWRPruszolA5Ottp+96ah39qlm984XyQQoN3ekmUNLej1IgSm5PDQuDdK/"
    @"I4M+SW5z2JhLAr3DdVAivjj/wrpYiR2kkmjHQXFo9vVZ2u9sYJYsiWiZPYZ9BdmQ8Y2lAAAAAElFTkSuQmCC";

/**
 * Mocks GADMAdapterInMobiInitializer.sharedInstance to return a fresh instance.
 * Returns the class mock for GADMAdapterInMobiInitializer.
 */
id _Nonnull AUTMockGADMAdapterInMobiInitializer(void);

/**
 * Mocks GADMAdapterInMobiDelegateManager.sharedInstance to return a fresh instance.
 * Returns the class mock for GADMAdapterInMobiDelegateManager.
 */
id _Nonnull AUTMockGADMAdapterInMobiDelegateManager(void);

/**
 * Mocks IMSdk initWithAccountID:consentDictionary:andCompletionHandler: to call completion handler
 * immediately with nil. Returns the class mock for IMSdk.
 */
id _Nonnull AUTMockIMSDKInit(void);

/**
 * Returns a native ad content string using the parameters.
 */
NSString *_Nonnull AUTNativeAdContentString(NSString *_Nullable landingPageURLString,
                                            NSString *_Nullable iconURLString,
                                            NSString *_Nullable price);