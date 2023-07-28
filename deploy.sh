#!/bin/bash

# check arg number
check_args () {
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 user host"
        exit 1
    fi
}

# build and deploy for macos
build_deploy_mac() {
    local user="$1"
    local host="$2"
    echo "Starting Build and Deploy for MacOS..."
    flutter build macos --release
    rm build/macos/Build/Products/Release/chitchat.dmg
    hdiutil create -format UDZO -srcfolder build/macos/Build/Products/Release/chitchat.app build/macos/Build/Products/Release/chitchat.dmg
    cp build/macos/Build/Products/Release/chitchat.dmg ~/Downloads
    scp ~/Downloads/chitchat.dmg "${user}@${host}:/mnt/backup_ssf/chitchat/download/"
    echo "MacOS Build and Deploy Complete."
}

# build and deploy for web
build_deploy_web() {
    local user="$1"
    local host="$2"
    echo "Starting Build and Deploy for Web..."
    flutter build web
    gsed -i "/base href=\"\/\"/s/\//.\//g" build/web/index.html
    cp -a build/web website/
    scp -r website/* "${user}@${host}:/mnt/backup_ssf/chitchat/"
    echo "Web Build and Deploy Complete."
}

# build and deploy for android
build_deploy_android() {
    local user="$1"
    local host="$2"
    echo "Starting Build and Deploy for Android..."
    flutter build apk  --release
    flutter build appbundle  --release
    scp build/app/outputs/flutter-apk/app-release.apk ${user}@${host}:/mnt/backup_ssf/chitchat/download/
    echo "Android Build and Deploy Complete."
}

# Main

check_args "$@"

build_deploy_mac "$@"
build_deploy_web "$@"
build_deploy_android "$@"
