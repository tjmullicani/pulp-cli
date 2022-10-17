#!/bin/bash

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")"/config.source

pulp debug has-plugin --name "file" || exit 3

cleanup() {
  pulp file remote destroy --name "cli_test_file_remote" || true
}
trap cleanup EXIT

expect_succ pulp file remote list

expect_succ pulp file remote create --name "cli_test_file_remote" --url "$FILE_REMOTE_URL" --proxy-url "http://proxy.org" --proxy-username "user" --proxy-password "pass" --max-retries 5 --total-timeout 32
expect_succ pulp file remote show --name "cli_test_file_remote"
test "$(echo "$OUTPUT" | jq -r '.proxy_url')" = "http://proxy.org"
test "$(echo "$OUTPUT" | jq -r '.max_retries')" = "5"
test "$(echo "$OUTPUT" | jq -r '.total_timeout')" = "32"
expect_succ pulp file remote update --name "cli_test_file_remote" --proxy-url "" --proxy-username "" --proxy-password "" --max-retries "" --total-timeout ""
expect_succ pulp file remote list --name-contains "li_test_file_remot"
test "$(echo "$OUTPUT" | jq -r '.[0].proxy_url')" = "null"
test "$(echo "$OUTPUT" | jq -r '.[0].max_retries')" = "null"
test "$(echo "$OUTPUT" | jq -r '.[0].total_timeout')" = "null"
expect_succ pulp file remote destroy --name "cli_test_file_remote"

# test cert/key fields for remotes - both @file and string args
CERTFILE="$(dirname "$(realpath "$0")")"/mock.crt
KEYFILE="$(dirname "$(realpath "$0")")"/mock.key
CERT=$(cat "${CERTFILE}")
KEY=$(cat "${KEYFILE}")
expect_succ pulp file remote create --name "cli_test_file_remote" --url "$FILE_REMOTE_URL" --client-cert @"$CERTFILE" --client-key @"$KEYFILE" --ca-cert @"$CERTFILE"
expect_succ pulp file remote destroy --name "cli_test_file_remote"

expect_succ pulp file remote create --name "cli_test_file_remote" --url "$FILE_REMOTE_URL" --client-cert "$CERT" --client-key "$KEY" --ca-cert "$CERT"
expect_succ pulp file remote destroy --name "cli_test_file_remote"
