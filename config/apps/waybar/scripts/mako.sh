#!/usr/bin/env bash
COUNT=$(makoctl list | grep -c "^Notification")
ENABLED=
DISABLED=
if [ "$COUNT" != 0 ]; then DISABLED="$COUNT  "; fi
if makoctl mode | grep -q "do-not-disturb" ; then echo "$DISABLED"; else echo "$ENABLED"; fi
