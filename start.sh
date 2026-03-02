#!/bin/bash
# Start InterVue — run from the project root

echo "Starting InterVue server on port 3001..."
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

trap "kill $SERVER_PID $WEB_PID 2>/dev/null; exit" INT TERM
wait
