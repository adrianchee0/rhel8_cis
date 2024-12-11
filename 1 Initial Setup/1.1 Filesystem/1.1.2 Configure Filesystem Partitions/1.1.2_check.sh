#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.1.2_check"
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

# 1.1.2.1.1 Ensure /tmp is a separate partition
id="1.1.2.1.1"
change="Ensure /tmp is a separate partition"

# Check if /tmp is a separate partition
findmnt_output=$(findmnt -nk /tmp 2>/dev/null)
systemd_output=$(systemctl is-enabled tmp.mount 2>/dev/null)

if [[ -n "$findmnt_output" ]]; then
    # /tmp is mounted
    if [[ "$systemd_output" != "masked" && "$systemd_output" != "disabled" ]]; then
        log_result "$id" "Compliant" "/tmp is a separate partition and systemd configuration is valid.\nFindmnt Output: $findmnt_output\nSystemd Output: $systemd_output"
    else
        log_result "$id" "Non-compliant" "/tmp is mounted but systemd configuration is not valid.\nFindmnt Output: $findmnt_output\nSystemd Output: $systemd_output"
    fi
else
    # /tmp is not mounted
    log_result "$id" "Non-compliant" "/tmp is not a separate partition.\nSystemd Output: $systemd_output"
fi

# 1.1.2.1.2 Ensure nodev option set on /tmp partition
id="1.1.2.1.2"
change="Ensure nodev option set on /tmp partition"

# Check if nodev option is set
if findmnt -kn /tmp | grep -q nodev; then
    log_result "$id" "Compliant" "The nodev option is set on /tmp partition."
else
    log_result "$id" "Non-compliant" "The nodev option is not set on /tmp partition."
fi

# 1.1.2.1.3 Ensure nosuid option set on /tmp partition
id="1.1.2.1.3"
change="Ensure nosuid option set on /tmp partition"

# Check if nosuid option is set
if findmnt -kn /tmp | grep -q nosuid; then
    log_result "$id" "Compliant" "The nosuid option is set on /tmp partition."
else
    log_result "$id" "Non-compliant" "The nosuid option is not set on /tmp partition."
fi

# 1.1.2.1.4 Ensure noexec option set on /tmp partition
id="1.1.2.1.4"
change="Ensure noexec option set on /tmp partition"

# Check if noexec option is set
if findmnt -kn /tmp | grep -q noexec; then
    log_result "$id" "Compliant" "The noexec option is set on /tmp partition."
else
    log_result "$id" "Non-compliant" "The noexec option is not set on /tmp partition."
fi

# 1.1.2.2.1 Ensure /dev/shm is a separate partition
id="1.1.2.2.1"
change="Ensure /dev/shm is a separate partition"

# Check if /dev/shm is a separate partition
findmnt_output=$(findmnt -nk /dev/shm 2>/dev/null)
if [[ -n "$findmnt_output" ]]; then
    log_result "$id" "Compliant" "/dev/shm is a separate partition.\nFindmnt Output: $findmnt_output"
else
    log_result "$id" "Non-compliant" "/dev/shm is not a separate partition."
fi

# 1.1.2.2.2 Ensure nodev option set on /dev/shm partition
id="1.1.2.2.2"
change="Ensure nodev option set on /dev/shm partition"

# Check if nodev option is set
if findmnt -kn /dev/shm | grep -q nodev; then
    log_result "$id" "Compliant" "The nodev option is set on /dev/shm partition."
else
    log_result "$id" "Non-compliant" "The nodev option is not set on /dev/shm partition."
fi

# 1.1.2.2.3 Ensure nosuid option set on /dev/shm partition
id="1.1.2.2.3"
change="Ensure nosuid option set on /dev/shm partition"

# Check if nosuid option is set
if findmnt -kn /dev/shm | grep -q nosuid; then
    log_result "$id" "Compliant" "The nosuid option is set on /dev/shm partition."
else
    log_result "$id" "Non-compliant" "The nosuid option is not set on /dev/shm partition."
fi

# 1.1.2.2.4 Ensure noexec option set on /dev/shm partition
id="1.1.2.2.4"
change="Ensure noexec option set on /dev/shm partition"

