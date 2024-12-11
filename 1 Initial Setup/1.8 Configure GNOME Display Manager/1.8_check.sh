#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.8_check"
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

# 1.8.1 Ensure GNOME Display Manager is removed
id="1.8.1"
change="Ensure GNOME Display Manager is removed"

# Check if GDM package is installed
if rpm -q gdm &>/dev/null; then
    log_result "$id" "Non-compliant" "The GNOME Display Manager (gdm) is installed."
else
    log_result "$id" "Compliant" "The GNOME Display Manager (gdm) is not installed."
fi

# 1.8.2 Ensure GDM login banner is configured
id="1.8.2"
change="Ensure GDM login banner is configured"

# Check if GNOME Display Manager (GDM or GDM3) is installed
if rpm -q gdm gdm3 &>/dev/null; then
    # Check for banner configuration
    gdm_file=$(grep -Prils '^\h*banner-message-enable\b' /etc/dconf/db/*.d 2>/dev/null)

    if [[ -n "$gdm_file" ]]; then
        output=""
        output2=""

        # Check if banner-message-enable is set to true
        if grep -Pisq '^\h*banner-message-enable=true\b' "$gdm_file"; then
            output="$output\n - The \"banner-message-enable\" option is enabled in \"$gdm_file\""
        else
            output2="$output2\n - The \"banner-message-enable\" option is not enabled in \"$gdm_file\""
        fi

        # Check if banner-message-text is set
        banner_text=$(grep -Pios '^\h*banner-message-text=.*$' "$gdm_file")
        if [[ -n "$banner_text" ]]; then
            output="$output\n - The \"banner-message-text\" option is set in \"$gdm_file\" with value:\n \"$banner_text\""
        else
            output2="$output2\n - The \"banner-message-text\" option is not set in \"$gdm_file\""
        fi

        # Log compliance status
        if [[ -z "$output2" ]]; then
            log_result "$id" "Compliant" "GDM login banner is correctly configured.\n$output"
        else
            log_result "$id" "Non-compliant" "Issues found in GDM login banner configuration.\n$output2\n$output"
        fi
    else
        log_result "$id" "Non-compliant" "The \"banner-message-enable\" option is not configured."
    fi
else
    log_result "$id" "Not Applicable" "GNOME Display Manager (GDM) is not installed."
fi

# 1.8.3 Ensure GDM disable-user-list option is enabled
id="1.8.3"
change="Ensure GDM disable-user-list option is enabled"

# Check if GNOME Display Manager (GDM or GDM3) is installed
if rpm -q gdm gdm3 &>/dev/null; then
    # Check for disable-user-list configuration
    gdm_file=$(grep -Pril '^\h*disable-user-list\h*=\h*true\b' /etc/dconf/db 2>/dev/null)

    if [[ -n "$gdm_file" ]]; then
        output=""
        output2=""

        output="$output\n - The \"disable-user-list\" option is enabled in \"$gdm_file\""

        # Set profile name based on dconf db directory
        gdm_profile=$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$gdm_file")

        # Check if the profile exists
        if grep -Pq "^\h*system-db:$gdm_profile" /etc/dconf/profile/"$gdm_profile"; then
            output="$output\n - The \"$gdm_profile\" exists in /etc/dconf/profile"
        else
            output2="$output2\n - The \"$gdm_profile\" doesn't exist in /etc/dconf/profile"
        fi

        # Check if the profile exists in the dconf database
        if [[ -f "/etc/dconf/db/$gdm_profile" ]]; then
            output="$output\n - The \"$gdm_profile\" profile exists in the dconf database"
        else
            output2="$output2\n - The \"$gdm_profile\" profile doesn't exist in the dconf database"
        fi

        # Log compliance status
        if [[ -z "$output2" ]]; then
            log_result "$id" "Compliant" "The disable-user-list option is correctly configured.\n$output"
        else
            log_result "$id" "Non-compliant" "Issues found in disable-user-list configuration.\n$output2\n$output"
        fi
    else
        log_result "$id" "Non-compliant" "The \"disable-user-list\" option is not enabled."
    fi
else
    log_result "$id" "Not Applicable" "GNOME Desktop Manager (GDM) is not installed."
fi

# 1.8.4 Ensure GDM screen locks when the user is idle
id="1.8.4"
change="Ensure GDM screen locks when the user is idle"

# Check if GNOME Display Manager (GDM or GDM3) is installed
if rpm -q gdm gdm3 &>/dev/null; then
    output=""
    output2=""
    idle_max_value=900  # Maximum value for idle-delay in seconds
    lock_max_value=5    # Maximum value for lock-delay in seconds

    # Locate the configuration file with idle-delay setting
    gdm_file=$(grep -Psril '^\h*idle-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ 2>/dev/null)

    if [[ -n "$gdm_file" ]]; then
        profile_name=$(awk -F'/' '{split($(NF-1),a,".");print a[1]}' <<< "$gdm_file")

        # Check idle-delay value
        idle_value=$(awk -F 'uint32' '/idle-delay/{print $2}' "$gdm_file" | xargs)
        if [[ -n "$idle_value" ]]; then
            if [[ "$idle_value" -gt 0 && "$idle_value" -le $idle_max_value ]]; then
                output="$output\n - The \"idle-delay\" option is set to \"$idle_value\" seconds in \"$gdm_file\""
            else
                output2="$output2\n - The \"idle-delay\" option is set to \"$idle_value\" seconds, which is either disabled or exceeds $idle_max_value."
            fi
        else
            output2="$output2\n - The \"idle-delay\" option is not set in \"$gdm_file\"."
        fi

        # Check lock-delay value
        lock_value=$(awk -F 'uint32' '/lock-delay/{print $2}' "$gdm_file" | xargs)
        if [[ -n "$lock_value" ]]; then
            if [[ "$lock_value" -ge 0 && "$lock_value" -le $lock_max_value ]]; then
                output="$output\n - The \"lock-delay\" option is set to \"$lock_value\" seconds in \"$gdm_file\""
            else
                output2="$output2\n - The \"lock-delay\" option is set to \"$lock_value\" seconds, which exceeds $lock_max_value."
            fi
        else
            output2="$output2\n - The \"lock-delay\" option is not set in \"$gdm_file\"."
        fi

        # Check if the profile exists in /etc/dconf/profile
        if grep -Psq "^\h*system-db:$profile_name" /etc/dconf/profile/*; then
            output="$output\n - The \"$profile_name\" profile exists in /etc/dconf/profile."
        else
            output2="$output2\n - The \"$profile_name\" profile doesn't exist in /etc/dconf/profile."
        fi

        # Check if the profile exists in the dconf database
        if [[ -f "/etc/dconf/db/$profile_name" ]]; then
            output="$output\n - The \"$profile_name\" profile exists in the dconf database."
        else
            output2="$output2\n - The \"$profile_name\" profile doesn't exist in the dconf database."
        fi
    else
        output2="$output2\n - The \"idle-delay\" option is not configured; remaining checks skipped."
    fi

    # Log compliance status
    if [[ -z "$output2" ]]; then
        log_result "$id" "Compliant" "GDM screen lock settings are correctly configured.\n$output"
    else
        log_result "$id" "Non-compliant" "Issues found in GDM screen lock configuration.\n$output2\n$output"
    fi
else
    log_result "$id" "Not Applicable" "GNOME Desktop Manager (GDM) is not installed."
fi

# 1.8.5 Ensure GDM screen locks cannot be overridden
id="1.8.5"
change="Ensure GDM screen locks cannot be overridden"

# Check if GNOME Display Manager (GDM or GDM3) is installed
if rpm -q gdm gdm3 &>/dev/null; then
    output=""
    output2=""

    # Locate the configuration files for idle-delay and lock-delay
    idle_key_dir="/etc/dconf/db/$(grep -Psril '^\h*idle-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"
    lock_key_dir="/etc/dconf/db/$(grep -Psril '^\h*lock-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"

    # Check if idle-delay is locked
    if [[ -d "$idle_key_dir" ]]; then
        if grep -Prilq '/org/gnome/desktop/session/idle-delay\b' "$idle_key_dir"; then
            output="$output\n - \"idle-delay\" is locked in \"$(grep -Pril '/org/gnome/desktop/session/idle-delay\b' "$idle_key_dir")\""
        else
            output2="$output2\n - \"idle-delay\" is not locked."
        fi
    else
        output2="$output2\n - \"idle-delay\" is not set, so it cannot be locked."
    fi

    # Check if lock-delay is locked
    if [[ -d "$lock_key_dir" ]]; then
        if grep -Prilq '/org/gnome/desktop/screensaver/lock-delay\b' "$lock_key_dir"; then
            output="$output\n - \"lock-delay\" is locked in \"$(grep -Pril '/org/gnome/desktop/screensaver/lock-delay\b' "$lock_key_dir")\""
        else
            output2="$output2\n - \"lock-delay\" is not locked."
        fi
    else
        output2="$output2\n - \"lock-delay\" is not set, so it cannot be locked."
    fi

    # Log compliance status
    if [[ -z "$output2" ]]; then
        log_result "$id" "Compliant" "GDM screen lock settings cannot be overridden.\n$output"
    else
        log_result "$id" "Non-compliant" "Issues found in GDM screen lock configuration.\n$output2\n$output"
    fi
else
    log_result "$id" "Not Applicable" "GNOME Desktop Manager (GDM) is not installed."
fi

# 1.8.6 Ensure GDM automatic mounting of removable media is disabled
id="1.8.6"
change="Ensure GDM automatic mounting of removable media is disabled"

# Check if GNOME Display Manager (GDM or GDM3) is installed
if rpm -q gdm gdm3 &>/dev/null; then
    output=""
    output2=""

    # Locate configuration files for automount and automount-open
    automount_file=$(grep -Prils -- '^\h*automount\b' /etc/dconf/db/*.d)
    automount_open_file=$(grep -Prils -- '^\h*automount-open\b' /etc/dconf/db/*.d)

    # Set profile name based on dconf db directory
    if [[ -f "$automount_file" ]]; then
        profile_name=$(awk -F'/' '{split($(NF-1),a,".");print a[1]}' <<< "$automount_file")
    elif [[ -f "$automount_open_file" ]]; then
        profile_name=$(awk -F'/' '{split($(NF-1),a,".");print a[1]}' <<< "$automount_open_file")
    fi

    # Perform checks if the profile exists
    if [[ -n "$profile_name" ]]; then
        profile_dir="/etc/dconf/db/$profile_name.d"

        # Check if profile file exists
        if grep -Pq -- "^\h*system-db:$profile_name\b" /etc/dconf/profile/*; then
            output="$output\n - dconf database profile file exists."
        else
            output2="$output2\n - dconf database profile isn't set."
        fi

        # Check if the dconf database file exists
        if [[ -f "/etc/dconf/db/$profile_name" ]]; then
            output="$output\n - The dconf database \"$profile_name\" exists."
        else
            output2="$output2\n - The dconf database \"$profile_name\" doesn't exist."
        fi

        # Check if the dconf database directory exists
        if [[ -d "$profile_dir" ]]; then
            output="$output\n - The dconf directory \"$profile_dir\" exists."
        else
            output2="$output2\n - The dconf directory \"$profile_dir\" doesn't exist."
        fi

        # Check automount setting
        if grep -Pqrs -- '^\h*automount\h*=\h*false\b' "$automount_file"; then
            output="$output\n - \"automount\" is set to false in: \"$automount_file\"."
        else
            output2="$output2\n - \"automount\" is not set correctly."
        fi

        # Check automount-open setting
        if grep -Pqs -- '^\h*automount-open\h*=\h*false\b' "$automount_open_file"; then
            output="$output\n - \"automount-open\" is set to false in: \"$automount_open_file\"."
        else
            output2="$output2\n - \"automount-open\" is not set correctly."
        fi
    else
        output2="$output2\n - Neither \"automount\" nor \"automount-open\" is set."
    fi
else
    log_result "$id" "Not Applicable" "GNOME Desktop Manager (GDM) is not installed."
    #return 0
fi

# Log compliance status
if [[ -z "$output2" ]]; then
    log_result "$id" "Compliant" "Automatic mounting of removable media is disabled.\n$output"
else
    log_result "$id" "Non-compliant" "Issues found in automatic mounting configuration.\n$output2\n$output"
fi

# 1.8.7 Ensure GDM disabling automatic mounting of removable media is not overridden
id="1.8.7"
change="Ensure GDM disabling automatic mounting of removable media is not overridden"

# Check if GNOME Display Manager (GDM or GDM3) is installed
if rpm -q gdm gdm3 &>/dev/null; then
    output=""
    output2=""

    # Locate directories for automount and automount-open locks
    lock_dir_automount="/etc/dconf/db/$(grep -Psril '^\h*automount\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d/locks"
    lock_dir_automount_open="/etc/dconf/db/$(grep -Psril '^\h*automount-open\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d/locks"

    # Check if automount lock exists
    if [[ -d "$lock_dir_automount" ]]; then
        if grep -Priq '^\h*/org/gnome/desktop/media-handling/automount\b' "$lock_dir_automount"; then
            output="$output\n - \"automount\" is locked in \"$lock_dir_automount\"."
        else
            output2="$output2\n - \"automount\" is not locked."
        fi
    else
        output2="$output2\n - \"automount\" is not set so it cannot be locked."
    fi

    # Check if automount-open lock exists
    if [[ -d "$lock_dir_automount_open" ]]; then
        if grep -Priq '^\h*/org/gnome/desktop/media-handling/automount-open\b' "$lock_dir_automount_open"; then
            output="$output\n - \"automount-open\" is locked in \"$lock_dir_automount_open\"."
        else
            output2="$output2\n - \"automount-open\" is not locked."
        fi
    else
        output2="$output2\n - \"automount-open\" is not set so it cannot be locked."
    fi
else
    log_result "$id" "Not Applicable" "GNOME Desktop Manager (GDM) is not installed."
    #return 0
fi

# Log compliance status
if [[ -z "$output2" ]]; then
    log_result "$id" "Compliant" "Disabling automatic mounting of removable media is locked.\n$output"
else
    log_result "$id" "Non-compliant" "Issues found in locking automatic mounting configuration.\n$output2\n$output"
fi

# 1.8.8 Ensure GDM autorun-never is enabled
id="1.8.8"
change="Ensure GDM autorun-never is enabled"

# Check if GNOME Display Manager (GDM or GDM3) is installed
if rpm -q gdm gdm3 &>/dev/null; then
    output=""
    output2=""

    # Locate directory and profile for autorun-never setting
    key_file="$(grep -Prils -- '^\h*autorun-never\b' /etc/dconf/db/*.d)"
    if [[ -f "$key_file" ]]; then
        profile_name="$(awk -F'/' '{split($(NF-1),a,".");print a[1]}' <<< "$key_file")"
        profile_dir="/etc/dconf/db/$profile_name.d"

        # Check if dconf profile exists
        if grep -Pq "^\h*system-db:$profile_name\b" /etc/dconf/profile/*; then
            output="$output\n - dconf database profile file \"$(grep -Pl -- "^\h*system-db:$profile_name\b" /etc/dconf/profile/*)\" exists."
        else
            output2="$output2\n - dconf database profile isn't set."
        fi

        # Check if dconf database file exists
        if [[ -f "/etc/dconf/db/$profile_name" ]]; then
            output="$output\n - The dconf database \"$profile_name\" exists."
        else
            output2="$output2\n - The dconf database \"$profile_name\" doesn't exist."
        fi

        # Check if dconf directory exists
        if [[ -d "$profile_dir" ]]; then
            output="$output\n - The dconf directory \"$profile_dir\" exists."
        else
            output2="$output2\n - The dconf directory \"$profile_dir\" doesn't exist."
        fi

        # Check if autorun-never is set to true
        if grep -Pqrs -- '^\h*autorun-never\h*=\h*true\b' "$key_file"; then
            output="$output\n - \"autorun-never\" is set to true in \"$key_file\"."
        else
            output2="$output2\n - \"autorun-never\" is not set correctly."
        fi
    else
        output2="$output2\n - \"autorun-never\" is not set."
    fi
else
    log_result "$id" "Not Applicable" "GNOME Desktop Manager (GDM) is not installed."
    #return 0
fi

# Log compliance status
if [[ -z "$output2" ]]; then
    log_result "$id" "Compliant" "The autorun-never setting is enabled for GDM.\n$output"
else
    log_result "$id" "Non-compliant" "Issues found with the autorun-never setting for GDM.\n$output2\n$output"
fi

# 1.8.9 Ensure GDM autorun-never is not overridden
id="1.8.9"
change="Ensure GDM autorun-never is not overridden"

# Check if GNOME Display Manager (GDM or GDM3) is installed
if rpm -q gdm gdm3 &>/dev/null; then
    output=""
    output2=""

    # Locate directory for locked settings
    key_dir="/etc/dconf/db/$(grep -Psril '^\h*autorun-never\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"
    if [[ -d "$key_dir" ]]; then
        # Check if autorun-never is locked
        if grep -Priq '^\h*\/org\/gnome\/desktop\/media-handling\/autorun-never\b' "$key_dir"; then
            output="$output\n - \"autorun-never\" is locked in \"$(grep -Pril '^\h*\/org\/gnome\/desktop\/media-handling\/autorun-never\b' "$key_dir")\"."
        else
            output2="$output2\n - \"autorun-never\" is not locked."
        fi
    else
        output2="$output2\n - \"autorun-never\" is not set, so it cannot be locked."
    fi
else
    log_result "$id" "Not Applicable" "GNOME Desktop Manager (GDM) is not installed."
    #return 0
fi

# Log compliance status
if [[ -z "$output2" ]]; then
    log_result "$id" "Compliant" "The autorun-never setting is locked and cannot be overridden.\n$output"
else
    log_result "$id" "Non-compliant" "Issues found with the locking of autorun-never.\n$output2\n$output"
fi

# 1.8.10 Ensure XDMCP is not enabled
id="1.8.10"
change="Ensure XDMCP is not enabled"

# Define the file to check
config_file="/etc/gdm/custom.conf"

# Check if the GNOME Display Manager is installed
if rpm -q gdm gdm3 &>/dev/null; then
    # Check if XDMCP is enabled
    if grep -Eis '^\s*Enable\s*=\s*true' "$config_file" &>/dev/null; then
        log_result "$id" "Non-compliant" "XDMCP is enabled in $config_file."
    else
        log_result "$id" "Compliant" "XDMCP is not enabled in $config_file."
    fi
else
    log_result "$id" "Not Applicable" "GNOME Display Manager (GDM) is not installed."
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"