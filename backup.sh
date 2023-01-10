#!/bin/bash

BACKUP_TARGET=/nfs/homelab/backup/awx/awx_export.config
TOWER_HOST=http://awx.calfolguera.com:80 TOWER_USERNAME=admin TOWER_PASSWORD=`cat password` awx export > $BACKUP_TARGET
