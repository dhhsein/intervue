#!/bin/bash
# Start InterVue as a production web app — run from the project root

# Clear ports 3001 and 8080 in case a previous run left them occupied
lsof -ti:3001 | xargs kill -9 2>/dev/null
lsof -ti:8080 | xargs kill -9 2>/dev/null

cleanup() {
  echo ""
  echo "Shutting down InterVue..."
  kill -- -$SERVER_PID 2>/dev/null
  kill -- -$WEB_PID 2>/dev/null
  lsof -ti:3001 | xargs kill -9 2>/dev/null
  lsof -ti:8080 | xargs kill -9 2>/dev/null
  exit 0
}

trap cleanup INT TERM

echo "Starting InterVue server on port 3001..."
set -m
(cd server && dart run bin/server.dart --data-dir ~/intervue_data) &
SERVER_PID=$!

sleep 2

echo "Serving production web app on port 8080..."
dhttpd --path build/web --port 8080 &
WEB_PID=$!

echo ""
echo "InterVue is running:"
echo "  Server: http://localhost:3001"
echo "  App:    http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop both."

wait
