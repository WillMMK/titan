#!/bin/bash

# Check if Titan's NOTICE file has been modified
NOTICE_FILE="third_party/titan/NOTICE"
NOTICE_SIZE=$(stat -f%z "$NOTICE_FILE" 2>/dev/null || stat -c%s "$NOTICE_FILE")

if [ "$NOTICE_SIZE" -gt 0 ]; then
    echo "Error: Titan's NOTICE file has been modified. Please check for updates."
    exit 1
fi

echo "Titan NOTICE file check passed."
exit 0 