#!/usr/bin/env python3
"""Generate MillsBucks.xcodeproj/project.pbxproj from the sources in ios/MillsBucks/.

Re-run after adding or removing a .swift file. IDs are derived from file names,
so regenerating produces a stable, diff-friendly project file.
"""
import hashlib
import os
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
IOS = ROOT / "ios"
APP = "MillsBucks"
SRC_DIR = IOS / APP
PROJ_DIR = IOS / f"{APP}.xcodeproj"

BUNDLE_ID = "com.millsbucks.tracker"
DEPLOYMENT_TARGET = "16.0"


def oid(label):
    """Deterministic 24-char uppercase hex object id."""
    return hashlib.md5(label.encode()).hexdigest()[:24].upper()


swift_files = sorted(p.name for p in SRC_DIR.glob("*.swift"))
resources = ["Assets.xcassets"]

ids = {
    "project": oid("project"),
    "target": oid("target"),
    "product": oid("product"),
    "mainGroup": oid("group.main"),
    "appGroup": oid("group.app"),
    "productsGroup": oid("group.products"),
    "sources": oid("phase.sources"),
    "frameworks": oid("phase.frameworks"),
    "resources": oid("phase.resources"),
    "projConfList": oid("conflist.project"),
    "targetConfList": oid("conflist.target"),
    "projDebug": oid("config.project.debug"),
    "projRelease": oid("config.project.release"),
    "targetDebug": oid("config.target.debug"),
    "targetRelease": oid("config.target.release"),
}

TAB = "\t"


def build_file_section():
    out = ["/* Begin PBXBuildFile section */"]
    for name in swift_files + resources:
        kind = "Sources" if name.endswith(".swift") else "Resources"
        out.append(f"{TAB*2}{oid('build.' + name)} /* {name} in {kind} */ = "
                   f"{{isa = PBXBuildFile; fileRef = {oid('file.' + name)} /* {name} */; }};")
    out.append("/* End PBXBuildFile section */")
    return "\n".join(out)


