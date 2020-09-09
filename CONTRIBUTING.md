# How to Contribute

We'd love to accept your patches and contributions to this project. There are
just a few small guidelines you need to follow.

## Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement. You (or your employer) retain the copyright to your contribution;
this simply gives us permission to use and redistribute your contributions as
part of the project. Head over to <https://cla.developers.google.com/> to see
your current agreements on file or to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

## Code reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

## Best practices

There are several coding practices that are applied to all adapters, for
code readability, code consistency, and bug avoidance purposes. Please keep
these in mind when making adapter modifications:

1. Avoid nesting if statements where possible. When checking for errors,
   add a return statement to quit early.

   For example, prefer:

   ```
   if (error) {
     return;
   }
   doStuff();
   ```

   instead of:

   ```
   if (!error) {
     doStuff();
   }
   ```

1. Prefer [Dispatch](https://developer.apple.com/documentation/dispatch) (e.g.
   `dispatch_sync` for reads on collections and `dispatch_async` on writes)
   instead of `@synchronized` blocks.

1. Use instance variables instead of properties for internal variables.

1. Comment all internal variables and properties. Comments should end with
   periods and should generally be complete sentences.

1. Use nullability annotations (`nullable` or `nonnull`) on all properties
   and methods, in both header and implementation files.

1. Use wrapper C-functions for adding objects to collections such as sets,
   arrays, or dictionaries. These wrappers perform proper nil checks on
   objects before setting them, to avoid crashes on adding nil to a
   collection. See
   [GADFBUtils](https://github.com/googleads/googleads-mobile-ios-mediation/blob/master/adapters/Facebook/FacebookAdapter/GADFBUtils.m)
   for an example implementation.

1. Protect completion handlers by wrapping thme in blocks. Theese wrappers
   provide the following benefits:

   - The underlying completion block is only called once
   - The underlying completion block is deallocated once it is called

   You therefore don’t need to set the object to nil or worry about doing nil
   checks on completion handlers. This avoids a crash that could happen when
   calling a nil block.

   Here is some sample code demonstrating wrapping a
   `GADMediationRewardedLoadCompletionHandler` block:

   ```
   __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
   __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
       [handler copy];

   _adLoadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
       _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {

     // Only allow completion handler to be called once.
     if (atomic_flag_test_and_set(&completionHandlerCalled)) {
       return nil;
     }

     id<GADMediationRewardedAdEventDelegate> delegate = nil;
     if (originalCompletionHandler) {
       // Call original handler and hold on to its return value.
       delegate = originalCompletionHandler(ad, error);
     }

     // Release reference to handler. Objects retained by the handler will
     // also be released.
     originalCompletionHandler = nil;

     // Return the return value.
     return delegate;
   };
   ```

# If you can't become a contributor

If you can't become a contributor, but wish to share some code that illustrates
an issue / shows how an issue may be fixed, then you can attach your changes on
the issue tracker. We will use this code to troubleshoot the issue and fix it,
but will not use this code in the library unless the steps to submit patches
are done.
