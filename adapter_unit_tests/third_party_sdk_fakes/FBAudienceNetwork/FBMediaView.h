#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBMediaViewDelegate;
@class FBNativeAd;

/**
 * The fake FBMediaView interface. This header contains subset of properties and methods of actual
 * public header.
 */

@interface FBMediaView : UIView

/**
 * The FBMediaViewDelegate delegate object.
 */
@property(nonatomic, weak, nullable) id<FBMediaViewDelegate> delegate;

@end

/**
 * The methods declared by the FBMediaViewDelegate protocol allow the adopting delegate to respond
 * to messages from the FBMediaView class and thus respond to operations such as whether the media
 * content has been loaded.
 */
@protocol FBMediaViewDelegate <NSObject>

@optional

/**
 * Sent when a FBMediaView has been successfully loaded.
 *
 * @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewDidLoad:(FBMediaView *)mediaView;

/**
 * Sent just before a FBMediaView will enter the fullscreen layout.
 *
 * @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewWillEnterFullscreen:(FBMediaView *)mediaView;

/**
 * Sent after a FBMediaView has exited the fullscreen layout.
 *
 * @param mediaView An FBMediaView object sending the message.
 */
- (void)mediaViewDidExitFullscreen:(FBMediaView *)mediaView;

/**
 * Sent when a FBMediaView has changed the playback volume of a video ad.
 *
 * @param mediaView A FBMediaView object sending the message.
 * @param volume The current ad video volume (after the volume change).
 */
- (void)mediaView:(FBMediaView *)mediaView videoVolumeDidChange:(float)volume;

/**
 * Sent after a video ad in a FBMediaView enters a paused state.
 *
 * @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewVideoDidPause:(FBMediaView *)mediaView;

/**
 * Sent after a video ad in FBMediaView enters a playing state.
 *
 * @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewVideoDidPlay:(FBMediaView *)mediaView;

/**
 * Sent when a video ad in a FBMediaView reaches the end of playback.
 *
 * @param mediaView A FBMediaView object sending the message.
 */
- (void)mediaViewVideoDidComplete:(FBMediaView *)mediaView;

@end

NS_ASSUME_NONNULL_END
