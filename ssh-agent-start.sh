#!/bin/sh

set -eu
umask 077

socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sway-ssh-agent.sock"
export SSH_AUTH_SOCK="$socket"

# ssh-add -l exits with 1 when the agent is running but has no keys.
if ssh-add -l >/dev/null 2>&1; then
    :
else
    status=$?
    if [ "$status" -ne 1 ]; then
        # A crashed agent can leave its socket behind.
        if [ -S "$socket" ]; then
            rm -- "$socket"
        fi
        ssh-agent -a "$socket" >/dev/null
    fi
fi

# Make the socket available to applications started through D-Bus or systemd.
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd SSH_AUTH_SOCK >/dev/null || \
        printf 'Could not publish SSH_AUTH_SOCK to D-Bus/systemd\n' >&2
fi

# Match private key files by their header, including keys with custom names.
for key in "$HOME"/.ssh/*; do
    [ -f "$key" ] && [ -r "$key" ] || continue
    IFS= read -r header < "$key" || continue
    case "$header" in
        '-----BEGIN '*'PRIVATE KEY-----')
            if [ -x /usr/libexec/seahorse/ssh-askpass ]; then
                SSH_ASKPASS=/usr/libexec/seahorse/ssh-askpass \
                    SSH_ASKPASS_REQUIRE=force ssh-add "$key" || \
                    printf 'Could not add SSH key: %s\n' "$key" >&2
            else
                ssh-add "$key" || \
                    printf 'Could not add SSH key: %s\n' "$key" >&2
            fi
            ;;
    esac
done
