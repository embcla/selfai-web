#!/bin/bash

# This script is used to encrypt and decrypt the secrets

# Usage:
# ./manage_secrets.sh encrypt
# ./manage_secrets.sh decrypt

# It expects a master key to be set in the MASTER_KEY environment variable
# and the secrets to be in the terraform.tfvars file


# Associative array of secrets with the following properties for each secret:
# - value: The default value if none provided
# - short_name: Short identifier used in commands (e.g. "hetzner", "cloudflare")
# - long_name: Human readable name used in prompts
# - variable: The variable name used in terraform.tfvars

# Spacing is important here, do not change it
# hcloud_token         = "secret"
# cloudflare_api_token = "secret"
# cloudflare_zone_id   = "secret"

declare -A secrets
secrets[hcloud_token,value]="secret"
secrets[hcloud_token,short_name]="hetzner"
secrets[hcloud_token,long_name]="Hetzner Cloud token"
secrets[hcloud_token,variable]="hcloud_token         "

secrets[cloudflare_api_token,value]="secret"
secrets[cloudflare_api_token,short_name]="cloudflare"
secrets[cloudflare_api_token,long_name]="Cloudflare API token"
secrets[cloudflare_api_token,variable]="cloudflare_api_token "

secrets[cloudflare_zone_id,value]="secret"
secrets[cloudflare_zone_id,short_name]="zone"
secrets[cloudflare_zone_id,long_name]="Cloudflare Zone ID"
secrets[cloudflare_zone_id,variable]="cloudflare_zone_id   "


# Function to get the master key
get_master_key() {
    if [ -z "$MASTER_KEY" ]; then
        echo "Error: MASTER_KEY environment variable not set"
        echo "Please set your master key:"
        echo "export MASTER_KEY='your-secure-key'"
        exit 1
    fi
}

# Function to encrypt a value
encrypt_value() {
    local value="$1"
    local master_key=$(get_master_key)
    # Encrypt the value
    echo "$value" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 10000 -pass "pass:$master_key" | base64 
}

# Function to decrypt a value
decrypt_value() {
    local value="$1"
    local master_key=$(get_master_key)
    # Decrypt the value
    echo "$value" | base64 -d | openssl enc -aes-256-cbc -d -salt -pbkdf2 -iter 10000 -pass "pass:$master_key"
}

# Function to decrypt or encrypt the array
de_en_crypt_array() {
    for secret in "${!secrets[@]}"; do
        # Only process entries with 'value' key
        if [[ $secret == *",value" ]]; then
            # Extract the base key (everything before ,value)
            local base_key=${secret%,value}
            local value=${secrets[$secret]}
            case "$1" in
                "decrypt")
                    local crypted_value=$(decrypt_value "$value")
                    ;;
                "encrypt")
                    local crypted_value=$(encrypt_value "$value")
                    ;;
            esac
            
            secrets[$secret]=$crypted_value
        fi
    done
}

# Function to encrypt the array
encrypt_array() {
    de_en_crypt_array "encrypt"
}

# Function to decrypt the array
decrypt_array() {
    de_en_crypt_array "decrypt"
}

# Function to read the terraform.tfvars file
read_tfvars_to_array() {
    # Read the terraform.tfvars file
    local terraform_tfvars=$(cat terraform.tfvars)
    # Fill the array with the values from the terraform.tfvars file
    for secret in "${!secrets[@]}"; do
        # Only process entries with 'variable' key
        if [[ $secret == *",variable" ]]; then
            # Extract the base key (everything before ,variable)
            local base_key=${secret%,variable}
            local variable=${secrets[$secret]}
            local value=$(echo "$terraform_tfvars" | grep "^$variable" | cut -d'=' -f2- | tr -d ' "')
            secrets[$base_key,value]=$value
        fi
    done
}

# Function to write the array to the terraform.tfvars file
write_array_to_tfvars() {
    # Write each secret to the file
    > terraform.tfvars
    for secret in "${!secrets[@]}"; do
        # Only process entries with 'variable' key
        if [[ $secret == *",variable" ]]; then
            # Extract the base key (everything before ,variable)
            local base_key=${secret%,variable}
            local variable=${secrets[$secret]}
            local value=${secrets[$base_key,value]}
            
            # Write the variable and value to terraform.tfvars
            echo "$variable = \"$value\"" >> terraform.tfvars
        fi
    done
}

# Function to decrypt the terraform.tfvars file
decrypt_tfvars() {
    # Read the terraform.tfvars file
    read_tfvars_to_array

    # Decrypt the array
    decrypt_array

    # Write the array to the terraform.tfvars file
    write_array_to_tfvars
}

# Function to encrypt the terraform.tfvars file
encrypt_tfvars() {
    # Read the terraform.tfvars file
    read_tfvars_to_array

    # Decrypt the array
    encrypt_array

    # Write the array to the terraform.tfvars file
    write_array_to_tfvars
}


# Main script logic
case "$1" in
    "encrypt")
        encrypt_tfvars
        ;;
    "decrypt")
        decrypt_tfvars
        ;;
    *)
        echo "Usage: $0 {encrypt|decrypt}"
        echo "  encrypt       - Encrypts the terraform.tfvars file"
        echo "                 Usage: $0 encrypt"
        echo "  decrypt...... - Decrypts the terraform.tfvars file"
        echo "                 Usage: $0 decrypt"
        echo ""
        echo "Note: Set your master key in the MASTER_KEY environment variable:"
        echo "export MASTER_KEY='your-secure-key'"
        exit 1
        ;;
esac 