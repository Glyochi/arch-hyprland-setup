#!/bin/sh
set -eu

WAKEALARM="/sys/class/rtc/rtc0/wakealarm"
STATE_DIR="/run/poweroff-after-suspend"
DEADLINE_FILE="$STATE_DIR/deadline"
DELAY_SEC=7200
TOLERANCE_SEC=120

log() {
    logger -t poweroff-after-suspend "$*"
}

case "${1:-}" in
    pre)
        [ "${2:-}" = "suspend" ] || exit 0
        [ -w "$WAKEALARM" ] || {
            log "wakealarm not writable; skipping"
            exit 0
        }

        # Setup directory
        mkdir -p "$STATE_DIR"
        # Get shutdown time
        now="$(date +%s)"
        deadline="$((now + DELAY_SEC))"
        # Save to disk 
        printf '%s\n' "$deadline" > "$DEADLINE_FILE"

        # Clear alarm and set new alarm
        printf '0\n' > "$WAKEALARM" || true
        printf '%s\n' "$deadline" > "$WAKEALARM"
        log "scheduled rtc wake in ${DELAY_SEC}s"
        ;;
    post)
        [ "${2:-}" = "suspend" ] || exit 0
        [ -f "$DEADLINE_FILE" ] || exit 0

        # Get scheduled shutdown
        deadline="$(cat "$DEADLINE_FILE")"
        # Remove deadline
        rm -f "$DEADLINE_FILE"
        # Remove alarm
        printf '0\n' > "$WAKEALARM" || true

        # Check if woke up early (by user)
        # Or woke up on time for shutdown (by alarm)
        now="$(date +%s)"
        if [ "$now" -ge "$((deadline - TOLERANCE_SEC))" ]; then
            log "deadline reached; powering off"
            systemd-run --unit=poweroff-after-suspend --on-active=5s /usr/bin/systemctl poweroff
        else
            log "resumed early; canceled poweroff"
        fi
        ;;
esac
