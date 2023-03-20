#!/bin/bash
# To generate the app icon files for MacOS and iOS from a base icon image `icon.png`, you can use the following bash script:
# This script creates MacOS app icons in the `macos_icon.iconset` folder and iOS app icons in the `ios_icon.iconset` folder, based on the `icon.png` file. It then copies the generated icons into the appropriate folders for a Flutter project (`macos/Runner/Assets.xcassets/AppIcon.appiconset` and `ios/Runner/Assets.xcassets/AppIcon.appiconset`). You should save this script to file (e.g. `generate_icons.sh`) and run it from the command line in your project directory. Don't forget to make the script executable using `chmod +x generate_icons.sh`.
# To use this script, you can run it from the command line with the `icon.png` file path parameter, like this:
#
#./generate_icons.sh /path/to/icon.png
#Make sure to replace `/path/to/icon.png` with the actual file path to your icon image.
# Get the input icon file path parameter
# Get the input icon file path parameter
icon_file=$1

# Create iOS app icons
mkdir ios_icon.iconset
sips -z 1024 1024 $icon_file --out ios_icon.iconset/Icon-App-1024x1024@1x.png
sips -z 20 20 $icon_file --out ios_icon.iconset/Icon-App-20x20@1x.png
sips -z 40 40 $icon_file --out ios_icon.iconset/Icon-App-20x20@2x.png
sips -z 60 60 $icon_file --out ios_icon.iconset/Icon-App-20x20@3x.png
sips -z 29 29 $icon_file --out ios_icon.iconset/Icon-App-29x29@1x.png
sips -z 58 58 $icon_file --out ios_icon.iconset/Icon-App-29x29@2x.png
sips -z 87 87 $icon_file --out ios_icon.iconset/Icon-App-29x29@3x.png
sips -z 40 40 $icon_file --out ios_icon.iconset/Icon-App-40x40@1x.png
sips -z 80 80 $icon_file --out ios_icon.iconset/Icon-App-40x40@2x.png
sips -z 120 120 $icon_file --out ios_icon.iconset/Icon-App-40x40@3x.png
sips -z 120 120 $icon_file --out ios_icon.iconset/Icon-App-60x60@2x.png
sips -z 180 180 $icon_file --out ios_icon.iconset/Icon-App-60x60@3x.png
sips -z 76 76 $icon_file --out ios_icon.iconset/Icon-App-76x76@1x.png
sips -z 152 152 $icon_file --out ios_icon.iconset/Icon-App-76x76@2x.png
sips -z 167 167 $icon_file --out ios_icon.iconset/Icon-App-83.5x83.5@2x.png

cp ios_icon.iconset/* ios/Runner/Assets.xcassets/AppIcon.appiconset/

# Create MacOS app icons
mkdir macos_icon.iconset
sips -z 16 16 $icon_file --out macos_icon.iconset/icon_16x16.png
sips -z 32 32 $icon_file --out macos_icon.iconset/icon_16x16@2x.png
sips -z 32 32 $icon_file --out macos_icon.iconset/icon_32x32.png
sips -z 64 64 $icon_file --out macos_icon.iconset/icon_32x32@2x.png
sips -z 128 128 $icon_file --out macos_icon.iconset/icon_128x128.png
sips -z 256 256 $icon_file --out macos_icon.iconset/icon_128x128@2x.png
sips -z 256 256 $icon_file --out macos_icon.iconset/icon_256x256.png
sips -z 512 512 $icon_file --out macos_icon.iconset/icon_256x256@2x.png
sips -z 512 512 $icon_file --out macos_icon.iconset/icon_512x512.png
sips -z 1024 1024 $icon_file --out macos_icon.iconset/icon_512x512@2x.png

# Copy the MacOS and iOS app icons to the respective folders
cp macos_icon.iconset/icon_16x16.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
cp macos_icon.iconset/icon_16x16@2x.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
cp macos_icon.iconset/icon_32x32.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
cp macos_icon.iconset/icon_32x32@2x.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
cp macos_icon.iconset/icon_128x128.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
cp macos_icon.iconset/icon_128x128@2x.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
cp macos_icon.iconset/icon_256x256.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
cp macos_icon.iconset/icon_256x256@2x.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
cp macos_icon.iconset/icon_512x512.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
cp macos_icon.iconset/icon_512x512@2x.png macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png

# Create Android app icons
mkdir android_icon
sips -z 48 48 $icon_file --out android_icon/drawable-mdpi/ic_launcher.png
sips -z 72 72 $icon_file --out android_icon/drawable-hdpi/ic_launcher.png
sips -z 96 96 $icon_file --out android_icon/drawable-xhdpi/ic_launcher.png
sips -z 144 144 $icon_file --out android_icon/drawable-xxhdpi/ic_launcher.png
sips -z 192 192 $icon_file --out android_icon/drawable-xxxhdpi/ic_launcher.png

cp  android_icon/drawable-mdpi/ic_launcher.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png
cp  android_icon/drawable-hdpi/ic_launcher.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
cp  android_icon/drawable-xhdpi/ic_launcher.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
cp  android_icon/drawable-xxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp  android_icon/drawable-xxxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png


# Create Windows app icons
sips -z 256 256 $icon_file --out windows/runner/resources/app_icon.ico

# Create Web
sips -z 192 192 $icon_file --out web/icons/Icon-192.png
sips -z 192 192 $icon_file --out web/icons/Icon-maskable-192.png
sips -z 512 512 $icon_file --out web/icons/Icon-512.png
sips -z 512 512 $icon_file --out web/icons/Icon-maskable-512.png

rm -rf android_icon
rm -rf macos_icon.iconset
rm -rf ios_icon.iconset
rm -rf windows_icon
