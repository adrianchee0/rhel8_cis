#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.7_check"
LOG_ID=$(ls ${LOG_DIR}/${LOG_PREFIX}_*.log 2>/dev/null | awk -F '_' '{print $NF}' | awk -F '.' '{print $1}' | sort -n | tail -1)
LOG_ID=$(printf "%03d" $((LOG_ID + 1)))
LOG_FILE="${LOG_DIR}/${LOG_PREFIX}_${LOG_ID}.log"

# Function to log results
log_result() {
    local id=$1
    local status=$2
    local reason=$3
    echo -e "${id} - ${status}\nReason: ${reason}\n" >> "$LOG_FILE"
}

# 1.7.1 Ensure message of the day is configured properly
id="1.7.1"
change="Ensure message of the day (MOTD) is configured properly"

# Check contents of /etc/motd against site policy
motd_content=$(cat /etc/motd 2>/dev/null)
motd_os_info_check=$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/motd 2>/dev/null)

if [[ -z "$motd_os_info_check" ]]; then
    log_result "$id" "Compliant" "MOTD is configured properly and does not contain OS or version information."
else
    details="MOTD contains prohibited system information:\n"
    details+=$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/motd | sed 's/^/ - /')
    log_result "$id" "Non-compliant" "MOTD contains OS or version information.\n$details"
fi

# 1.7.2 Ensure local login warning banner is configured properly
id="1.7.2"
change="Ensure local login warning banner is configured properly"

# Check contents of /etc/issue against site policy
issue_content=$(cat /etc/issue 2>/dev/null)
issue_os_info_check=$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/issue 2>/dev/null)

if [[ -z "$issue_os_info_check" ]]; then
    log_result "$id" "Compliant" "Local login warning banner is configured properly and does not contain OS or version information."
else
    details="Local login banner contains prohibited system information:\n"
    details+=$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/issue | sed 's/^/ - /')
    log_result "$id" "Non-compliant" "Local login banner contains OS or version information.\n$details"
fi

# 1.7.3 Ensure remote login warning banner is configured properly
id="1.7.3"
change="Ensure remote login warning banner is configured properly"

# Check contents of /etc/issue.net against site policy
issue_net_content=$(cat /etc/issue.net 2>/dev/null)
issue_net_os_info_check=$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/issue.net 2>/dev/null)

if [[ -z "$issue_net_os_info_check" ]]; then
    log_result "$id" "Compliant" "Remote login warning banner is configured properly and does not contain OS or version information."
else
    details="Remote login banner contains prohibited system information:\n"
    details+=$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/issue.net | sed 's/^/ - /')
    log_result "$id" "Non-compliant" "Remote login banner contains OS or version information.\n$details"
fi

# 1.7.4 Ensure access to /etc/motd is configured
id="1.7.4"
change="Ensure access to /etc/motd is configured"

if [ -e /etc/motd ]; then
    # Get file permissions, UID, and GID for /etc/motd
    motd_stat=$(stat -Lc '%a %u %g' /etc/motd)
    motd_perms=$(echo "$motd_stat" | awk '{print $1}')
    motd_uid=$(echo "$motd_stat" | awk '{print $2}')
    motd_gid=$(echo "$motd_stat" | awk '{print $3}')
    
    # Check if permissions are 644 or more restrictive, and UID and GID are both 0 (root)
    if [[ "$motd_perms" -le 644 && "$motd_uid" -eq 0 && "$motd_gid" -eq 0 ]]; then
        log_result "$id" "Compliant" "/etc/motd permissions are correctly configured.\nAccess: ($motd_perms/-rw-r--r--) Uid: ($motd_uid/root) Gid: ($motd_gid/root)"
    else
        log_result "$id" "Non-compliant" "/etc/motd permissions are incorrectly configured.\nAccess: ($motd_perms) Uid: ($motd_uid) Gid: ($motd_gid)"
    fi
else
    log_result "$id" "Compliant" "/etc/motd does not exist."
fi

# 1.7.5 Ensure access to /etc/issue is configured
id="1.7.5"
change="Ensure access to /etc/issue is configured"

if [ -e /etc/issue ]; then
    # Get file permissions, UID, and GID for /etc/issue
    issue_stat=$(stat -Lc '%a %u %g' /etc/issue)
    issue_perms=$(echo "$issue_stat" | awk '{print $1}')
    issue_uid=$(echo "$issue_stat" | awk '{print $2}')
    issue_gid=$(echo "$issue_stat" | awk '{print $3}')
    
    # Check if permissions are 644 or more restrictive, and UID and GID are both 0 (root)
    if [[ "$issue_perms" -le 644 && "$issue_uid" -eq 0 && "$issue_gid" -eq 0 ]]; then
        log_result "$id" "Compliant" "/etc/issue permissions are correctly configured.\nAccess: ($issue_perms/-rw-r--r--) Uid: ($issue_uid/root) Gid: ($issue_gid/root)"
    else
        log_result "$id" "Non-compliant" "/etc/issue permissions are incorrectly configured.\nAccess: ($issue_perms) Uid: ($issue_uid) Gid: ($issue_gid)"
    fi
else
    log_result "$id" "Compliant" "/etc/issue does not exist."
fi

# 1.7.6 Ensure access to /etc/issue.net is configured
id="1.7.6"
change="Ensure access to /etc/issue.net is configured"

if [ -e /etc/issue.net ]; then
    # Get file permissions, UID, and GID for /etc/issue.net
    issue_net_stat=$(stat -Lc '%a %u %g' /etc/issue.net)
    issue_net_perms=$(echo "$issue_net_stat" | awk '{print $1}')
    issue_net_uid=$(echo "$issue_net_stat" | awk '{print $2}')
    issue_net_gid=$(echo "$issue_net_stat" | awk '{print $3}')
    
    # Check if permissions are 644 or more restrictive, and UID and GID are both 0 (root)
    if [[ "$issue_net_perms" -le 644 && "$issue_net_uid" -eq 0 && "$issue_net_gid" -eq 0 ]]; then
        log_result "$id" "Compliant" "/etc/issue.net permissions are correctly configured.\nAccess: ($issue_net_perms/-rw-r--r--) Uid: ($issue_net_uid/root) Gid: ($issue_net_gid/root)"
    else
        log_result "$id" "Non-compliant" "/etc/issue.net permissions are incorrectly configured.\nAccess: ($issue_net_perms) Uid: ($issue_net_uid) Gid: ($issue_net_gid)"
    fi
else
    log_result "$id" "Compliant" "/etc/issue.net does not exist."
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"