def file_reference_section():
    out = ["/* Begin PBXFileReference section */",
           f"{TAB*2}{ids['product']} /* {APP}.app */ = {{isa = PBXFileReference; "
           f"explicitFileType = wrapper.application; includeInIndex = 0; "
           f"path = {APP}.app; sourceTree = BUILT_PRODUCTS_DIR; }};"]
    for name in swift_files:
        out.append(f"{TAB*2}{oid('file.' + name)} /* {name} */ = {{isa = PBXFileReference; "
                   f"lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
    for name in resources:
        out.append(f"{TAB*2}{oid('file.' + name)} /* {name} */ = {{isa = PBXFileReference; "
                   f"lastKnownFileType = folder.assetcatalog; path = {name}; sourceTree = \"<group>\"; }};")
    out.append("/* End PBXFileReference section */")
    return "\n".join(out)


def group_section():
    app_children = "\n".join(
        f"{TAB*4}{oid('file.' + n)} /* {n} */," for n in swift_files + resources)
    return f"""/* Begin PBXGroup section */
{TAB*2}{ids['mainGroup']} = {{
{TAB*3}isa = PBXGroup;
{TAB*3}children = (
{TAB*4}{ids['appGroup']} /* {APP} */,
{TAB*4}{ids['productsGroup']} /* Products */,
{TAB*3});
{TAB*3}sourceTree = "<group>";
{TAB*2}}};
{TAB*2}{ids['appGroup']} /* {APP} */ = {{
{TAB*3}isa = PBXGroup;
{TAB*3}children = (
{app_children}
{TAB*3});
{TAB*3}path = {APP};
{TAB*3}sourceTree = "<group>";
{TAB*2}}};
{TAB*2}{ids['productsGroup']} /* Products */ = {{
{TAB*3}isa = PBXGroup;
{TAB*3}children = (
{TAB*4}{ids['product']} /* {APP}.app */,
{TAB*3});
{TAB*3}name = Products;
{TAB*3}sourceTree = "<group>";
{TAB*2}}};
/* End PBXGroup section */"""


def phase_sections():
    sources = "\n".join(
        f"{TAB*4}{oid('build.' + n)} /* {n} in Sources */," for n in swift_files)
    res = "\n".join(
        f"{TAB*4}{oid('build.' + n)} /* {n} in Resources */," for n in resources)
    return f"""/* Begin PBXFrameworksBuildPhase section */
{TAB*2}{ids['frameworks']} /* Frameworks */ = {{
{TAB*3}isa = PBXFrameworksBuildPhase;
{TAB*3}buildActionMask = 2147483647;
{TAB*3}files = (
{TAB*3});
{TAB*3}runOnlyForDeploymentPostprocessing = 0;
{TAB*2}}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXResourcesBuildPhase section */
{TAB*2}{ids['resources']} /* Resources */ = {{
{TAB*3}isa = PBXResourcesBuildPhase;
{TAB*3}buildActionMask = 2147483647;
{TAB*3}files = (
{res}
{TAB*3});
{TAB*3}runOnlyForDeploymentPostprocessing = 0;
{TAB*2}}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
{TAB*2}{ids['sources']} /* Sources */ = {{
{TAB*3}isa = PBXSourcesBuildPhase;
{TAB*3}buildActionMask = 2147483647;
{TAB*3}files = (
{sources}
{TAB*3});
{TAB*3}runOnlyForDeploymentPostprocessing = 0;
{TAB*2}}};
/* End PBXSourcesBuildPhase section */"""


def target_and_project_sections():
    return f"""/* Begin PBXNativeTarget section */
{TAB*2}{ids['target']} /* {APP} */ = {{
{TAB*3}isa = PBXNativeTarget;
{TAB*3}buildConfigurationList = {ids['targetConfList']} /* Build configuration list for PBXNativeTarget "{APP}" */;
{TAB*3}buildPhases = (
{TAB*4}{ids['sources']} /* Sources */,
{TAB*4}{ids['frameworks']} /* Frameworks */,
{TAB*4}{ids['resources']} /* Resources */,
{TAB*3});
{TAB*3}buildRules = (
{TAB*3});
{TAB*3}dependencies = (
{TAB*3});
{TAB*3}name = {APP};
{TAB*3}productName = {APP};
{TAB*3}productReference = {ids['product']} /* {APP}.app */;
{TAB*3}productType = "com.apple.product-type.application";
{TAB*2}}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
{TAB*2}{ids['project']} /* Project object */ = {{
{TAB*3}isa = PBXProject;
{TAB*3}attributes = {{
{TAB*4}BuildIndependentTargetsInParallel = 1;
{TAB*4}LastSwiftUpdateCheck = 1500;
{TAB*4}LastUpgradeCheck = 1500;
{TAB*4}TargetAttributes = {{
{TAB*5}{ids['target']} = {{
{TAB*6}CreatedOnToolsVersion = 15.0;
{TAB*5}}};
{TAB*4}}};
{TAB*3}}};
{TAB*3}buildConfigurationList = {ids['projConfList']} /* Build configuration list for PBXProject "{APP}" */;
{TAB*3}compatibilityVersion = "Xcode 14.0";
{TAB*3}developmentRegion = en;
{TAB*3}hasScannedForEncodings = 0;
{TAB*3}knownRegions = (
{TAB*4}en,
{TAB*4}Base,
{TAB*3});
{TAB*3}mainGroup = {ids['mainGroup']};
{TAB*3}productRefGroup = {ids['productsGroup']} /* Products */;
{TAB*3}projectDirPath = "";
{TAB*3}projectRoot = "";
{TAB*3}targets = (
{TAB*4}{ids['target']} /* {APP} */,
{TAB*3});
{TAB*2}}};
/* End PBXProject section */"""


PROJECT_COMMON = """ALWAYS_SEARCH_USER_PATHS = NO;
CLANG_ANALYZER_NONNULL = YES;
CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
CLANG_ENABLE_MODULES = YES;
CLANG_ENABLE_OBJC_ARC = YES;
CLANG_ENABLE_OBJC_WEAK = YES;
CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
CLANG_WARN_BOOL_CONVERSION = YES;
CLANG_WARN_COMMA = YES;
CLANG_WARN_CONSTANT_CONVERSION = YES;
CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
CLANG_WARN_EMPTY_BODY = YES;
CLANG_WARN_ENUM_CONVERSION = YES;
CLANG_WARN_INFINITE_RECURSION = YES;
CLANG_WARN_INT_CONVERSION = YES;
CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
CLANG_WARN_STRICT_PROTOTYPES = YES;
CLANG_WARN_SUSPICIOUS_MOVE = YES;
CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
CLANG_WARN_UNREACHABLE_CODE = YES;
CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
COPY_PHASE_STRIP = NO;
ENABLE_STRICT_OBJC_MSGSEND = YES;
GCC_C_LANGUAGE_STANDARD = gnu17;
GCC_NO_COMMON_BLOCKS = YES;
GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
GCC_WARN_UNDECLARED_SELECTOR = YES;
GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
GCC_WARN_UNUSED_FUNCTION = YES;
GCC_WARN_UNUSED_VARIABLE = YES;
IPHONEOS_DEPLOYMENT_TARGET = %s;
LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
MTL_FAST_MATH = YES;
SDKROOT = iphoneos;""" % DEPLOYMENT_TARGET

PROJECT_DEBUG_ONLY = """DEBUG_INFORMATION_FORMAT = dwarf;
ENABLE_TESTABILITY = YES;
GCC_DYNAMIC_NO_PIC = NO;
GCC_OPTIMIZATION_LEVEL = 0;
GCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
ONLY_ACTIVE_ARCH = YES;
SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
SWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

PROJECT_RELEASE_ONLY = """DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
ENABLE_NS_ASSERTIONS = NO;
MTL_ENABLE_DEBUG_INFO = NO;
SWIFT_COMPILATION_MODE = wholemodule;
VALIDATE_PRODUCT = YES;"""

TARGET_COMMON = """ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
CODE_SIGN_STYLE = Automatic;
CURRENT_PROJECT_VERSION = 1;
ENABLE_PREVIEWS = YES;
GENERATE_INFOPLIST_FILE = YES;
INFOPLIST_KEY_CFBundleDisplayName = "Mills Bucks";
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
INFOPLIST_KEY_UILaunchScreen_Generation = YES;
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait";
LD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
MARKETING_VERSION = 1.0;
PRODUCT_BUNDLE_IDENTIFIER = %s;
PRODUCT_NAME = "$(TARGET_NAME)";
SWIFT_EMIT_LOC_STRINGS = YES;
SWIFT_VERSION = 5.0;
TARGETED_DEVICE_FAMILY = "1,2";""" % BUNDLE_ID


def indent_settings(block, depth):
    pad = TAB * depth
    out = []
    for line in block.split("\n"):
        out.append(line if line.startswith("\t") else pad + line)
    return "\n".join(out)


def config(cfg_id, name, settings, base=None):
    body = indent_settings(settings, 4)
    base_line = f"\n{TAB*3}baseConfigurationReference = {base};" if base else ""
    return f"""{TAB*2}{cfg_id} /* {name} */ = {{
{TAB*3}isa = XCBuildConfiguration;{base_line}
{TAB*3}buildSettings = {{
{body}
{TAB*3}}};
{TAB*3}name = {name};
{TAB*2}}};"""


def config_sections():
    blocks = [
        config(ids["projDebug"], "Debug", PROJECT_COMMON + "\n" + PROJECT_DEBUG_ONLY),
        config(ids["projRelease"], "Release", PROJECT_COMMON + "\n" + PROJECT_RELEASE_ONLY),
        config(ids["targetDebug"], "Debug", TARGET_COMMON),
        config(ids["targetRelease"], "Release", TARGET_COMMON),
    ]
    return ("/* Begin XCBuildConfiguration section */\n"
            + "\n".join(blocks)
            + "\n/* End XCBuildConfiguration section */")


def conf_list_sections():
    def lst(list_id, owner, debug_id, release_id):
        return f"""{TAB*2}{list_id} /* Build configuration list for {owner} */ = {{
{TAB*3}isa = XCConfigurationList;
{TAB*3}buildConfigurations = (
{TAB*4}{debug_id} /* Debug */,
{TAB*4}{release_id} /* Release */,
{TAB*3});
{TAB*3}defaultConfigurationIsVisible = 0;
{TAB*3}defaultConfigurationName = Release;
{TAB*2}}};"""
    return ("/* Begin XCConfigurationList section */\n"
            + lst(ids["projConfList"], f'PBXProject "{APP}"', ids["projDebug"], ids["projRelease"])
            + "\n"
            + lst(ids["targetConfList"], f'PBXNativeTarget "{APP}"', ids["targetDebug"], ids["targetRelease"])
            + "\n/* End XCConfigurationList section */")


pbxproj = f"""// !$*UTF8*$!
{{
{TAB}archiveVersion = 1;
{TAB}classes = {{
{TAB}}};
{TAB}objectVersion = 56;
{TAB}objects = {{

{build_file_section()}

{file_reference_section()}

{phase_sections()}

{group_section()}

{target_and_project_sections()}

{config_sections()}

{conf_list_sections()}
{TAB}}};
{TAB}rootObject = {ids['project']} /* Project object */;
}}
"""

SCHEME = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1500" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['target']}"
               BuildableName = "{APP}.app"
               BlueprintName = "{APP}"
               ReferencedContainer = "container:{APP}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['target']}"
            BuildableName = "{APP}.app"
            BlueprintName = "{APP}"
            ReferencedContainer = "container:{APP}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['target']}"
            BuildableName = "{APP}.app"
            BlueprintName = "{APP}"
            ReferencedContainer = "container:{APP}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

WORKSPACE = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""

os.makedirs(PROJ_DIR / "xcshareddata" / "xcschemes", exist_ok=True)
os.makedirs(PROJ_DIR / "project.xcworkspace", exist_ok=True)
(PROJ_DIR / "project.pbxproj").write_text(pbxproj, encoding="utf-8")
(PROJ_DIR / "xcshareddata" / "xcschemes" / f"{APP}.xcscheme").write_text(SCHEME, encoding="utf-8")
(PROJ_DIR / "project.xcworkspace" / "contents.xcworkspacedata").write_text(WORKSPACE, encoding="utf-8")

print(f"wrote {PROJ_DIR.relative_to(ROOT)}/project.pbxproj")
print(f"  {len(swift_files)} swift files: {', '.join(swift_files)}")
print(f"  resources: {', '.join(resources)}")
