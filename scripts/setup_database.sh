#!/bin/bash

#
# This script expects the user to be "admin" and postgres container already running
#

# Execute deploy_all.sql file
docker exec -w /etc/eleados/ -it postgres psql -U admin -d Eleados -f /etc/eleados/deploy_all.sql
