#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.4_check"
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

# 1.4.1 Ensure address space layout randomization (ASLR) is enabled
id="1.4.1"
change="Ensure address space layout randomization (ASLR) is enabled"

# Kernel parameter to check
kernel_param="kernel.randomize_va_space"
expected_value="2"

# Initialize output
output_correct=""
output_incorrect=""

# Check current running configuration
current_value=$(sysctl "$kernel_param" 2>/dev/null | awk -F= '{print $2}' | xargs)

if [[ "$current_value" == "$expected_value" ]]; then
    output_correct="$output_correct\n - \"$kernel_param\" is correctly set to \"$current_value\" in the running configuration."
else
    output_incorrect="$output_incorrect\n - \"$kernel_param\" is incorrectly set to \"$current_value\" in the running configuration. Expected: \"$expected_value\"."
fi

# Check durable settings from configuration files
declare -A config_files
while read -r file line; do
    if [[ "$line" == "$kernel_param=$expected_value" ]]; then
        config_files["$file"]="correct"
        output_correct="$output_correct\n - \"$kernel_param\" is correctly set in \"$file\"."
    elif [[ "$line" == "$kernel_param"* ]]; then
        config_files["$file"]="incorrect"
        output_incorrect="$output_incorrect\n - \"$kernel_param\" is incorrectly set in \"$file\". Expected: \"$kernel_param=$expected_value\"."
    fi
