#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.5.1_check"
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

# 1.5.1.1 Ensure SELinux is installed
id="1.5.1.1"
change="Ensure SELinux is installed"

# Check if SELinux packages are installed
if rpm -q libselinux &>/dev/null; then
    log_result "$id" "Compliant" "SELinux is installed. Package found: $(rpm -q libselinux)"
else
    log_result "$id" "Non-compliant" "SELinux is not installed. Package libselinux is missing."
fi

# 1.5.1.2 Ensure SELinux is not disabled in bootloader configuration
id="1.5.1.2"
change="Ensure SELinux is not disabled in bootloader configuration"

# Check if SELinux is disabled in the bootloader
if grubby --info=ALL | grep -Po '(selinux|enforcing)=0\b' &>/dev/null; then
    log_result "$id" "Non-compliant" "SELinux is disabled in the bootloader configuration. Check grub boot parameters."
else
    log_result "$id" "Compliant" "SELinux is not disabled in the bootloader configuration. No selinux=0 or enforcing=0 parameters found."
fi

# 1.5.1.3 Ensure SELinux policy is configured
id="1.5.1.3"
change="Ensure SELinux policy is configured"

# Check SELinux policy configuration
selinux_configured=$(grep -E '^\s*SELINUXTYPE=(targeted|mls)\b' /etc/selinux/config)
sestatus_policy=$(sestatus | grep 'Loaded policy name' | awk '{print $NF}')

if [[ "$selinux_configured" =~ SELINUXTYPE=(targeted|mls) ]] && [[ "$sestatus_policy" =~ ^(targeted|mls)$ ]]; then
    log_result "$id" "Compliant" "SELinux policy is configured correctly.\nSELinux Config: $selinux_configured\nLoaded Policy: $sestatus_policy"
else
    log_result "$id" "Non-compliant" "SELinux policy is not configured correctly.\nSELinux Config: $selinux_configured\nLoaded Policy: $sestatus_policy"
fi

# 1.5.1.4 Ensure the SELinux mode is not disabled
id="1.5.1.4"
change="Ensure the SELinux mode is not disabled"

# Check SELinux current and configured modes
current_mode=$(getenforce)
configured_mode=$(grep -Ei '^\s*SELINUX=(enforcing|permissive)' /etc/selinux/config | awk -F= '{print $2}' | xargs)

if [[ "$current_mode" =~ ^(Enforcing|Permissive)$ ]] && [[ "$configured_mode" =~ ^(enforcing|permissive)$ ]]; then
    log_result "$id" "Compliant" "SELinux mode is not disabled.\nCurrent Mode: $current_mode\nConfigured Mode: $configured_mode"
else
    log_result "$id" "Non-compliant" "SELinux mode is disabled or misconfigured.\nCurrent Mode: $current_mode\nConfigured Mode: $configured_mode"
fi

# 1.5.1.5 Ensure the SELinux mode is enforcing
id="1.5.1.5"
change="Ensure the SELinux mode is enforcing"

# Check SELinux current and configured modes
current_mode=$(getenforce)
configured_mode=$(grep -i '^\s*SELINUX=enforcing' /etc/selinux/config | awk -F= '{print $2}' | xargs)

if [[ "$current_mode" == "Enforcing" ]] && [[ "$configured_mode" == "enforcing" ]]; then
    log_result "$id" "Compliant" "SELinux is in enforcing mode.\nCurrent Mode: $current_mode\nConfigured Mode: $configured_mode"
else
    log_result "$id" "Non-compliant" "SELinux is not in enforcing mode.\nCurrent Mode: $current_mode\nConfigured Mode: $configured_mode"
fi

# 1.5.1.6 Ensure no unconfined services exist
id="1.5.1.6"
change="Ensure no unconfined services exist"

# Check for unconfined services
unconfined_services=$(ps -eZ | grep -w unconfined_service_t)

if [[ -z "$unconfined_services" ]]; then
    log_result "$id" "Compliant" "No unconfined services exist."
else
    log_result "$id" "Non-compliant" "Unconfined services found.\nDetails: $unconfined_services"
fi

# 1.5.1.7 Ensure the MCS Translation Service (mcstrans) is not installed
id="1.5.1.7"
change="Ensure the MCS Translation Service (mcstrans) is not installed"

# Check if mcstrans is installed
mcstrans_installed=$(rpm -q mcstrans)

if [[ "$mcstrans_installed" == "package mcstrans is not installed" ]]; then
    log_result "$id" "Compliant" "The MCS Translation Service (mcstrans) is not installed."
else
    log_result "$id" "Non-compliant" "The MCS Translation Service (mcstrans) is installed.\nDetails: $mcstrans_installed"
fi

# 1.5.1.8 Ensure SETroubleshoot is not installed
id="1.5.1.8"
change="Ensure SETroubleshoot is not installed"

# Check if setroubleshoot is installed
setroubleshoot_installed=$(rpm -q setroubleshoot)

if [[ "$setroubleshoot_installed" == "package setroubleshoot is not installed" ]]; then
    log_result "$id" "Compliant" "SETroubleshoot is not installed."
else
    log_result "$id" "Non-compliant" "SETroubleshoot is installed.\nDetails: $setroubleshoot_installed"
fi


# Indicate log file creation
echo "Log file created at: $LOG_FILE"