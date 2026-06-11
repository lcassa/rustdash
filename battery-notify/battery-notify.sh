#!/bin/sh
# Low-battery notifier. Reads the battery level from sysfs, and sends a desktop
# notification (via notify-send/dunst) once when crossing the warning (10%) and
# critical (5%) thresholds while discharging. Meant to be run periodically by a
# systemd user timer; it does nothing and exits between runs (no resident
# process). State is kept in tmpfs ($XDG_RUNTIME_DIR) to avoid disk writes.

set -eu

BAT_DIR=/sys/class/power_supply/qcom-battmgr-bat

# Thresholds are overridable via the environment to make testing easy.
THRESHOLD_WARN=${THRESHOLD_WARN:-10}
THRESHOLD_CRIT=${THRESHOLD_CRIT:-5}

STATE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/battery-notify.state"

# Bail out quietly if the battery is not present (e.g. on a desktop).
[ -r "$BAT_DIR/capacity" ] || exit 0

cap=$(cat "$BAT_DIR/capacity")
status=$(cat "$BAT_DIR/status")

# Last notified level: empty | "10" | "5".
level=""
[ -f "$STATE" ] && level=$(cat "$STATE")

notify() {
    # $1 = urgency tag for the message, $2 = title, $3 = body
    notify-send -u critical -a Battery \
        -h string:x-dunst-stack-tag:battery \
        -h "int:value:$cap" \
        "$2" "$3"
}

if [ "$status" = "Discharging" ]; then
    if [ "$cap" -le "$THRESHOLD_CRIT" ] && [ "$level" != "5" ]; then
        notify crit "🪫 Battery critical (${cap}%)" "Plug in the charger NOW."
        printf '5' > "$STATE"
    elif [ "$cap" -le "$THRESHOLD_WARN" ] && [ "$level" != "10" ] && [ "$level" != "5" ]; then
        notify warn "🔋 Battery low (${cap}%)" "Plug in the charger."
        printf '10' > "$STATE"
    fi
else
    # Charging/full/etc.: re-arm for the next discharge cycle.
    rm -f "$STATE"
fi

# Re-arm once the battery climbs back above the warning threshold.
if [ "$cap" -gt "$THRESHOLD_WARN" ]; then
    rm -f "$STATE"
fi
