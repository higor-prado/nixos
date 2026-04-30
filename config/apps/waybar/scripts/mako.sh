#!/usr/bin/env bash

update_mako() {
    COUNT=$(makoctl list | grep -c "^Notification")
    ENABLED=
    DISABLED=
    if [ "$COUNT" != 0 ]; then DISABLED="$COUNT  "; fi
    if makoctl mode | grep -q "do-not-disturb" ; then
        echo "$DISABLED"
    else
        echo "$ENABLED"
    fi
}

# Initial update
update_mako

# Listen for DBus events in a blocking loop
dbus-monitor "interface='org.freedesktop.Notifications'" | while read -r line; do
    if [[ "$line" == *"member=Notify"* || "$line" == *"member=CloseNotification"* || "$line" == *"member=ActionInvoked"* ]]; then
        update_mako
    fi
done
