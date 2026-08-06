#import "third_party/objective_c/gma_sdk_mediation/adapter_unit_tests/third_party_sdk_fakes/FBAudienceNetwork/FBMediaView.h"

@implementation FBMediaView

- (void)playVideo {
  if ([_delegate respondsToSelector:@selector(mediaViewVideoDidPlay:)]) {
    [_delegate mediaViewVideoDidPlay:self];
  }
}

- (void)pauseVideo {
  if ([_delegate respondsToSelector:@selector(mediaViewVideoDidPause:)]) {
    [_delegate mediaViewVideoDidPause:self];
  }
}

- (void)completeVideo {
  if ([_delegate respondsToSelector:@selector(mediaViewVideoDidComplete:)]) {
    [_delegate mediaViewVideoDidComplete:self];
  }
}

- (void)enterFullscreen {
  if ([_delegate respondsToSelector:@selector(mediaViewWillEnterFullscreen:)]) {
    [_delegate mediaViewWillEnterFullscreen:self];
  }
}

- (void)exitFullscreen {
  if ([_delegate respondsToSelector:@selector(mediaViewDidExitFullscreen:)]) {
    [_delegate mediaViewDidExitFullscreen:self];
  }
}

- (void)changeVolume:(float)volume {
  if ([_delegate respondsToSelector:@selector(mediaView:videoVolumeDidChange:)]) {
    [_delegate mediaView:self videoVolumeDidChange:volume];
  }
}

- (void)loadVideo {
  if ([_delegate respondsToSelector:@selector(mediaViewDidLoad:)]) {
    [_delegate mediaViewDidLoad:self];
  }
}

@end
