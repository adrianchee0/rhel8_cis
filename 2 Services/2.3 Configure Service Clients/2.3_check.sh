#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="2.3_check"
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

# 2.3.1 Ensure ftp client is not installed
id="2.3.1"
change="Ensure ftp client is not installed"

# Check if the ftp package is installed
ftp_installed=$(rpm -q ftp 2>/dev/null)

if [[ "$ftp_installed" =~ "not installed" ]]; then
    # ftp package is not installed
    log_result "$id" "Compliant" "The ftp package is not installed."
else
    # ftp package is installed
    log_result "$id" "Non-compliant" "The ftp package is installed."
    
    # Remove the ftp package if it is not required
    rpm -e ftp
    log_result "$id" "Action Taken" "The ftp package has been removed."
fi

# 2.3.2 Ensure ldap client is not installed
id="2.3.2"
change="Ensure ldap client is not installed"

# Check if the openldap-clients package is installed
ldap_installed=$(rpm -q openldap-clients 2>/dev/null)

if [[ "$ldap_installed" =~ "not installed" ]]; then
    # openldap-clients package is not installed
    log_result "$id" "Compliant" "The openldap-clients package is not installed."
else
    # openldap-clients package is installed
    log_result "$id" "Non-compliant" "The openldap-clients package is installed."
    
    # Remove the openldap-clients package if it is not required
    rpm -e openldap-clients
    log_result "$id" "Action Taken" "The openldap-clients package has been removed."
fi

# 2.3.3 Ensure nis client is not installed
id="2.3.3"
change="Ensure nis client is not installed"

# Check if the ypbind package is installed
nis_installed=$(rpm -q ypbind 2>/dev/null)

if [[ "$nis_installed" =~ "not installed" ]]; then
    # ypbind package is not installed
    log_result "$id" "Compliant" "The ypbind package is not installed."
else
    # ypbind package is installed
    log_result "$id" "Non-compliant" "The ypbind package is installed."
    
    # Remove the ypbind package if it is not required
    rpm -e ypbind
    log_result "$id" "Action Taken" "The ypbind package has been removed."
fi

# 2.3.4 Ensure telnet client is not installed
id="2.3.4"
change="Ensure telnet client is not installed"

# Check if the telnet package is installed
telnet_installed=$(rpm -q telnet 2>/dev/null)

if [[ "$telnet_installed" =~ "not installed" ]]; then
    # telnet package is not installed
    log_result "$id" "Compliant" "The telnet package is not installed."
else
    # telnet package is installed
    log_result "$id" "Non-compliant" "The telnet package is installed."
    
    # Remove the telnet package if it is not required
    rpm -e telnet
    log_result "$id" "Action Taken" "The telnet package has been removed."
fi

# 2.3.5 Ensure tftp client is not installed
id="2.3.5"
change="Ensure tftp client is not installed"

# Check if the tftp package is installed
tftp_installed=$(rpm -q tftp 2>/dev/null)

if [[ "$tftp_installed" =~ "not installed" ]]; then
    # tftp package is not installed
    log_result "$id" "Compliant" "The tftp package is not installed."
else
    # tftp package is installed
    log_result "$id" "Non-compliant" "The tftp package is installed."
    
    # Remove the tftp package if it is not required
    rpm -e tftp
    log_result "$id" "Action Taken" "The tftp package has been removed."
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"