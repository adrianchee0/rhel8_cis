#!/bin/bash
# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.1.1_check"
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

# Function to perform checks for a given module
perform_checks() {
    local id=$1
    local module_name=$2
    local module_type=$3
    local l_output=""
    local l_output2=""
    local l_output3=""
    local deny_listed="n"
    local search_locations="/lib/modprobe.d/*.conf /usr/local/lib/modprobe.d/*.conf /run/modprobe.d/*.conf /etc/modprobe.d/*.conf"
    local module_paths="/lib/modules/**/kernel/$module_type"

    # Check if the module is currently loadable
    module_loadable_chk() {
        local loadable_output
        loadable_output=$(modprobe -n -v "$module_name" 2>/dev/null)
        if echo "$loadable_output" | grep -Pq '^\h*install \/bin\/(true|false)'; then
            l_output="$l_output\n - Module \"$module_name\" is not loadable."
        else
            l_output2="$l_output2\n - Module \"$module_name\" is loadable: \"$loadable_output\"."
        fi
    }

    # Check if the module is currently loaded
    module_loaded_chk() {
        if ! lsmod | grep -q "$module_name"; then
            l_output="$l_output\n - Module \"$module_name\" is not loaded."
        else
            l_output2="$l_output2\n - Module \"$module_name\" is currently loaded."
        fi
    }

    # Check if the module is deny-listed
    module_deny_chk() {
        deny_listed="y"
        if modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$module_name\b"; then
            local blacklist_files
            blacklist_files=$(grep -Pls -- "^\h*blacklist\h+$module_name\b" $search_locations 2>/dev/null)
            l_output="$l_output\n - Module \"$module_name\" is deny-listed in: \"$blacklist_files\"."
        else
            l_output2="$l_output2\n - Module \"$module_name\" is not deny-listed."
        fi
    }

    # Check if the module exists on the system
    for module_dir in $module_paths; do
        if [ -d "$module_dir/$module_name" ] && [ -n "$(ls -A $module_dir/$module_name 2>/dev/null)" ]; then
            l_output3="$l_output3\n - \"$module_dir\""
            [ "$deny_listed" != "y" ] && module_deny_chk
            if [ "$module_dir" = "/lib/modules/$(uname -r)/kernel/$module_type" ]; then
                module_loadable_chk
                module_loaded_chk
            fi
        else
            l_output="$l_output\n - Module \"$module_name\" does not exist in \"$module_dir\"."
        fi
    done

    # Log results
    if [ -z "$l_output2" ]; then
        log_result "$id" "Compliant" "$module_name kernel module is not available. $l_output"
    else
        log_result "$id" "Non-compliant" "$module_name kernel module has issues:\n$l_output2\n$l_output"
    fi
}

# 1.1.1.1 Ensure cramfs kernel module is not available
perform_checks "1.1.1.1" "cramfs" "fs"

# 1.1.1.2 Ensure freevxfs kernel module is not available
perform_checks "1.1.1.2" "freevxfs" "fs"

# 1.1.1.3 Ensure hfs kernel module is not available
perform_checks "1.1.1.3" "hfs" "fs"

# 1.1.1.4 Ensure hfsplus kernel module is not available
perform_checks "1.1.1.4" "hfsplus" "fs"

# 1.1.1.5 Ensure jffs2 kernel module is not available
perform_checks "1.1.1.5" "jffs2" "fs"

# 1.1.1.6 Ensure squashfs kernel module is not available
perform_checks "1.1.1.6" "squashfs" "fs"

# 1.1.1.7 Ensure udf kernel module is not available
perform_checks "1.1.1.7" "udf" "fs"

# 1.1.1.8 Ensure usb-storage kernel module is not available
perform_checks "1.1.1.8" "usb-storage" "drivers"