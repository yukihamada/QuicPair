#!/bin/bash

echo "🔧 Creating Clean Xcode Project"
echo "==============================="

# Create project using xcodebuild
PROJECT_NAME="QuicPair"
BUNDLE_ID="com.yukihamada.quicpair"

# Create a simple project.yml for xcodegen if available
cat > project.yml << EOF
name: QuicPair
options:
  bundleIdPrefix: com.yukihamada
  deploymentTarget:
    iOS: 16.0
targets:
  QuicPair:
    type: application
    platform: iOS
    sources:
      - path: QuicPair
        excludes:
          - "**/*.xcassets"
      - path: QuicPairApp/QuicPairApp
    resources:
      - path: QuicPairApp/QuicPairApp/Assets.xcassets
    info:
      path: QuicPair/Info.plist
      properties:
        CFBundleDisplayName: QuicPair
        UILaunchScreen: {}
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        NSCameraUsageDescription: "QuicPair needs camera access to scan QR codes for connecting to your Mac"
        NSLocalNetworkUsageDescription: "QuicPair needs local network access to connect to your Mac and use local LLM"
        NSAppTransportSecurity:
          NSAllowsArbitraryLoads: true
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.yukihamada.quicpair
      ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
      DEVELOPMENT_TEAM: ""
      CODE_SIGN_STYLE: Automatic
EOF

# Check if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo "📦 Using xcodegen to create project..."
    xcodegen
    rm project.yml
else
    echo "📦 Creating Xcode project manually..."
    
    # Use Python to create a proper project file
    python3 << 'PYTHON_EOF'
import os
import uuid
import plistlib

def create_xcode_project():
    # Create project directory
    os.makedirs("QuicPair.xcodeproj", exist_ok=True)
    
    # Generate UUIDs
    def new_uuid():
        return str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    # Project structure
    project_uuid = new_uuid()
    main_group_uuid = new_uuid()
    products_group_uuid = new_uuid()
    sources_group_uuid = new_uuid()
    views_group_uuid = new_uuid()
    services_group_uuid = new_uuid()
    models_group_uuid = new_uuid()
    target_uuid = new_uuid()
    build_config_list_uuid = new_uuid()
    project_build_config_list_uuid = new_uuid()
    
    # File references
    files = {
        'QuicPairApp.swift': ('QuicPair/QuicPairApp.swift', new_uuid()),
        'AppState.swift': ('QuicPair/AppState.swift', new_uuid()),
        'ContentView.swift': ('QuicPair/Views/ContentView.swift', new_uuid()),
        'QRScannerView.swift': ('QuicPair/Views/QRScannerView.swift', new_uuid()),
        'ChatView.swift': ('QuicPair/Views/ChatView.swift', new_uuid()),
        'OnboardingView.swift': ('QuicPair/Views/OnboardingView.swift', new_uuid()),
        'ManualConnectionView.swift': ('QuicPair/Views/ManualConnectionView.swift', new_uuid()),
        'TTFTChartView.swift': ('QuicPair/Views/TTFTChartView.swift', new_uuid()),
        'ChatService.swift': ('QuicPair/Services/ChatService.swift', new_uuid()),
        'ConnectionManager.swift': ('QuicPair/Services/ConnectionManager.swift', new_uuid()),
        'NoiseManager.swift': ('QuicPair/Services/NoiseManager.swift', new_uuid()),
        'ChatMessage.swift': ('QuicPair/Models/ChatMessage.swift', new_uuid()),
        'RecentConnection.swift': ('QuicPair/Models/RecentConnection.swift', new_uuid()),
        'Assets.xcassets': ('QuicPairApp/QuicPairApp/Assets.xcassets', new_uuid()),
        'Info.plist': ('QuicPair/Info.plist', new_uuid()),
    }
    
    # Build file UUIDs
    build_files = {name: new_uuid() for name in files if name.endswith('.swift')}
    resources_uuid = new_uuid()
    
    # Create the project.pbxproj content
    content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
"""
    
    # Add build files
    for name, uuid in build_files.items():
        file_uuid = files[name][1]
        content += f"\t\t{uuid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {name} */; }};\n"
    
    content += f"\t\t{resources_uuid} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {files['Assets.xcassets'][1]} /* Assets.xcassets */; }};\n"
    
    content += """/* End PBXBuildFile section */

