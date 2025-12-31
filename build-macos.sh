#!/bin/bash

set -euo pipefail

# By default we configure signing from .env. Set SKIP_CONFIGURE=1 to skip.
SKIP_CONFIGURE=${SKIP_CONFIGURE:-0}

if [[ "$SKIP_CONFIGURE" != "1" && -f "./configure.sh" ]]; then
  ./configure.sh
fi

CONFIGURATION=${CONFIGURATION:-Debug}
SCHEME=${SCHEME:-"AI Shortcuts"}
DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-build/DerivedData}
DESTINATION=${DESTINATION:-"platform=macOS"}
RUN=${RUN:-1}

echo "Building AI Shortcuts for macOS..."
xcodebuild -project "AI Shortcuts.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -destination "$DESTINATION" \
  build

echo "Build complete!"

if [[ "$RUN" == "1" ]]; then
  APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/AI Shortcuts.app"
  echo "Launching app: $APP_PATH"
  open "$APP_PATH"
fi

