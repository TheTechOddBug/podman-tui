#!/usr/bin/env bats
#
# podman-tui system view functionality tests
#

load helpers
load helpers_tui

@test "system add" {
    check_skip "system_add"

    default_conn=$(jq .Connection.Default ${PODMAN_CONNECTIONS_CONFIG} | sed 's/"//g')
    default_conn_uri=$(jq .Connection.Connections.${default_conn}.URI ${PODMAN_CONNECTIONS_CONFIG} | sed 's/"//g')
    default_conn_identity=$(jq .Connection.Connections.${default_conn}.Identity ${PODMAN_CONNECTIONS_CONFIG} | sed 's/"//g')

    # switch to system view
    # select add connection
    # fillout name field
    # fillout URI field
    # go to Add button and press Enter
    podman_tui_set_view "system"
    podman_tui_select_system_cmd "add"
    podman_tui_send_inputs $TEST_SYSTEM_CONN_NAME
    podman_tui_send_inputs "Tab"
    podman_tui_send_inputs $default_conn_uri
    podman_tui_send_inputs "Tab"
    podman_tui_send_inputs $default_conn_identity
    podman_tui_send_inputs "Tab" "Tab" "Enter"
    sleep $TEST_TIMEOUT_LOW

    run_helper jq ".Connection.Connections.${TEST_SYSTEM_CONN_NAME}.URI" ${PODMAN_CONNECTIONS_CONFIG}
    assert "$output" == "\"$default_conn_uri\"" "expected ${default_conn_uri} in configuration"
}

@test "system remove" {
    check_skip "system_remove"

    conn_index=$(${PODMAN_CMD} system connection list -f json | jq -r '.[].Name' | nl | grep -E "[[:digit:]]+[[:space:]]+${TEST_SYSTEM_CONN_NAME}$" | awk '{print $1}')
    conn_index=$((conn_index -1 ))

    # switch to system view
    # select localhost_test connection name
    # select "remove connection" command
    # confirm connection removal
    podman_tui_set_view "system"
    podman_tui_select_item ${conn_index}
    podman_tui_select_system_cmd "remove"
    podman_tui_send_inputs "Enter"
    sleep $TEST_TIMEOUT_LOW

    run_helper jq ".Connection.Connections.${TEST_SYSTEM_CONN_NAME}" ${PODMAN_CONNECTIONS_CONFIG}
    assert "$output" == "null" "expected ${TEST_SYSTEM_CONN_NAME} connection to be removed from config"
}

@test "system connect" {
    check_skip "system_connect"

    default_conn=$(jq .Connection.Default ${PODMAN_CONNECTIONS_CONFIG} | sed 's/"//g')
    default_conn_uri=$(jq .Connection.Connections.${default_conn}.URI ${PODMAN_CONNECTIONS_CONFIG} | sed 's/"//g')
    default_conn_identity=$(jq .Connection.Connections.${default_conn}.Identity ${PODMAN_CONNECTIONS_CONFIG} | sed 's/"//g')

    podman system connection add --identity ${default_conn_identity} ${TEST_SYSTEM_CONN_NAME} ${default_conn_uri}

    conn_index=$(${PODMAN_CMD} system connection list -f json | jq -r '.[].Name' | nl | grep -E "[[:digit:]]+[[:space:]]+${TEST_SYSTEM_CONN_NAME}$" | awk '{print $1}')
    conn_index=$((conn_index -1 ))
    row_index=$((conn_index + 7))

    # switch to system view
    # select "disconnect" command
    podman_tui_set_view "system"
    podman_tui_select_system_cmd "disconnect"
    sleep $TEST_TIMEOUT_LOW
    run_helper tmux capture-pane -pS 0 -E 0
    assert "$output" =~ "DISCONNECTED" "expected DISCONNECTED connection status"

    # select "connect" command
    podman_tui_select_item ${conn_index}
    podman_tui_select_system_cmd "connect"
    sleep $TEST_TIMEOUT_LOW
    run_helper tmux capture-pane -pS 0 -E 0
    assert "$output" =~ "STATUS_OK" "expected STATUS_OK connection status"

    run_helper tmux capture-pane -pS ${row_index} -E ${row_index}
    assert "$output" =~ "connected" "expected connected connection status"
}

@test "system disconnect" {
    check_skip "system_disconnect"

    # switch to system view
    # select "disconnect" command
    podman_tui_set_view "system"
    podman_tui_select_system_cmd "disconnect"
    sleep $TEST_TIMEOUT_LOW

    run_helper tmux capture-pane -pS 0 -E 0
    assert "$output" =~ "DISCONNECTED" "expected DISCONNECTED connection status"

    run_helper tmux capture-pane -pS 7 -E 7
    assert "$output" !~ "connected" "expected empty connection status"
}

@test "system set default" {
    check_skip "system_default"

    current_default_conn=$(jq .Connection.Default ${PODMAN_CONNECTIONS_CONFIG} | sed 's/"//g')

    conn_index=$(${PODMAN_CMD} system connection list -f json | jq -r '.[].Name' | nl | grep -E "[[:digit:]]+[[:space:]]+${TEST_SYSTEM_CONN_NAME}$" | awk '{print $1}')
    conn_index=$((conn_index -1 ))

    # switch to system view
    # select localhost_test connection name
    # select "set default" command
    podman_tui_set_view "system"
    podman_tui_select_item ${conn_index}
    podman_tui_select_system_cmd "default"
    sleep $TEST_TIMEOUT_LOW

    default_conn=$(jq .Connection.Default ${PODMAN_CONNECTIONS_CONFIG})

    run_helper jq .Connection.Default ${PODMAN_CONNECTIONS_CONFIG}

    podman system connection default ${current_default_conn}

    assert "$output" == "\"$TEST_SYSTEM_CONN_NAME\"" "expected ${TEST_SYSTEM_CONN_NAME} as default connection"
}