/* Begin PBXFileReference section */
"""
    
    # Add file references
    content += f"\t\t{new_uuid()} /* QuicPair.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = QuicPair.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
    
    for name, (path, uuid) in files.items():
        if name.endswith('.swift'):
            content += f"\t\t{uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};\n"
        elif name == 'Assets.xcassets':
            content += f"\t\t{uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = ../../{path}; sourceTree = \"<group>\"; }};\n"
        elif name == 'Info.plist':
            content += f"\t\t{uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = {name}; sourceTree = \"<group>\"; }};\n"
    
    content += f"""/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{new_uuid()} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group_uuid} = {{
			isa = PBXGroup;
			children = (
				{sources_group_uuid} /* QuicPair */,
				{products_group_uuid} /* Products */,
			);
			sourceTree = \"<group>\";
		}};
		{products_group_uuid} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{new_uuid()} /* QuicPair.app */,
			);
			name = Products;
			sourceTree = \"<group>\";
		}};
		{sources_group_uuid} /* QuicPair */ = {{
			isa = PBXGroup;
			children = (
				{files['QuicPairApp.swift'][1]} /* QuicPairApp.swift */,
				{files['AppState.swift'][1]} /* AppState.swift */,
				{models_group_uuid} /* Models */,
				{views_group_uuid} /* Views */,
				{services_group_uuid} /* Services */,
				{files['Assets.xcassets'][1]} /* Assets.xcassets */,
				{files['Info.plist'][1]} /* Info.plist */,
			);
			path = QuicPair;
			sourceTree = \"<group>\";
		}};
		{views_group_uuid} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{files['ContentView.swift'][1]} /* ContentView.swift */,
				{files['QRScannerView.swift'][1]} /* QRScannerView.swift */,
				{files['ChatView.swift'][1]} /* ChatView.swift */,
				{files['OnboardingView.swift'][1]} /* OnboardingView.swift */,
				{files['ManualConnectionView.swift'][1]} /* ManualConnectionView.swift */,
				{files['TTFTChartView.swift'][1]} /* TTFTChartView.swift */,
			);
			path = Views;
			sourceTree = \"<group>\";
		}};
		{services_group_uuid} /* Services */ = {{
			isa = PBXGroup;
			children = (
				{files['ChatService.swift'][1]} /* ChatService.swift */,
				{files['ConnectionManager.swift'][1]} /* ConnectionManager.swift */,
				{files['NoiseManager.swift'][1]} /* NoiseManager.swift */,
			);
			path = Services;
			sourceTree = \"<group>\";
		}};
		{models_group_uuid} /* Models */ = {{
			isa = PBXGroup;
			children = (
				{files['ChatMessage.swift'][1]} /* ChatMessage.swift */,
				{files['RecentConnection.swift'][1]} /* RecentConnection.swift */,
			);
			path = Models;
			sourceTree = \"<group>\";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_uuid} /* QuicPair */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {build_config_list_uuid} /* Build configuration list for PBXNativeTarget \"QuicPair\" */;
			buildPhases = (
				{new_uuid()} /* Sources */,
				{new_uuid()} /* Frameworks */,
				{new_uuid()} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = QuicPair;
			productName = QuicPair;
			productReference = {new_uuid()} /* QuicPair.app */;
			productType = \"com.apple.product-type.application\";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_uuid} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{target_uuid} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {project_build_config_list_uuid} /* Build configuration list for PBXProject \"QuicPair\" */;
			compatibilityVersion = \"Xcode 14.0\";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group_uuid};
			productRefGroup = {products_group_uuid} /* Products */;
			projectDirPath = \"\";
			projectRoot = \"\";
			targets = (
				{target_uuid} /* QuicPair */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{new_uuid()} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{resources_uuid} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{new_uuid()} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
"""
    
    # Add source files to build phase
    for name, uuid in build_files.items():
        content += f"\t\t\t\t{uuid} /* {name} in Sources */,\n"
    
    content += f"""			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{new_uuid()} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";
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
					\"DEBUG=1\",
					\"$(inherited)\",
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
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\";
				SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";
			}};
			name = Debug;
		}};
		{new_uuid()} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";
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
				DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";
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
			}};
			name = Release;
		}};
		{new_uuid()} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = \"\";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = QuicPair/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = QuicPair;
				INFOPLIST_KEY_NSCameraUsageDescription = \"QuicPair needs camera access to scan QR codes for connecting to your Mac\";
				INFOPLIST_KEY_NSLocalNetworkUsageDescription = \"QuicPair needs local network access to connect to your Mac and use local LLM\";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown\";
				LD_RUNPATH_SEARCH_PATHS = (
					\"$(inherited)\",
					\"@executable_path/Frameworks\",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.yukihamada.quicpair;
				PRODUCT_NAME = \"$(TARGET_NAME)\";
				SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = \"1,2\";
			}};
			name = Debug;
		}};
		{new_uuid()} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = \"\";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = QuicPair/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = QuicPair;
				INFOPLIST_KEY_NSCameraUsageDescription = \"QuicPair needs camera access to scan QR codes for connecting to your Mac\";
				INFOPLIST_KEY_NSLocalNetworkUsageDescription = \"QuicPair needs local network access to connect to your Mac and use local LLM\";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown\";
				LD_RUNPATH_SEARCH_PATHS = (
					\"$(inherited)\",
					\"@executable_path/Frameworks\",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.yukihamada.quicpair;
				PRODUCT_NAME = \"$(TARGET_NAME)\";
				SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = \"1,2\";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{project_build_config_list_uuid} /* Build configuration list for PBXProject \"QuicPair\" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{new_uuid()} /* Debug */,
				{new_uuid()} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{build_config_list_uuid} /* Build configuration list for PBXNativeTarget \"QuicPair\" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{new_uuid()} /* Debug */,
				{new_uuid()} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_uuid} /* Project object */;
}}
"""
    
    # Write the project file
    with open("QuicPair.xcodeproj/project.pbxproj", "w") as f:
        f.write(content)
    
    print("✅ Xcode project created successfully!")

# Run the function
create_xcode_project()
PYTHON_EOF
fi

echo ""
echo "🎯 Project created! Now open QuicPair.xcodeproj in Xcode"
echo ""
echo "Next steps:"
echo "1. Select your development team in project settings"
echo "2. Clean build folder (Shift+Cmd+K)"
echo "3. Build the project (Cmd+B)"