#!/bin/bash

#
# This script expects the user to be "admin" and postgres container already running
#

# Execute deploy_all.sql file
docker exec -it postgres psql -U admin -f /etc/eleados/deploy_all.sql