# Check if noexec option is set
if findmnt -kn /dev/shm | grep -q noexec; then
    log_result "$id" "Compliant" "The noexec option is set on /dev/shm partition."
else
    log_result "$id" "Non-compliant" "The noexec option is not set on /dev/shm partition."
fi

# 1.1.2.3.1 Ensure /home is a separate partition
id="1.1.2.3.1"
change="Ensure /home is a separate partition"

# Check if /home is a separate partition
findmnt_output=$(findmnt -nk /home 2>/dev/null)
if [[ -n "$findmnt_output" ]]; then
    log_result "$id" "Compliant" "/home is a separate partition.\nFindmnt Output: $findmnt_output"
else
    log_result "$id" "Non-compliant" "/home is not a separate partition."
fi

# 1.1.2.3.2 Ensure nodev option set on /home partition
id="1.1.2.3.2"
change="Ensure nodev option set on /home partition"

# Check if nodev option is set
if findmnt -kn /home | grep -q nodev; then
    log_result "$id" "Compliant" "The nodev option is set on /home partition."
else
    log_result "$id" "Non-compliant" "The nodev option is not set on /home partition."
fi

# 1.1.2.3.3 Ensure nosuid option set on /home partition
id="1.1.2.3.3"
change="Ensure nosuid option set on /home partition"

# Check if nosuid option is set
if findmnt -kn /home | grep -q nosuid; then
    log_result "$id" "Compliant" "The nosuid option is set on /home partition."
else
    log_result "$id" "Non-compliant" "The nosuid option is not set on /home partition."
fi

# 1.1.2.4.1 Ensure /var is a separate partition
id="1.1.2.4.1"
change="Ensure /var is a separate partition"

# Check if /var is a separate partition
findmnt_output=$(findmnt -nk /var 2>/dev/null)
if [[ -n "$findmnt_output" ]]; then
    log_result "$id" "Compliant" "/var is a separate partition.\nFindmnt Output: $findmnt_output"
else
    log_result "$id" "Non-compliant" "/var is not a separate partition."
fi

# 1.1.2.4.2 Ensure nodev option set on /var partition
id="1.1.2.4.2"
change="Ensure nodev option set on /var partition"

# Check if nodev option is set
if findmnt -kn /var | grep -q nodev; then
    log_result "$id" "Compliant" "The nodev option is set on /var partition."
else
    log_result "$id" "Non-compliant" "The nodev option is not set on /var partition."
fi

# 1.1.2.4.3 Ensure nosuid option set on /var partition
id="1.1.2.4.3"
change="Ensure nosuid option set on /var partition"

# Check if nosuid option is set
if findmnt -kn /var | grep -q nosuid; then
    log_result "$id" "Compliant" "The nosuid option is set on /var partition."
else
    log_result "$id" "Non-compliant" "The nosuid option is not set on /var partition."
fi

# 1.1.2.5.1 Ensure separate partition exists for /var/tmp
id="1.1.2.5.1"
change="Ensure separate partition exists for /var/tmp"

# Check if /var/tmp is a separate partition
findmnt_output=$(findmnt -nk /var/tmp 2>/dev/null)
if [[ -n "$findmnt_output" ]]; then
    log_result "$id" "Compliant" "/var/tmp is a separate partition.\nFindmnt Output: $findmnt_output"
else
    log_result "$id" "Non-compliant" "/var/tmp is not a separate partition."
fi

# 1.1.2.5.2 Ensure nodev option set on /var/tmp partition
id="1.1.2.5.2"
change="Ensure nodev option set on /var/tmp partition"

# Check if nodev option is set
if findmnt -kn /var/tmp | grep -q nodev; then
    log_result "$id" "Compliant" "The nodev option is set on /var/tmp partition."
else
    log_result "$id" "Non-compliant" "The nodev option is not set on /var/tmp partition."
fi

# 1.1.2.5.3 Ensure nosuid option set on /var/tmp partition
id="1.1.2.5.3"
change="Ensure nosuid option set on /var/tmp partition"

# Check if nosuid option is set
if findmnt -kn /var/tmp | grep -q nosuid; then
    log_result "$id" "Compliant" "The nosuid option is set on /var/tmp partition."
else
    log_result "$id" "Non-compliant" "The nosuid option is not set on /var/tmp partition."
