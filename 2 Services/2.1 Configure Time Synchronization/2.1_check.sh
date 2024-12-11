#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="2.1_check"
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

# 2.1.1 Ensure time synchronization is in use
id="2.1.1"
change="Ensure time synchronization is in use"

# Check if chrony is installed
if rpm -q chrony &>/dev/null; then
    log_result "$id" "Compliant" "Chrony is installed for time synchronization."
else
    log_result "$id" "Non-compliant" "Chrony is not installed. Time synchronization may not be in use."
fi

# 2.1.2 Ensure chrony is configured
id="2.1.2"
change="Ensure chrony is configured"

# Check if chrony is configured
chrony_configured=$(grep -Prs -- '^\h*(server|pool)\h+[^#\n\r]+' /etc/chrony.conf /etc/chrony.d/ 2>/dev/null)

if [[ -n "$chrony_configured" ]]; then
    log_result "$id" "Compliant" "Chrony is configured with the following servers/pools:\n$chrony_configured"
else
    log_result "$id" "Non-compliant" "Chrony is not configured with any server or pool."
fi

# 2.1.3 Ensure chrony is not run as the root user
id="2.1.3"
change="Ensure chrony is not run as the root user"

# Check if chrony is configured to run as the root user
chrony_root_check=$(grep -Psi -- '^\h*OPTIONS=\"?\h+-u\h+root\b' /etc/sysconfig/chronyd 2>/dev/null)

if [[ -z "$chrony_root_check" ]]; then
    log_result "$id" "Compliant" "Chrony is not configured to run as the root user."
else
    log_result "$id" "Non-compliant" "Chrony is configured to run as the root user:\n$chrony_root_check"
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"