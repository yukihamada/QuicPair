#!/bin/bash

echo "📱 Creating Complete iOS App Xcode Project"
echo "=========================================="

PROJECT_NAME="QuicPairApp"
BUNDLE_ID="com.yukihamada.quicpair"

# プロジェクト構造を作成
mkdir -p "$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata"
mkdir -p "$PROJECT_NAME/$PROJECT_NAME"

# 既存のファイルをプロジェクトフォルダにコピー
cp -r QuicPair/* "$PROJECT_NAME/$PROJECT_NAME/"

# project.pbxprojを作成
cat > "$PROJECT_NAME.xcodeproj/project.pbxproj" << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		8D5B3F2A2C8E4A7900A1B2C3 /* QuicPairApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F292C8E4A7900A1B2C3 /* QuicPairApp.swift */; };
		8D5B3F2C2C8E4A7900A1B2C3 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F2B2C8E4A7900A1B2C3 /* ContentView.swift */; };
		8D5B3F2E2C8E4A7900A1B2C3 /* QRScannerView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F2D2C8E4A7900A1B2C3 /* QRScannerView.swift */; };
		8D5B3F302C8E4A7900A1B2C3 /* OnboardingView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F2F2C8E4A7900A1B2C3 /* OnboardingView.swift */; };
		8D5B3F322C8E4A7900A1B2C3 /* ManualConnectionView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F312C8E4A7900A1B2C3 /* ManualConnectionView.swift */; };
		8D5B3F342C8E4A7900A1B2C3 /* TTFTChartView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F332C8E4A7900A1B2C3 /* TTFTChartView.swift */; };
		8D5B3F362C8E4A7900A1B2C3 /* ChatService.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F352C8E4A7900A1B2C3 /* ChatService.swift */; };
		8D5B3F382C8E4A7900A1B2C3 /* ConnectionManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F372C8E4A7900A1B2C3 /* ConnectionManager.swift */; };
		8D5B3F3A2C8E4A7900A1B2C3 /* NoiseManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8D5B3F392C8E4A7900A1B2C3 /* NoiseManager.swift */; };
		8D5B3F3C2C8E4A7A00A1B2C3 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = 8D5B3F3B2C8E4A7A00A1B2C3 /* Assets.xcassets */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		8D5B3F262C8E4A7900A1B2C3 /* QuicPairApp.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = QuicPairApp.app; sourceTree = BUILT_PRODUCTS_DIR; };
		8D5B3F292C8E4A7900A1B2C3 /* QuicPairApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = QuicPairApp.swift; sourceTree = "<group>"; };
		8D5B3F2B2C8E4A7900A1B2C3 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		8D5B3F2D2C8E4A7900A1B2C3 /* QRScannerView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = QRScannerView.swift; sourceTree = "<group>"; };
		8D5B3F2F2C8E4A7900A1B2C3 /* OnboardingView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = OnboardingView.swift; sourceTree = "<group>"; };
		8D5B3F312C8E4A7900A1B2C3 /* ManualConnectionView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ManualConnectionView.swift; sourceTree = "<group>"; };
		8D5B3F332C8E4A7900A1B2C3 /* TTFTChartView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TTFTChartView.swift; sourceTree = "<group>"; };
		8D5B3F352C8E4A7900A1B2C3 /* ChatService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ChatService.swift; sourceTree = "<group>"; };
		8D5B3F372C8E4A7900A1B2C3 /* ConnectionManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ConnectionManager.swift; sourceTree = "<group>"; };
		8D5B3F392C8E4A7900A1B2C3 /* NoiseManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NoiseManager.swift; sourceTree = "<group>"; };
		8D5B3F3B2C8E4A7A00A1B2C3 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		8D5B3F3D2C8E4A7A00A1B2C3 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		8D5B3F232C8E4A7900A1B2C3 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		8D5B3F1D2C8E4A7900A1B2C3 = {
			isa = PBXGroup;
			children = (
				8D5B3F282C8E4A7900A1B2C3 /* QuicPairApp */,
				8D5B3F272C8E4A7900A1B2C3 /* Products */,
			);
			sourceTree = "<group>";
		};
		8D5B3F272C8E4A7900A1B2C3 /* Products */ = {
			isa = PBXGroup;
			children = (
				8D5B3F262C8E4A7900A1B2C3 /* QuicPairApp.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		8D5B3F282C8E4A7900A1B2C3 /* QuicPairApp */ = {
			isa = PBXGroup;
			children = (
				8D5B3F292C8E4A7900A1B2C3 /* QuicPairApp.swift */,
				8D5B3F422C8E4A8100A1B2C3 /* Views */,
				8D5B3F432C8E4A8600A1B2C3 /* Services */,
				8D5B3F3B2C8E4A7A00A1B2C3 /* Assets.xcassets */,
				8D5B3F3D2C8E4A7A00A1B2C3 /* Info.plist */,
			);
			path = QuicPairApp;
			sourceTree = "<group>";
		};
		8D5B3F422C8E4A8100A1B2C3 /* Views */ = {
			isa = PBXGroup;
			children = (
				8D5B3F2B2C8E4A7900A1B2C3 /* ContentView.swift */,
				8D5B3F2D2C8E4A7900A1B2C3 /* QRScannerView.swift */,
				8D5B3F2F2C8E4A7900A1B2C3 /* OnboardingView.swift */,
				8D5B3F312C8E4A7900A1B2C3 /* ManualConnectionView.swift */,
				8D5B3F332C8E4A7900A1B2C3 /* TTFTChartView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		};
		8D5B3F432C8E4A8600A1B2C3 /* Services */ = {
			isa = PBXGroup;
			children = (
				8D5B3F352C8E4A7900A1B2C3 /* ChatService.swift */,
				8D5B3F372C8E4A7900A1B2C3 /* ConnectionManager.swift */,
				8D5B3F392C8E4A7900A1B2C3 /* NoiseManager.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		8D5B3F252C8E4A7900A1B2C3 /* QuicPairApp */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 8D5B3F402C8E4A7A00A1B2C3 /* Build configuration list for PBXNativeTarget "QuicPairApp" */;
			buildPhases = (
				8D5B3F222C8E4A7900A1B2C3 /* Sources */,
				8D5B3F232C8E4A7900A1B2C3 /* Frameworks */,
				8D5B3F242C8E4A7900A1B2C3 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = QuicPairApp;
			packageProductDependencies = (
			);
			productName = QuicPairApp;
			productReference = 8D5B3F262C8E4A7900A1B2C3 /* QuicPairApp.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		8D5B3F1E2C8E4A7900A1B2C3 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					8D5B3F252C8E4A7900A1B2C3 = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			buildConfigurationList = 8D5B3F212C8E4A7900A1B2C3 /* Build configuration list for PBXProject "QuicPairApp" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = 8D5B3F1D2C8E4A7900A1B2C3;
			productRefGroup = 8D5B3F272C8E4A7900A1B2C3 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				8D5B3F252C8E4A7900A1B2C3 /* QuicPairApp */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		8D5B3F242C8E4A7900A1B2C3 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				8D5B3F3C2C8E4A7A00A1B2C3 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		8D5B3F222C8E4A7900A1B2C3 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				8D5B3F2C2C8E4A7900A1B2C3 /* ContentView.swift in Sources */,
				8D5B3F2A2C8E4A7900A1B2C3 /* QuicPairApp.swift in Sources */,
				8D5B3F2E2C8E4A7900A1B2C3 /* QRScannerView.swift in Sources */,
				8D5B3F302C8E4A7900A1B2C3 /* OnboardingView.swift in Sources */,
				8D5B3F322C8E4A7900A1B2C3 /* ManualConnectionView.swift in Sources */,
				8D5B3F342C8E4A7900A1B2C3 /* TTFTChartView.swift in Sources */,
				8D5B3F362C8E4A7900A1B2C3 /* ChatService.swift in Sources */,
				8D5B3F382C8E4A7900A1B2C3 /* ConnectionManager.swift in Sources */,
				8D5B3F3A2C8E4A7900A1B2C3 /* NoiseManager.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		8D5B3F3E2C8E4A7A00A1B2C3 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
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
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		8D5B3F3F2C8E4A7A00A1B2C3 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
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
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		8D5B3F412C8E4A7A00A1B2C3 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = QuicPairApp/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = QuicPair;
				INFOPLIST_KEY_NSCameraUsageDescription = "QuicPair needs camera access to scan QR codes for connecting to your Mac";
				INFOPLIST_KEY_NSLocalNetworkUsageDescription = "QuicPair needs local network access to connect to your Mac and use local LLM";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.yukihamada.quicpair";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		8D5B3F422C8E4A7A00A1B2C3 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = QuicPairApp/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = QuicPair;
				INFOPLIST_KEY_NSCameraUsageDescription = "QuicPair needs camera access to scan QR codes for connecting to your Mac";
				INFOPLIST_KEY_NSLocalNetworkUsageDescription = "QuicPair needs local network access to connect to your Mac and use local LLM";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.yukihamada.quicpair";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		8D5B3F212C8E4A7900A1B2C3 /* Build configuration list for PBXProject "QuicPairApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				8D5B3F3E2C8E4A7A00A1B2C3 /* Debug */,
				8D5B3F3F2C8E4A7A00A1B2C3 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		8D5B3F402C8E4A7A00A1B2C3 /* Build configuration list for PBXNativeTarget "QuicPairApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				8D5B3F412C8E4A7A00A1B2C3 /* Debug */,
				8D5B3F422C8E4A7A00A1B2C3 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = 8D5B3F1E2C8E4A7900A1B2C3 /* Project object */;
}
EOF

# workspace設定を作成
cat > "$PROJECT_NAME.xcodeproj/project.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
EOF

cat > "$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDEDidComputeMac32BitWarning</key>
	<true/>
</dict>
</plist>
EOF

# Assets.xcassetsを作成
mkdir -p "$PROJECT_NAME/$PROJECT_NAME/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$PROJECT_NAME/$PROJECT_NAME/Assets.xcassets/AccentColor.colorset"

cat > "$PROJECT_NAME/$PROJECT_NAME/Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

cat > "$PROJECT_NAME/$PROJECT_NAME/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

cat > "$PROJECT_NAME/$PROJECT_NAME/Assets.xcassets/AccentColor.colorset/Contents.json" << 'EOF'
{
  "colors" : [
    {
      "color" : {
        "platform" : "universal",
        "reference" : "systemBlueColor"
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo ""
echo "✅ iOS App Xcode Project Created!"
echo ""
echo "📁 Project: $PROJECT_NAME.xcodeproj"
echo ""
echo "🚀 Next steps:"
echo "1. Opening in Xcode..."
echo "2. Select your team in Signing & Capabilities"
echo "3. Connect your iPhone"
echo "4. Press Cmd+R to run"

# Xcodeで開く
open "$PROJECT_NAME.xcodeproj"