#!/bin/bash

echo "Starting release validation..."

REQUIRED_FILES=(
    "app/index.html"
    "config/release-policy.txt"
    "docs/release-notes.md"
)

VALIDATION_FAILED=0

for FILE in "${REQUIRED_FILES[@]}"
do
    if [ ! -f "$FILE" ]; then
        echo "ERROR: Missing file: $FILE"
        VALIDATION_FAILED=1

    elif [ ! -s "$FILE" ]; then
        echo "ERROR: File is empty: $FILE"
        VALIDATION_FAILED=1

    else
        echo "SUCCESS: $FILE exists and is not empty"
    fi
done

if [ "$VALIDATION_FAILED" -ne 0 ]; then
    echo "Release validation FAILED."
    exit 1
fi

echo "Release validation PASSED."
exit 0
