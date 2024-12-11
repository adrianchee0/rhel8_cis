#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.3_check"
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

# 1.3.1 Ensure bootloader password is set
id="1.3.1"
change="Ensure bootloader password is set"

# Check if GRUB password is set
grub_password_file=$(find /boot -type f -name 'user.cfg' ! -empty 2>/dev/null)

if [[ -f "$grub_password_file" ]]; then
    grub_password=$(awk -F= '/^\s*GRUB2_PASSWORD=/ {print $2}' "$grub_password_file" 2>/dev/null)
    if [[ -n "$grub_password" ]]; then
        log_result "$id" "Compliant" "Bootloader password is set.\nPassword hash found in: $grub_password_file\nHash: $grub_password"
    else
        log_result "$id" "Non-compliant" "Bootloader password is not set in the GRUB configuration file: $grub_password_file."
    fi
else
    log_result "$id" "Non-compliant" "No non-empty GRUB user.cfg file found in /boot. Bootloader password is not set."
fi

# 1.3.2 Ensure permissions on bootloader config are configured
id="1.3.2"
change="Ensure permissions on bootloader config are configured"

# Initialize outputs
output_correct=""
output_incorrect=""

# Function to check file permissions
file_permission_check() {
    local file=$1
    local mode user group
    mode=$(stat -c "%a" "$file")
    user=$(stat -c "%U" "$file")
    group=$(stat -c "%G" "$file")

    # Determine expected mode based on location
    if [[ "$file" =~ ^/boot/efi/EFI ]]; then
        expected_mode="0700"
    else
        expected_mode="0600"
    fi

    # Check mode
    if [[ "$mode" -le "$expected_mode" ]]; then
        output_correct="$output_correct\n - File: \"$file\" has correct mode: \"$mode\"."
    else
        output_incorrect="$output_incorrect\n - File: \"$file\" has incorrect mode: \"$mode\". Expected: \"$expected_mode\" or more restrictive."
    fi

    # Check owner
    if [[ "$user" == "root" ]]; then
        output_correct="$output_correct\n - File: \"$file\" is correctly owned by user: \"$user\"."
    else
        output_incorrect="$output_incorrect\n - File: \"$file\" is owned by user: \"$user\". Expected: \"root\"."
    fi

    # Check group owner
    if [[ "$group" == "root" ]]; then
        output_correct="$output_correct\n - File: \"$file\" is correctly group-owned by: \"$group\"."
    else
        output_incorrect="$output_incorrect\n - File: \"$file\" is group-owned by: \"$group\". Expected: \"root\"."
    fi
}

# Find bootloader configuration files
while IFS= read -r -d $'\0' file; do
    file_permission_check "$file"
done < <(find /boot -type f \( -name 'grub*' -o -name 'user.cfg' \) -print0)

# Log results
if [[ -z "$output_incorrect" ]]; then
    log_result "$id" "Compliant" "All bootloader configuration files have correct permissions:\n$output_correct"
else
    log_result "$id" "Non-compliant" "Some bootloader configuration files have incorrect permissions:\n$output_incorrect\n$output_correct"
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"