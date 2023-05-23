#import "AUTKAdConfiguration.h"

@implementation AUTKMediationCredentials
@synthesize format;
@synthesize settings;
@end

@implementation AUTKMediationServerConfiguration
@synthesize credentials;
@end

@implementation AUTKMediationBannerAdConfiguration
@synthesize bidResponse;
@synthesize topViewController;
@synthesize credentials;
@synthesize watermark;
@synthesize extras;
@synthesize childDirectedTreatment;
@synthesize isTestRequest;
@synthesize adSize;
@end

@implementation AUTKMediationInterstitialAdConfiguration
@synthesize bidResponse;
@synthesize topViewController;
@synthesize credentials;
@synthesize watermark;
@synthesize extras;
@synthesize childDirectedTreatment;
@synthesize isTestRequest;
@end

@implementation AUTKMediationRewardedAdConfiguration
@synthesize bidResponse;
@synthesize topViewController;
@synthesize credentials;
@synthesize watermark;
@synthesize extras;
@synthesize childDirectedTreatment;
@synthesize isTestRequest;
@end

@implementation AUTKMediationNativeAdConfiguration
@synthesize bidResponse;
@synthesize topViewController;
@synthesize credentials;
@synthesize watermark;
@synthesize extras;
@synthesize childDirectedTreatment;
@synthesize isTestRequest;
@synthesize options;
@end
