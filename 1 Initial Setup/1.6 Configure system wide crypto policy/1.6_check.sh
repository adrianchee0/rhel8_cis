#!/bin/bash

# Dynamic Log File Creation
LOG_DIR="."
LOG_PREFIX="1.6_check"
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

# 1.6.1 Ensure system wide crypto policy is not set to legacy
id="1.6.1"
change="Ensure system wide crypto policy is not set to legacy"

# Check if system-wide crypto policy is set to LEGACY
crypto_policy=$(grep -Pi '^\h*LEGACY\b' /etc/crypto-policies/config 2>/dev/null)

if [[ -z "$crypto_policy" ]]; then
    log_result "$id" "Compliant" "The system-wide crypto policy is not set to LEGACY."
else
    log_result "$id" "Non-compliant" "The system-wide crypto policy is set to LEGACY.\nDetails: $crypto_policy"
fi

# 1.6.2 Ensure system wide crypto policy disables SHA1 hash and signature support
id="1.6.2"
change="Ensure system wide crypto policy disables SHA1 hash and signature support"

# Check for SHA1 hash and signature support in the crypto policy
sha1_hash_support=$(grep -Pi -- '^\h*(hash|sign)\h*=\h*([^\n\r#]+)?-sha1\b' /etc/crypto-policies/state/CURRENT.pol 2>/dev/null)
sha1_in_certs=$(grep -Pi -- '^\h*sha1_in_certs\h*=\h*' /etc/crypto-policies/state/CURRENT.pol 2>/dev/null)

if [[ -z "$sha1_hash_support" && "$sha1_in_certs" =~ sha1_in_certs\ =\ 0 ]]; then
    log_result "$id" "Compliant" "SHA1 hash and signature support is disabled in the system-wide crypto policy."
else
    details="SHA1 support settings:\n"
    [[ -n "$sha1_hash_support" ]] && details+=" - Hash/Sign support: $sha1_hash_support\n"
    [[ ! "$sha1_in_certs" =~ sha1_in_certs\ =\ 0 ]] && details+=" - SHA1 in certificates is not correctly disabled: $sha1_in_certs\n"
    log_result "$id" "Non-compliant" "SHA1 hash and signature support is not fully disabled in the system-wide crypto policy.\n$details"
fi

# 1.6.3 Ensure system wide crypto policy disables CBC for SSH
id="1.6.3"
change="Ensure system wide crypto policy disables CBC for SSH"

# Check for CBC cipher usage in the crypto policy
cbc_check=$(grep -Piq -- '^\h*cipher\h*=\h*([^#\n\r]+)?-CBC\b' /etc/crypto-policies/state/CURRENT.pol)
ssh_cipher_check=$(grep -Piq -- '^\h*cipher@(lib|open)ssh(-server|-client)?\h*=\h*' /etc/crypto-policies/state/CURRENT.pol)
cbc_ssh_check=$(grep -Piq -- '^\h*cipher@(lib|open)ssh(-server|-client)?\h*=\h*([^#\n\r]+)?-CBC\b' /etc/crypto-policies/state/CURRENT.pol)

if [[ -z "$cbc_check" && -n "$ssh_cipher_check" && -z "$cbc_ssh_check" ]]; then
    log_result "$id" "Compliant" "Cipher Block Chaining (CBC) is disabled for SSH in the system-wide crypto policy."
else
    details="Cipher Block Chaining (CBC) settings:\n"
    [[ -n "$cbc_check" ]] && details+=" - CBC is enabled globally in the crypto policy.\n"
    [[ -z "$ssh_cipher_check" ]] && details+=" - SSH cipher settings are not explicitly configured in the crypto policy.\n"
    [[ -n "$cbc_ssh_check" ]] && details+=" - CBC is enabled for SSH in the crypto policy.\n"
    log_result "$id" "Non-compliant" "Cipher Block Chaining (CBC) is not fully disabled for SSH in the system-wide crypto policy.\n$details"
fi

# 1.6.4 Ensure system wide crypto policy disables MACs less than 128 bits
id="1.6.4"
change="Ensure system wide crypto policy disables MACs less than 128 bits"

# Check for weak MACs (less than 128 bits) in the crypto policy
weak_macs_check=$(grep -Pi -- '^\h*mac\h*=\h*([^#\n\r]+)?-64\b' /etc/crypto-policies/state/CURRENT.pol)

if [[ -z "$weak_macs_check" ]]; then
    log_result "$id" "Compliant" "MACs less than 128 bits are disabled in the system-wide crypto policy."
else
    details="Weak MACs are enabled in the system-wide crypto policy:\n"
    details+=$(grep -Pi -- '^\h*mac\h*=\h*([^#\n\r]+)?-64\b' /etc/crypto-policies/state/CURRENT.pol | sed 's/^/ - /')
    log_result "$id" "Non-compliant" "MACs less than 128 bits are not fully disabled in the system-wide crypto policy.\n$details"
fi

# Indicate log file creation
echo "Log file created at: $LOG_FILE"