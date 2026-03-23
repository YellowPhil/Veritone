# macOS Veritone — optional: set DEVELOPER_DIR or XCODE_APP (latter becomes …/Contents/Developer)
root := justfile_directory()
derived-data := root + '/.derivedData'
app := derived-data + '/Build/Products/Debug/Veritone.app'

# Build Debug for macOS (SwiftPM packages resolve via Xcode)
build:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "${DEVELOPER_DIR:-}" && -n "${XCODE_APP:-}" ]]; then
        export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
    fi
    cd '{{ root }}'
    xcodebuild \
        -project Veritone.xcodeproj \
        -scheme Veritone \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath '{{ derived-data }}' \
        build

# Build (if needed) and open the app
run: build
    open '{{ app }}'
