# How to run unit tests for an adapter?

Internally, Google automatically runs unit tests for an adapter for every pull request and the pull request can be merged only if the unit tests pass. So, we recommend code contributors to run these unit tests on their pull request changes and make any changes needed so that the unit tests pass.

Also, we recommend contributors to add unit tests for new code. Thank you for contributing!

This document describes how a code contributor can run the unit tests on their local Mac.

On your Mac terminal, under the `googleads-mobile-ios-mediation/AdapterUnitTests/` directory, run:

- `export ADAPTER_TARGETS="AdapterTargetName"`

Note: To find the adapter target name, please go to the [Podfile](https://github.com/googleads/googleads-mobile-ios-mediation/blob/main/AdapterUnitTests/Podfile) and search for the adapter name. For example, for the IronSource adapter, the target name can be found at [this line](https://github.com/googleads/googleads-mobile-ios-mediation/blob/fd2bcd277847d6538931b8cc021e43f52d58a73d/AdapterUnitTests/Podfile#L144). So, you would run `export ADAPTER_TARGETS="IronSourceAdapter"`.

And then run:

- `pod install`

And then open on XCode the `AdapterUnitTests.xcworkspace` that would have been just created.

And then, you can run the unit tests for the adapter from the XCode UI.

Once you are done, you can clean the project by running:

- `bash pod_deintegrate.sh`
