# Podman-tui functionality tests with bats

## Running tests

To run the tests locally in your remote sandbox node (e.g. frawhide), you can use one of these methods:

* Make podman-tui binary

    ```shell
    $ make binary
    ```

* Add default podman remote connection URI (test host)

    ```shell
    $ sudo podman system connection add --default --identity /root/.ssh/id_ed25519 frawhide root@frawhide
    ```

* Reset podman system on remote test host

    ```shell
    sudo podman system reset
    ```

* Start podman service on remote test host

    ```shell
    sudo systemctl start podman.socket
    ```

* Run functionality tests

    ```shell
    sudo make test-functionality
    ```

## Requirements
- if you are not in root directory of the project, be sure `PODMAN_TUI` variable is set
- access to repository to pull busybox and httpd image
- tmux
