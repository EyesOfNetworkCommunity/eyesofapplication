#!/bin/sh
find /srv/eyesofnetwork/eon4apps/html/*.* -mmin +1440 -exec rm -rf {} \;
exit 0

