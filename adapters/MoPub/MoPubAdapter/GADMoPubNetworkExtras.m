#import "GADMoPubNetworkExtras.h"
#import "GADMAdapterMoPubConstants.h"

@implementation GADMoPubNetworkExtras

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    // Default values of each extra.
    _privacyIconSize = DEFAULT_MOPUB_PRIVACY_ICON_SIZE;
    _minimumBannerSize = CGSizeZero;
  }
  return self;
}

@end
