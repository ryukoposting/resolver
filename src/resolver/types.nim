import std/uri

type
  Version* = object ##\
    ## Represents a version conforming with Semver.
    ##
    ## A Semver version has the form:
    ## ```
    ## <major>.<minor>.<patch>[-[preReleaseTags.]...][+[buildMetadata.]...]
    ## ```
    ## 
    ## For example, this `Version` represents the version string
    ## `1.2.3-alpha.4+ABCDEFG.linux`:
    ## 
    ## ```nim
    ## let ver = Version(
    ##   major: 1
    ##   minor: 2,
    ##   patch: 3,
    ##   preReleaseTags: @["alpha", "4"],
    ##   buildMetadata: @["ABCDEFG", "linux"]
    ## )
    ## ```
    ## 
    major*, minor*, patch*: uint
    preReleaseTags*, buildMetadata*: seq[string]

  VersionRuleKind* = enum
    vrEqual,
    vrNotEqual,
    vrGreaterOrEqual,
    vrLesserOrEqual,
    vrBackwardsCompat,
    vrOptimisticBackwardsCompat,
    vrAnd,
    vrOr

  VersionRule* = ref object ##\
    ## Represents a rule that filters versions. Each VersionRuleKind
    ## corresponds to a part of the rule grammar described in
    ## module `resolver/versionrule`.
    ## 
    ## A `nil` VersionRule matches any version.
    case kind*: VersionRuleKind
    of vrEqual, vrNotEqual, vrGreaterOrEqual, vrLesserOrEqual,
       vrBackwardsCompat, vrOptimisticBackwardsCompat:
      version*: Version
    of vrAnd, vrOr:
      left*, right*: VersionRule

  Dependency* = object ##\
    ## A dependency is a package name with a corresponding VersionRule.
    packageName*: string
    versionRule*: VersionRule
    location*: Uri

  ParseVersionError* = object of ValueError

type
  VersionParseOpts* {.pure.} = enum ##\
    ## Flags that control the behavior of the parser functions:
    ##  - `parseVersionRule`
    ##  - `parseVersion`
    ##  - `parseDependency`
    AllowMissingMinor,   ## Allow a missing minor version number.
    AllowMissingPatch,   ## Allow a missing patch version number.
    AllowPreReleaseTags, ## Allow pre-release tags.
    AllowBuildMetadata,  ## Allow build metadata.
    ConsumeWholeInput    ## Raise an error if the whole string isn't consumed by the parser.

const DefaultVersionParseOpts*: set[VersionParseOpts] = {
  AllowPreReleaseTags,
  AllowBuildMetadata,
  ConsumeWholeInput
}