fi

# 1.1.2.5.4 Ensure noexec option set on /var/tmp partition
id="1.1.2.5.4"
change="Ensure noexec option set on /var/tmp partition"

# Check if noexec option is set
if findmnt -kn /var/tmp | grep -q noexec; then
    log_result "$id" "Compliant" "The noexec option is set on /var/tmp partition."
else
    log_result "$id" "Non-compliant" "The noexec option is not set on /var/tmp partition."
fi

# 1.1.2.6.1 Ensure separate partition exists for /var/log
id="1.1.2.6.1"
change="Ensure separate partition exists for /var/log"

# Check if /var/log is a separate partition
findmnt_output=$(findmnt -nk /var/log 2>/dev/null)
if [[ -n "$findmnt_output" ]]; then
    log_result "$id" "Compliant" "/var/log is a separate partition.\nFindmnt Output: $findmnt_output"
else
    log_result "$id" "Non-compliant" "/var/log is not a separate partition."
fi

# 1.1.2.6.2 Ensure nodev option set on /var/log partition
id="1.1.2.6.2"
change="Ensure nodev option set on /var/log partition"

# Check if nodev option is set
if findmnt -kn /var/log | grep -q nodev; then
    log_result "$id" "Compliant" "The nodev option is set on /var/log partition."
else
    log_result "$id" "Non-compliant" "The nodev option is not set on /var/log partition."
fi

# 1.1.2.6.3 Ensure nosuid option set on /var/log partition
id="1.1.2.6.3"
change="Ensure nosuid option set on /var/log partition"

# Check if nosuid option is set
if findmnt -kn /var/log | grep -q nosuid; then
    log_result "$id" "Compliant" "The nosuid option is set on /var/log partition."
else
    log_result "$id" "Non-compliant" "The nosuid option is not set on /var/log partition."
fi

# 1.1.2.6.4 Ensure noexec option set on /var/log partition
id="1.1.2.6.4"
change="Ensure noexec option set on /var/log partition"

# Check if noexec option is set
if findmnt -kn /var/log | grep -q noexec; then
    log_result "$id" "Compliant" "The noexec option is set on /var/log partition."
else
    log_result "$id" "Non-compliant" "The noexec option is not set on /var/log partition."
fi

# 1.1.2.7.1 Ensure separate partition exists for /var/log/audit
id="1.1.2.7.1"
change="Ensure separate partition exists for /var/log/audit"

# Check if /var/log/audit is a separate partition
findmnt_output=$(findmnt -nk /var/log/audit 2>/dev/null)
if [[ -n "$findmnt_output" ]]; then
    log_result "$id" "Compliant" "/var/log/audit is a separate partition.\nFindmnt Output: $findmnt_output"
else
    log_result "$id" "Non-compliant" "/var/log/audit is not a separate partition."
fi

# 1.1.2.7.2 Ensure nodev option set on /var/log/audit partition
id="1.1.2.7.2"
change="Ensure nodev option set on /var/log/audit partition"

# Check if nodev option is set
if findmnt -kn /var/log/audit | grep -q nodev; then
    log_result "$id" "Compliant" "The nodev option is set on /var/log/audit partition."
else
    log_result "$id" "Non-compliant" "The nodev option is not set on /var/log/audit partition."
fi

# 1.1.2.7.3 Ensure nosuid option set on /var/log/audit partition
id="1.1.2.7.3"
change="Ensure nosuid option set on /var/log/audit partition"

# Check if nosuid option is set
if findmnt -kn /var/log/audit | grep -q nosuid; then
    log_result "$id" "Compliant" "The nosuid option is set on /var/log/audit partition."
else
    log_result "$id" "Non-compliant" "The nosuid option is not set on /var/log/audit partition."
fi

# 1.1.2.7.4 Ensure noexec option set on /var/log/audit partition
id="1.1.2.7.4"
change="Ensure noexec option set on /var/log/audit partition"

# Check if noexec option is set
if findmnt -kn /var/log/audit | grep -q noexec; then
    log_result "$id" "Compliant" "The noexec option is set on /var/log/audit partition."
else
    log_result "$id" "Non-compliant" "The noexec option is not set on /var/log/audit partition."
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"
