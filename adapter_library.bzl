"""Common functions for creating mediation adapter libraries."""

def adapter_library(deps):
    """Generates objc library target for GMA SDK adapter in current package.

    Args:
      deps: additional dependencies specific to the adapter.
    """

    DIR_NAME = native.package_name().split("/")[-1]

    # Targets containing the Facebook Adapter source, to be used in an objc_library target.
    HEADERS = native.glob(["Public/Headers/*.h"])

    SOURCES = native.glob([
        "%s/**/*.m" % DIR_NAME,
        "%s/**/*.h" % DIR_NAME,
    ])

    # These list comprehensions are stripping the directory paths from the headers
    # and implementation files. We do this because all the  #import statements in
    # the adapter are relative to the same folder.
    HEADER_BASENAMES = [f.split("/")[-1] for f in HEADERS]

    SOURCE_BASENAMES = [f.split("/")[-1] for f in SOURCES]

    # A target containing all the header files for the adapter in one folder.
    native.genrule(
        name = "flat_headers",
        srcs = HEADERS,
        outs = HEADER_BASENAMES,
        cmd = "cp $(SRCS) $(@D)",
    )

    # A target containing all the implementation files for the adapter in one folder.
    native.genrule(
        name = "flat_sources",
        srcs = SOURCES,
        outs = SOURCE_BASENAMES,
        cmd = "cp $(SRCS) $(@D)",
    )

    # The Third party SDK / GoogleMobileAds adapter.
    native.objc_library(
        name = "adapter_library",
        testonly = 1,
        srcs = [":flat_sources"],
        hdrs = [":flat_headers"],
        copts = [
            "-Wno-error=incompatible-pointer-types",
        ],
        deps = [
            "//third_party/GoogleMobileAdsIOS:google_mobile_ads_framework_current",
        ] + deps,
    )
