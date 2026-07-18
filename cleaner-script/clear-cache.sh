#!/bin/bash

# Linux VPS cache cleaner
# Logs actions to /var/log/cleanall.log

echo "==================================" >> /var/log/cleanall.log
echo "Cache cleanup started: $(date)" >> /var/log/cleanall.log

# Sync filesystem buffers
sync

# Drop pagecache, dentries, and inodes
echo 3 > /proc/sys/vm/drop_caches

# Clear systemd journal logs older than 7 days
journalctl --vacuum-time=7d

rm -rf /var/cache/apt/archives/*.deb

# Clear temp folders
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "Cache cleaned successfully" >> /var/log/cleanall.log
