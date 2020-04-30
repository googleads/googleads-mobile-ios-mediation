#import <Foundation/Foundation.h>
#import "GADMediationAdapterMoPub.h"

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterMoPubMutableArrayAddObject(NSMutableArray *_Nullable array,
                                           NSObject *_Nonnull object);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterMoPubMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key);

/// Sets |value| for |key| in mapTable if |value| is not nil.
void GADMAdapterMoPubMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                             id<NSCopying> _Nullable key, id _Nullable value);

/// Sets |value| for |key| in |dictionary| if |value| is not nil.
void GADMAdapterMoPubMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                      id<NSCopying> _Nullable key,
                                                      id _Nullable value);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMoPubErrorWithCodeAndDescription(GADMoPubErrorCode *_Nonnull code,
                                                      NSString *_Nonnull description);
