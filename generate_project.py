import os
import uuid

def gen_id():
    return uuid.uuid4().hex[:24].upper()

# Target and project settings
app_files = [
    "App/CircleAlertApp.swift",
    "Models/AppModels.swift",
    "ViewModels/AuthViewModel.swift",
    "ViewModels/HomeViewModel.swift",
    "ViewModels/CreateGroupViewModel.swift",
    "ViewModels/JoinGroupViewModel.swift",
    "ViewModels/GroupDetailViewModel.swift",
    "ViewModels/GeofenceSetupViewModel.swift",
    "ViewModels/ActivityAlertsViewModel.swift",
    "Views/Components/StatusPillView.swift",
    "Views/Components/PrimaryButton.swift",
    "Views/Components/CustomTextField.swift",
    "Views/Components/EmptyStateCard.swift",
    "Views/Authentication/LoginView.swift",
    "Views/Authentication/SignUpView.swift",
    "Views/Home/HomeDashboardView.swift",
    "Views/Groups/CreateGroupView.swift",
    "Views/Groups/JoinGroupView.swift",
    "Views/Groups/GroupDetailView.swift",
    "Views/Geofence/GeofenceSetupView.swift",
    "Views/Activity/ActivityAlertsView.swift",
    "Location/LocationManager.swift",
    "Location/GeofenceSimulator.swift",
    "Services/FirebaseService.swift",
    "Services/NotificationService.swift",
    "Services/SharedKMPBridge.swift",
]

resource_files = [
    "Resources/Info.plist",
    "Resources/GoogleService-Info.plist",
    "Resources/Assets.xcassets",
]

test_files = [
    "CircleAlertTests.swift"
]

file_refs = {}
build_files = {}

for f in app_files + resource_files:
    fid = gen_id()
    bid = gen_id()
    file_refs[f] = fid
    build_files[f] = bid

for f in test_files:
    fid = gen_id()
    bid = gen_id()
    file_refs[f] = fid
    build_files[f] = bid

# Shared framework ref
framework_file_id = gen_id()
framework_build_id = gen_id()

# CoreLocation, MapKit, UserNotifications framework refs
cl_file_id = gen_id()
cl_build_id = gen_id()
mk_file_id = gen_id()
mk_build_id = gen_id()
un_file_id = gen_id()
un_build_id = gen_id()

proj_id = gen_id()
target_id = gen_id()
test_target_id = gen_id()

sources_build_phase_id = gen_id()
resources_build_phase_id = gen_id()
frameworks_build_phase_id = gen_id()
kmp_script_phase_id = gen_id()

test_sources_phase_id = gen_id()
test_frameworks_phase_id = gen_id()

main_group_id = gen_id()
app_group_id = gen_id()
test_group_id = gen_id()
products_group_id = gen_id()
frameworks_group_id = gen_id()

app_product_id = gen_id()
test_product_id = gen_id()

proj_config_list_id = gen_id()
target_config_list_id = gen_id()
test_config_list_id = gen_id()

proj_debug_cfg_id = gen_id()
proj_release_cfg_id = gen_id()
target_debug_cfg_id = gen_id()
target_release_cfg_id = gen_id()
test_debug_cfg_id = gen_id()
test_release_cfg_id = gen_id()

target_proxy_id = gen_id()
target_dep_id = gen_id()

# Build PBXBuildFile section
pbx_build_files = []
for f in app_files:
    pbx_build_files.append(f"\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {os.path.basename(f)} */; }};")

for f in resource_files:
    if f.endswith(".xcassets"):
        pbx_build_files.append(f"\t\t{build_files[f]} /* {os.path.basename(f)} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {os.path.basename(f)} */; }};")
    elif f.endswith("GoogleService-Info.plist"):
        pbx_build_files.append(f"\t\t{build_files[f]} /* {os.path.basename(f)} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {os.path.basename(f)} */; }};")

for f in test_files:
    pbx_build_files.append(f"\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {os.path.basename(f)} */; }};")

pbx_build_files.append(f"\t\t{framework_build_id} /* SharedCircleAlert.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {framework_file_id} /* SharedCircleAlert.framework */; }};")
pbx_build_files.append(f"\t\t{cl_build_id} /* CoreLocation.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {cl_file_id} /* CoreLocation.framework */; }};")
pbx_build_files.append(f"\t\t{mk_build_id} /* MapKit.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {mk_file_id} /* MapKit.framework */; }};")
pbx_build_files.append(f"\t\t{un_build_id} /* UserNotifications.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {un_file_id} /* UserNotifications.framework */; }};")

