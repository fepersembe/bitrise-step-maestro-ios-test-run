#!/bin/sh

set -ex

# Change to source directory
cd $BITRISE_SOURCE_DIR

# Maestro version
if [[ -z "$maestro_cli_version" ]]; then
    echo "Maestro CLI version not specified, using latest"
else
    echo "Maestro CLI version: $maestro_cli_version"
    export MAESTRO_VERSION=$maestro_cli_version;
fi

# Install maestro CLI
echo "Installing Maestro CLI"
curl -Ls "https://get.maestro.mobile.dev" | bash
export PATH="$PATH":"$HOME/.maestro/bin"
echo "MAESTRO INSTALLED - Check Version"
maestro -v

# Run Maestro Cloud
xcrun simctl install booted $app_file
xcrun simctl io booted recordVideo --codec=h264 -f $BITRISE_DEPLOY_DIR/ui_tests.mp4 &
maestro test $workspace/ --format junit --output $BITRISE_DEPLOY_DIR/test_report.xml $additional_params || true
killall -SIGINT simctl

# Export test results
# Test report file
[[ "$export_test_report" == "true" ]] && is_export="true"
if [[ "$is_export" == "true" ]]; then
    test_run_dir="$BITRISE_TEST_RESULT_DIR/maestro"
    mkdir "$test_run_dir"
    cp $BITRISE_DEPLOY_DIR/test_report.xml "$test_run_dir/maestro_report.xml"
    cp $BITRISE_DEPLOY_DIR/ui_tests.mp4 "$test_run_dir/ui_tests.mp4"
    echo '{"maestro-test-report":"Maestro Cloud Flows"}' >> "$test_run_dir/test-info.json"
fi
