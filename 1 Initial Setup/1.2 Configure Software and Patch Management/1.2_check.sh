#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.2_check"
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

# 1.2.1 Ensure GPG keys are configured
id="1.2.1"
change="Ensure GPG keys are configured"

# Check for GPG key URLs in repository configurations
gpg_key_urls=$(grep -r gpgkey /etc/yum.repos.d/* /etc/dnf/dnf.conf 2>/dev/null)

if [[ -n "$gpg_key_urls" ]]; then
    gpg_key_urls_result="GPG key URLs are configured:\n$gpg_key_urls"
else
    gpg_key_urls_result="No GPG key URLs found in repository configuration."
fi

# Check for installed GPG keys
installed_gpg_keys=""
for RPM_PACKAGE in $(rpm -q gpg-pubkey 2>/dev/null); do
    RPM_SUMMARY=$(rpm -q --queryformat "%{SUMMARY}" "${RPM_PACKAGE}")
    RPM_PACKAGER=$(rpm -q --queryformat "%{PACKAGER}" "${RPM_PACKAGE}")
    RPM_DATE=$(date +%Y-%m-%d -d "1970-1-1+$((0x$(rpm -q --queryformat "%{RELEASE}" "${RPM_PACKAGE}") ))sec")
    RPM_KEY_ID=$(rpm -q --queryformat "%{VERSION}" "${RPM_PACKAGE}")
    installed_gpg_keys+="\nRPM: ${RPM_PACKAGE}\nPackager: ${RPM_PACKAGER}\nSummary: ${RPM_SUMMARY}\nCreation date: ${RPM_DATE}\nKey ID: ${RPM_KEY_ID}"
done

if [[ -n "$installed_gpg_keys" ]]; then
    installed_gpg_keys_result="Installed GPG keys:\n$installed_gpg_keys"
else
    installed_gpg_keys_result="No installed GPG keys found."
fi

# Query locally available GPG keys
local_gpg_keys=$(find /etc/pki/rpm-gpg/ -type f -exec rpm -qf {} \; 2>/dev/null | sort -u | xargs -I{} rpm -q --queryformat "%{NAME}-%{VERSION} %{PACKAGER} %{SUMMARY}\\n" {})

if [[ -n "$local_gpg_keys" ]]; then
    local_gpg_keys_result="Locally available GPG keys:\n$local_gpg_keys"
else
    local_gpg_keys_result="No locally available GPG keys found."
fi

# Log results
log_result "$id" "Manual" "GPG Key Audit Results:\n$gpg_key_urls_result\n$installed_gpg_keys_result\n$local_gpg_keys_result"

# 1.2.2 Ensure gpgcheck is globally activated
id="1.2.2"
change="Ensure gpgcheck is globally activated"

# Check global gpgcheck setting in /etc/dnf/dnf.conf
global_gpgcheck=$(grep ^gpgcheck /etc/dnf/dnf.conf 2>/dev/null)
if [[ "$global_gpgcheck" == "gpgcheck=1" ]]; then
    global_gpgcheck_result="Global gpgcheck is properly set to 1 in /etc/dnf/dnf.conf."
else
    global_gpgcheck_result="Global gpgcheck is not set to 1 in /etc/dnf/dnf.conf. Found: $global_gpgcheck"
fi

# Check gpgcheck setting in /etc/yum.repos.d/
repo_gpgcheck=$(grep -Prs -- '^\h*gpgcheck\h*=\h*(0|[2-9]|[1-9][0-9]+|[a-zA-Z_]+)\b' /etc/yum.repos.d/ 2>/dev/null)
if [[ -z "$repo_gpgcheck" ]]; then
    repo_gpgcheck_result="No invalid gpgcheck values found in /etc/yum.repos.d/."
else
    repo_gpgcheck_result="Invalid gpgcheck values found in /etc/yum.repos.d/:\n$repo_gpgcheck"
fi

# Log results
log_result "$id" "Compliant" "gpgcheck Audit Results:\n$global_gpgcheck_result\n$repo_gpgcheck_result"

# 1.2.3 Ensure repo_gpgcheck is globally activated
id="1.2.3"
change="Ensure repo_gpgcheck is globally activated"

# Check global repo_gpgcheck setting in /etc/dnf/dnf.conf
global_repo_gpgcheck=$(grep ^repo_gpgcheck /etc/dnf/dnf.conf 2>/dev/null)
if [[ "$global_repo_gpgcheck" == "repo_gpgcheck=1" ]]; then
    global_repo_gpgcheck_result="Global repo_gpgcheck is properly set to 1 in /etc/dnf/dnf.conf."
else
    global_repo_gpgcheck_result="Global repo_gpgcheck is not set to 1 in /etc/dnf/dnf.conf. Found: $global_repo_gpgcheck"
fi

# Check repo_gpgcheck settings in /etc/yum.repos.d/
repo_gpgcheck_disabled=$(grep -l "repo_gpgcheck=0" /etc/yum.repos.d/* 2>/dev/null)
if [[ -z "$repo_gpgcheck_disabled" ]]; then
    repo_gpgcheck_result="No repositories explicitly disable repo_gpgcheck in /etc/yum.repos.d/."
else
    repo_gpgcheck_result="Repositories disabling repo_gpgcheck in /etc/yum.repos.d/:\n$repo_gpgcheck_disabled"
fi

# Log results
log_result "$id" "Compliant" "repo_gpgcheck Audit Results:\n$global_repo_gpgcheck_result\n$repo_gpgcheck_result"

# 1.2.4 Ensure package manager repositories are configured
id="1.2.4"
change="Ensure package manager repositories are configured"

# Check configured repositories
dnf_repolist_output=$(dnf repolist 2>/dev/null)
if [[ -n "$dnf_repolist_output" ]]; then
    repo_files=$(ls /etc/yum.repos.d/*.repo 2>/dev/null)
    if [[ -n "$repo_files" ]]; then
        repo_file_details=$(cat /etc/yum.repos.d/*.repo)
        log_result "$id" "Compliant" "Repositories are configured. DNF Repolist Output:\n$dnf_repolist_output\n\nRepo Files:\n$repo_files\n\nRepo File Details:\n$repo_file_details"
    else
        log_result "$id" "Non-compliant" "No repository configuration files found in /etc/yum.repos.d/. Ensure repository files are present."
    fi
else
    log_result "$id" "Non-compliant" "DNF repolist command returned no output. Ensure package manager repositories are correctly configured."
fi

# 1.2.5 Ensure updates, patches, and additional security software are installed
id="1.2.5"
change="Ensure updates, patches, and additional security software are installed"

# Check for available updates
updates_output=$(dnf check-update 2>/dev/null)

# Check if a system reboot is required
reboot_required=$(dnf needs-restarting -r 2>/dev/null)

if [[ -z "$updates_output" ]]; then
    if [[ -z "$reboot_required" ]]; then
        log_result "$id" "Compliant" "No updates or patches are available. System reboot is not required."
    else
        log_result "$id" "Compliant with Warning" "No updates or patches are available, but a system reboot is required.\nReboot Status:\n$reboot_required"
    fi
else
    log_result "$id" "Non-compliant" "Updates or patches are available. Run 'dnf upgrade' to apply updates.\nAvailable Updates:\n$updates_output"
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"