# Build PBXFileReference section
pbx_file_refs = []
for f in app_files:
    name = os.path.basename(f)
    pbx_file_refs.append(f"\t\t{file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{f}\"; sourceTree = \"<group>\"; }};")

for f in resource_files:
    name = os.path.basename(f)
    if f.endswith(".xcassets"):
        file_type = "folder.assetcatalog"
    else:
        file_type = "text.plist.xml"
    pbx_file_refs.append(f"\t\t{file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = \"{f}\"; sourceTree = \"<group>\"; }};")

for f in test_files:
    name = os.path.basename(f)
    pbx_file_refs.append(f"\t\t{file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{f}\"; sourceTree = \"<group>\"; }};")

pbx_file_refs.append(f"\t\t{app_product_id} /* CircleAlert.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = CircleAlert.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
pbx_file_refs.append(f"\t\t{test_product_id} /* CircleAlertTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = CircleAlertTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
pbx_file_refs.append(f"\t\t{framework_file_id} /* SharedCircleAlert.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = SharedCircleAlert.framework; path = \"../shared/build/bin/iosSimulatorArm64/debugFramework/SharedCircleAlert.framework\"; sourceTree = SOURCE_ROOT; }};")
pbx_file_refs.append(f"\t\t{cl_file_id} /* CoreLocation.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = CoreLocation.framework; path = System/Library/Frameworks/CoreLocation.framework; sourceTree = SDKROOT; }};")
pbx_file_refs.append(f"\t\t{mk_file_id} /* MapKit.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = MapKit.framework; path = System/Library/Frameworks/MapKit.framework; sourceTree = SDKROOT; }};")
pbx_file_refs.append(f"\t\t{un_file_id} /* UserNotifications.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = UserNotifications.framework; path = System/Library/Frameworks/UserNotifications.framework; sourceTree = SDKROOT; }};")

# Sources build phase
sources_entries = "\n".join([f"\t\t\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */," for f in app_files])
resource_entries = "\n".join([f"\t\t\t\t{build_files[f]} /* {os.path.basename(f)} in Resources */," for f in resource_files if f.endswith(".xcassets") or f.endswith("GoogleService-Info.plist")])
test_sources_entries = "\n".join([f"\t\t\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */," for f in test_files])

frameworks_entries = f"""\t\t\t\t{framework_build_id} /* SharedCircleAlert.framework in Frameworks */,
\t\t\t\t{cl_build_id} /* CoreLocation.framework in Frameworks */,
\t\t\t\t{mk_build_id} /* MapKit.framework in Frameworks */,
\t\t\t\t{un_build_id} /* UserNotifications.framework in Frameworks */,"""

nl = "\n"
app_group_entries = nl.join([f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */," for f in app_files + resource_files])
test_group_entries = nl.join([f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */," for f in test_files])
pbx_build_files_str = nl.join(pbx_build_files)
pbx_file_refs_str = nl.join(pbx_file_refs)

content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{pbx_build_files_str}
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		{target_proxy_id} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {proj_id} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {target_id};
			remoteInfo = CircleAlert;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
{pbx_file_refs_str}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_build_phase_id} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
{frameworks_entries}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{test_frameworks_phase_id} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group_id} = {{
			isa = PBXGroup;
			children = (
				{app_group_id} /* CircleAlert */,
				{test_group_id} /* CircleAlertTests */,
				{frameworks_group_id} /* Frameworks */,
				{products_group_id} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{app_group_id} /* CircleAlert */ = {{
			isa = PBXGroup;
			children = (
{app_group_entries}
			);
			path = CircleAlert;
			sourceTree = "<group>";
		}};
		{test_group_id} /* CircleAlertTests */ = {{
			isa = PBXGroup;
			children = (
{test_group_entries}
			);
			path = CircleAlertTests;
			sourceTree = "<group>";
		}};
		{frameworks_group_id} /* Frameworks */ = {{
			isa = PBXGroup;
			children = (
				{framework_file_id} /* SharedCircleAlert.framework */,
				{cl_file_id} /* CoreLocation.framework */,
				{mk_file_id} /* MapKit.framework */,
				{un_file_id} /* UserNotifications.framework */,
			);
			name = Frameworks;
			sourceTree = "<group>";
		}};
		{products_group_id} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{app_product_id} /* CircleAlert.app */,
				{test_product_id} /* CircleAlertTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* CircleAlert */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_config_list_id} /* Build configuration list for PBXNativeTarget "CircleAlert" */;
			buildPhases = (
				{sources_build_phase_id} /* Sources */,
				{frameworks_build_phase_id} /* Frameworks */,
				{resources_build_phase_id} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = CircleAlert;
			productName = CircleAlert;
			productReference = {app_product_id} /* CircleAlert.app */;
			productType = "com.apple.product-type.application";
		}};
		{test_target_id} /* CircleAlertTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {test_config_list_id} /* Build configuration list for PBXNativeTarget "CircleAlertTests" */;
			buildPhases = (
				{test_sources_phase_id} /* Sources */,
				{test_frameworks_phase_id} /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				{target_dep_id} /* PBXTargetDependency */,
			);
			name = CircleAlertTests;
			productName = CircleAlertTests;
			productReference = {test_product_id} /* CircleAlertTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{proj_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 16.0;
					}};
					{test_target_id} = {{
						CreatedOnToolsVersion = 16.0;
						TestTargetID = {target_id};
					}};
				}};
			}};
			buildConfigurationList = {proj_config_list_id} /* Build configuration list for PBXProject "CircleAlert" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group_id};
			productRefGroup = {products_group_id} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* CircleAlert */,
				{test_target_id} /* CircleAlertTests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_build_phase_id} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{resource_entries}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_build_phase_id} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{sources_entries}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{test_sources_phase_id} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{test_sources_entries}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{target_dep_id} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {target_id} /* CircleAlert */;
			targetProxy = {target_proxy_id} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{proj_debug_cfg_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				ENABLE_BITCODE = NO;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{proj_release_cfg_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				ENABLE_BITCODE = NO;
				ENABLE_NS_ASSERTIONS = NO;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{target_debug_cfg_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ARCHS = arm64;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = NO;
				FRAMEWORK_SEARCH_PATHS = (
					"$(inherited)",
					"$(SRCROOT)/../shared/build/bin/iosSimulatorArm64/debugFramework",
					"$(SRCROOT)/../shared/build/bin/iosArm64/debugFramework",
				);
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = CircleAlert/Resources/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"$(SRCROOT)/../shared/build/bin/iosSimulatorArm64/debugFramework",
				);
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.circlealert.ios;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{target_release_cfg_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ARCHS = arm64;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = NO;
				FRAMEWORK_SEARCH_PATHS = (
					"$(inherited)",
					"$(SRCROOT)/../shared/build/bin/iosSimulatorArm64/debugFramework",
					"$(SRCROOT)/../shared/build/bin/iosArm64/debugFramework",
				);
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = CircleAlert/Resources/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"$(SRCROOT)/../shared/build/bin/iosSimulatorArm64/debugFramework",
				);
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.circlealert.ios;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
		{test_debug_cfg_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ARCHS = arm64;
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				FRAMEWORK_SEARCH_PATHS = (
					"$(inherited)",
					"$(SRCROOT)/../shared/build/bin/iosSimulatorArm64/debugFramework",
					"$(SRCROOT)/../shared/build/bin/iosArm64/debugFramework",
				);
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.circlealert.ios.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/CircleAlert.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/CircleAlert";
			}};
			name = Debug;
		}};
		{test_release_cfg_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ARCHS = arm64;
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				FRAMEWORK_SEARCH_PATHS = (
					"$(inherited)",
					"$(SRCROOT)/../shared/build/bin/iosSimulatorArm64/debugFramework",
					"$(SRCROOT)/../shared/build/bin/iosArm64/debugFramework",
				);
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.circlealert.ios.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/CircleAlert.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/CircleAlert";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{proj_config_list_id} /* Build configuration list for PBXProject "CircleAlert" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{proj_debug_cfg_id} /* Debug */,
				{proj_release_cfg_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{target_config_list_id} /* Build configuration list for PBXNativeTarget "CircleAlert" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{target_debug_cfg_id} /* Debug */,
				{target_release_cfg_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{test_config_list_id} /* Build configuration list for PBXNativeTarget "CircleAlertTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{test_debug_cfg_id} /* Debug */,
				{test_release_cfg_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

	}};
	rootObject = {proj_id} /* Project object */;
}}
"""

os.makedirs("iosApp/CircleAlert.xcodeproj", exist_ok=True)
with open("iosApp/CircleAlert.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Generated iosApp/CircleAlert.xcodeproj/project.pbxproj successfully!")
