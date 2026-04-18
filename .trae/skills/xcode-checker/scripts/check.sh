#!/bin/bash

# Ensure we are in the project root
if [ ! -d "VEXHelper.xcodeproj" ]; then
    # Try to find the project root relative to the script
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    PROJECT_ROOT="$SCRIPT_DIR/../../.."
    if [ -d "$PROJECT_ROOT/VEXHelper.xcodeproj" ]; then
        cd "$PROJECT_ROOT"
    else
        echo "Error: VEXHelper.xcodeproj not found. Please run this script from the project root."
        exit 1
    fi
fi

echo "Starting Xcode build and analysis..."

# Build for iOS Simulator to avoid signing issues
# Using 'platform=iOS Simulator,name=iPhone 17' as a default destination
# Adding CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO to bypass signing
xcodebuild -project VEXHelper.xcodeproj \
           -scheme VEXHelper \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           clean build analyze \
           CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

if [ $? -eq 0 ]; then
    echo "Build and analysis completed successfully. No errors found."
else
    echo "Build or analysis failed. Please check the errors above."
    exit 1
fi
