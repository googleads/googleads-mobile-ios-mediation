#import "GADMAdapterMoPubUtils.h"

void GADMAdapterMoPubMutableArrayAddObject(NSMutableArray *_Nullable array,
                                           NSObject *_Nonnull object) {
  if (object) {
    [array addObject:object];  // Allow pattern.
  }
}

void GADMAdapterMoPubMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

void GADMAdapterMoPubMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                             id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key]; // Allow pattern.
  }
}

void GADMAdapterMoPubMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                      id<NSCopying> _Nullable key,
                                                      id _Nullable value) {
  if (value && key) {
    dictionary[key] = value; // Allow pattern.
  }
}