done < <(grep -R "^$kernel_param" /etc/sysctl.d/* /usr/lib/sysctl.d/* /etc/sysctl.conf 2>/dev/null)

# Check if the parameter is missing from all configuration files
if [[ ${#config_files[@]} -eq 0 ]]; then
    output_incorrect="$output_incorrect\n - \"$kernel_param\" is not set in any configuration file."
fi

# Log results
if [[ -z "$output_incorrect" ]]; then
    log_result "$id" "Compliant" "ASLR is enabled and properly configured:\n$output_correct"
else
    log_result "$id" "Non-compliant" "ASLR is not properly configured:\n$output_incorrect\n$output_correct"
fi

# 1.4.2 Ensure ptrace_scope is restricted
id="1.4.2"
change="Ensure ptrace_scope is restricted"

# Kernel parameter to check
kernel_param="kernel.yama.ptrace_scope"
expected_value="1"

# Initialize output
output_correct=""
output_incorrect=""

# Check current running configuration
current_value=$(sysctl "$kernel_param" 2>/dev/null | awk -F= '{print $2}' | xargs)

if [[ "$current_value" == "$expected_value" ]]; then
    output_correct="$output_correct\n - \"$kernel_param\" is correctly set to \"$current_value\" in the running configuration."
else
    output_incorrect="$output_incorrect\n - \"$kernel_param\" is incorrectly set to \"$current_value\" in the running configuration. Expected: \"$expected_value\"."
fi

# Check durable settings from configuration files
declare -A config_files
while read -r file line; do
    if [[ "$line" == "$kernel_param=$expected_value" ]]; then
        config_files["$file"]="correct"
        output_correct="$output_correct\n - \"$kernel_param\" is correctly set in \"$file\"."
    elif [[ "$line" == "$kernel_param"* ]]; then
        config_files["$file"]="incorrect"
        output_incorrect="$output_incorrect\n - \"$kernel_param\" is incorrectly set in \"$file\". Expected: \"$kernel_param=$expected_value\"."
    fi
done < <(grep -R "^$kernel_param" /etc/sysctl.d/* /usr/lib/sysctl.d/* /etc/sysctl.conf 2>/dev/null)

# Check if the parameter is missing from all configuration files
if [[ ${#config_files[@]} -eq 0 ]]; then
    output_incorrect="$output_incorrect\n - \"$kernel_param\" is not set in any configuration file."
fi

# Log results
if [[ -z "$output_incorrect" ]]; then
    log_result "$id" "Compliant" "ptrace_scope is restricted and properly configured:\n$output_correct"
else
    log_result "$id" "Non-compliant" "ptrace_scope is not properly configured:\n$output_incorrect\n$output_correct"
fi

# 1.4.3 Ensure core dump backtraces are disabled
id="1.4.3"
change="Ensure core dump backtraces are disabled"

# Parameter to check
parameter="ProcessSizeMax"
expected_value="0"
config_file="/etc/systemd/coredump.conf"
config_dir="/etc/systemd/coredump.conf.d"

# Initialize output
output_correct=""
output_incorrect=""

# Check if the parameter is set in the main configuration file
if grep -Eqs "^\s*$parameter\s*=\s*$expected_value\s*$" "$config_file"; then
    output_correct="$output_correct\n - \"$parameter\" is correctly set to \"$expected_value\" in \"$config_file\"."
else
    output_incorrect="$output_incorrect\n - \"$parameter\" is not correctly set in \"$config_file\". Expected: \"$parameter=$expected_value\"."
fi

# Check if the parameter is set in any configuration files in the directory
for file in "$config_dir"/*.conf; do
    if [[ -f "$file" ]]; then
        if grep -Eqs "^\s*$parameter\s*=\s*$expected_value\s*$" "$file"; then
            output_correct="$output_correct\n - \"$parameter\" is correctly set to \"$expected_value\" in \"$file\"."
        else
            output_incorrect="$output_incorrect\n - \"$parameter\" is not correctly set in \"$file\". Expected: \"$parameter=$expected_value\"."
        fi
    fi
done

# Check if the parameter is set in the systemd running configuration
running_value=$(systemctl show -p $parameter --value coredump 2>/dev/null)
if [[ "$running_value" == "$expected_value" ]]; then
    output_correct="$output_correct\n - \"$parameter\" is correctly set to \"$running_value\" in the running configuration."
else
    output_incorrect="$output_incorrect\n - \"$parameter\" is incorrectly set to \"$running_value\" in the running configuration. Expected: \"$expected_value\"."
fi

# Log results
if [[ -z "$output_incorrect" ]]; then
    log_result "$id" "Compliant" "Core dump backtraces are disabled:\n$output_correct"
else
    log_result "$id" "Non-compliant" "Core dump backtraces are not properly disabled:\n$output_incorrect\n$output_correct"
fi

# 1.4.4 Ensure core dump storage is disabled
id="1.4.4"
change="Ensure core dump storage is disabled"

# Parameter to check
parameter="Storage"
expected_value="none"
config_file="/etc/systemd/coredump.conf"
config_dir="/etc/systemd/coredump.conf.d"

# Initialize output
output_correct=""
output_incorrect=""

# Check if the parameter is set in the main configuration file
if grep -Eqs "^\s*$parameter\s*=\s*$expected_value\s*$" "$config_file"; then
    output_correct="$output_correct\n - \"$parameter\" is correctly set to \"$expected_value\" in \"$config_file\"."
else
    output_incorrect="$output_incorrect\n - \"$parameter\" is not correctly set in \"$config_file\". Expected: \"$parameter=$expected_value\"."
fi

# Check if the parameter is set in any configuration files in the directory
for file in "$config_dir"/*.conf; do
    if [[ -f "$file" ]]; then
        if grep -Eqs "^\s*$parameter\s*=\s*$expected_value\s*$" "$file"; then
            output_correct="$output_correct\n - \"$parameter\" is correctly set to \"$expected_value\" in \"$file\"."
        else
            output_incorrect="$output_incorrect\n - \"$parameter\" is not correctly set in \"$file\". Expected: \"$parameter=$expected_value\"."
        fi
    fi
done

# Check if the parameter is set in the systemd running configuration
running_value=$(systemctl show -p $parameter --value coredump 2>/dev/null)
if [[ "$running_value" == "$expected_value" ]]; then
    output_correct="$output_correct\n - \"$parameter\" is correctly set to \"$running_value\" in the running configuration."
else
    output_incorrect="$output_incorrect\n - \"$parameter\" is incorrectly set to \"$running_value\" in the running configuration. Expected: \"$expected_value\"."
fi

# Log results
if [[ -z "$output_incorrect" ]]; then
    log_result "$id" "Compliant" "Core dump storage is disabled:\n$output_correct"
else
    log_result "$id" "Non-compliant" "Core dump storage is not properly disabled:\n$output_incorrect\n$output_correct"
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"