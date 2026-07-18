#/bin/bash
# Debian 13 Chrony Configuration

pool pool.ntp.org iburst maxsources 4

# Alternative servers
pool time.cloudflare.com iburst
pool time.google.com iburst

driftfile /var/lib/chrony/chrony.drift

makestep 1.0 3
rtcsync

minsources 2

logdir /var/log/chrony

# Uncomment for troubleshooting
# log tracking measurements statistics
