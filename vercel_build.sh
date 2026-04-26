#!/bin/bash

# Clone the stable channel of the Flutter repository
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to the system path
export PATH="$PATH:`pwd`/flutter/bin"

# Pre-download development binaries
flutter precache

# Build the app for the web with the provided Vercel environment variables
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
