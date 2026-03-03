#!/bin/bash
# Start InterVue — run from the project root

# Clear port 3001 in case a previous run left it occupied
lsof -ti:3001 | xargs kill -9 2>/dev/null

cleanup() {
  echo ""
  echo "Shutting down InterVue..."
  # Kill entire process groups so child processes (dart, flutter) are included
  kill -- -$SERVER_PID 2>/dev/null
  kill -- -$WEB_PID 2>/dev/null
  # As a fallback, kill anything still on port 3001
  lsof -ti:3001 | xargs kill -9 2>/dev/null
  exit 0
}

trap cleanup INT TERM

echo "Starting InterVue server on port 3001..."
# Use set -m (job control) so background jobs get their own process groups
set -m
(cd server && dart run bin/server.dart --data-dir ~/intervue_data) &
SERVER_PID=$!

sleep 2

echo "Starting Flutter web app..."
flutter run -d chrome &
WEB_PID=$!

echo ""
echo "InterVue is running:"
echo "  Server: http://localhost:3001"
echo "  App: Flutter web (Chrome)"
echo ""
echo "Press Ctrl+C to stop both."

wait
