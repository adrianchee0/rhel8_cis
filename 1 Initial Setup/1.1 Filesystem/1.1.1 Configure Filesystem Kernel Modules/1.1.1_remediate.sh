#!/bin/bash
# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.1.1_remediate"
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

# Remediation function for kernel module
remediate_kernel_module() {
    local id=$1
    local module_name=$2
    local module_type=$3
    local l_output=""
    local l_mpath="/lib/modules/**/kernel/$module_type"
    local l_mpname
    local l_mndir
    local remediation_failed=0

    l_mpname=$(tr '-' '_' <<< "$module_name")
    l_mndir=$(tr '-' '/' <<< "$module_name")

    # Add 'install module_name /bin/false' to prevent loading
    module_loadable_fix() {
        local loadable_output
        loadable_output=$(modprobe -n -v "$module_name" 2>/dev/null)
        if ! grep -Pq '^\h*install \/bin\/(true|false)' <<< "$loadable_output"; then
            echo "install $module_name /bin/false" >> /etc/modprobe.d/"$l_mpname".conf 2>/dev/null
            if [ $? -eq 0 ]; then
                l_output="$l_output\n - Added 'install $module_name /bin/false' to /etc/modprobe.d/$l_mpname.conf."
            else
                l_output="$l_output\n - Failed to add 'install $module_name /bin/false'."
                remediation_failed=1
            fi
        else
            l_output="$l_output\n - 'install $module_name /bin/false' is already set."
        fi
    }

    # Unload module if it is currently loaded
    module_loaded_fix() {
        if lsmod | grep -q "$module_name"; then
            modprobe -r "$module_name" 2>/dev/null
            if [ $? -eq 0 ]; then
                l_output="$l_output\n - Unloaded module $module_name."
            else
                l_output="$l_output\n - Failed to unload module $module_name."
                remediation_failed=1
            fi
        else
            l_output="$l_output\n - Module $module_name is not loaded."
        fi
    }

    # Add 'blacklist module_name' to deny list
    module_deny_fix() {
        if ! modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$module_name\b"; then
            echo "blacklist $module_name" >> /etc/modprobe.d/"$l_mpname".conf 2>/dev/null
            if [ $? -eq 0 ]; then
                l_output="$l_output\n - Added 'blacklist $module_name' to /etc/modprobe.d/$l_mpname.conf."
            else
                l_output="$l_output\n - Failed to add 'blacklist $module_name'."
                remediation_failed=1
            fi
        else
            l_output="$l_output\n - Module $module_name is already deny-listed."
        fi
    }

    # Check if the module exists on the system
    for module_dir in $l_mpath; do
        if [ -d "$module_dir/$l_mndir" ] && [ -n "$(ls -A "$module_dir/$l_mndir" 2>/dev/null)" ]; then
            l_output="$l_output\n - Module $module_name exists in $module_dir."
            module_deny_fix
            if [ "$module_dir" = "/lib/modules/$(uname -r)/kernel/$module_type" ]; then
                module_loadable_fix
                module_loaded_fix
            fi
        else
            l_output="$l_output\n - Module $module_name does not exist in $module_dir."
        fi
    done

    # Log results
    if [ $remediation_failed -eq 0 ]; then
        log_result "$id" "Remediated" "$module_name kernel module remediation complete. $l_output"
    else
        log_result "$id" "Failed" "$module_name kernel module remediation encountered issues. $l_output"
    fi
}

# 1.1.1.1 Ensure cramfs kernel module is not available
remediate_kernel_module "1.1.1.1" "cramfs" "fs"

# 1.1.1.2 Ensure freevxfs kernel module is not available
remediate_kernel_module "1.1.1.2" "freevxfs" "fs"

# 1.1.1.3 Ensure hfs kernel module is not available
remediate_kernel_module "1.1.1.3" "hfs" "fs"

# 1.1.1.4 Ensure hfsplus kernel module is not available
remediate_kernel_module "1.1.1.4" "hfsplus" "fs"

# 1.1.1.5 Ensure jffs2 kernel module is not available
remediate_kernel_module "1.1.1.5" "jffs2" "fs"

# 1.1.1.6 Ensure squashfs kernel module is not available
remediate_kernel_module "1.1.1.6" "squashfs" "fs"

# 1.1.1.7 Ensure udf kernel module is not available
remediate_kernel_module "1.1.1.7" "udf" "fs"

# 1.1.1.8 Ensure usb-storage kernel module is not available
remediate_kernel_module "1.1.1.8" "usb-storage" "drivers"
