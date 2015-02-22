#!/bin/bash

JAVA_CMD=$(which java)
JAR_CMD=$(which jar)
if [ -z "${JAVA_CMD}" ] || [ -z "${JAR_CMD}" ]; then
    echo This plugin requires Java. Please install it first, then come back and try again.
    exit 1
fi

pushd . > /dev/null

cd $(dirname $(pwd)/$0)/..
rm -rf ./Java

# grab the content renderer jar
echo -n "Looking for a copy of astah* community... "
ASTAH_APP=$(find /Applications -name "astah community.app" | head -n 1)

if [ -n "${ASTAH_APP}" ]; then
    echo "found at ${ASTAH_APP}."
    cp -R "${ASTAH_APP}/Contents/Java" . > /dev/null
else
    echo "not found, falling back to the Confluence plugin"
    pushd . > /dev/null

    MACRO_JAR_DIR=$(mktemp -d -t astaviewer.download)
    cd "${MACRO_JAR_DIR}"
    curl -L -o macro.jar https://marketplace.atlassian.com/download/plugins/com.change_vision.astah.astah-confluence-macro/version/55

    echo "Extracting plugin..."
    jar xf macro.jar

    popd > /dev/null

    mkdir Java
    unzip -d Java "${MACRO_JAR_DIR}/astah.zip" > /dev/null
    rm -rf "${MACRO_JAR_DIR}"
fi

popd > /dev/null

echo "AstaViewer setup completed, now go build the project!"
