#!/bin/bash

set -e

readonly DEFAULT_PUBLIC_KEY="$HOME/.ssh/id_rsa.pub"
readonly DEFAULT_TRUSTED_CA="/etc/ssh/trusted-user-ca-keys.pem"

# These helper functions are from the sign_ssh_key.sh Hashicorp script

readonly SCRIPT_NAME="$(basename "$0")"

function print_usage {
  echo
  echo "Usage: sign_ssh_key.sh [OPTIONS]"
  echo
  echo "If authenticated to Vault, signs a public key with Vault for use as an SSH client, generating a public certificate in the same directory as the public key with the suffix '-cert.pub'."
  echo
  echo "Options:"
  echo
  echo -e "  --public-key\tThe public key to sign (Must end in .pub lowercase). Optional. Default: $DEFAULT_PUBLIC_KEY."
  echo
  echo "Example:"
  echo
  echo "  sign_ssh_key.sh"
}

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local -r message="$1"
  log "INFO" "$message"
}

function log_warn {
  local -r message="$1"
  log "WARN" "$message"
}

function log_error {
  local -r message="$1"
  log "ERROR" "$message"
}

function assert_not_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

function configure_trusted_ca {
  local -r trusted_ca="$1"
  # Aquire the public CA cert to approve an authority for known hosts.
  local -r trusted_ca="/etc/ssh/trusted-user-ca-keys.pem"
  vault read -field=public_key ssh-client-signer/config/ca | sudo tee $trusted_ca
  # If TrustedUserCAKeys not defined, then add it to sshd_config
  sudo grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo 'TrustedUserCAKeys' | sudo tee -a /etc/ssh/sshd_config
  # Ensure the value for TrustedUserCAKeys is configured correctly
  sudo sed -i "s@TrustedUserCAKeys.*@TrustedUserCAKeys $trusted_ca@g" /etc/ssh/sshd_config 
}

function configure_cert {
  local -r cert="$3"
  sudo chmod 0644 $cert

  # View result metadata
  ssh-keygen -Lf $cert

  # centos / amazon linux, restart ssh service
  sudo systemctl restart sshd
  log_info "Signing SSH client key done."
}

function sign_public_key {
  local -r public_key="$1"
  local -r trusted_ca="$2"
  local -r cert="$3"

  if [[ "$public_key"!="$DEFAULT_PUBLIC_KEY" ]]; then
    log "Copying $trusted_ca to $(dirname $public_key). Ensure you download this file to $trusted_ca if you intend to connect from a remote client."
    sudo cp $trusted_ca $(dirname $public_key)
  fi

  log_info "Signing public key"
  
  vault write ssh-client-signer/sign/ssh-role \
      public_key=@$public_key

  # Save the signed public cert
  vault write -field=signed_key ssh-client-signer/sign/ssh-role \
      public_key=@$public_key > $cert
}

# You should be able to ssh into a target host:
# ssh -i signed-cert.pub -i ~/.ssh/id_rsa username@10.0.23.5

function install {
  local public_key="$DEFAULT_PUBLIC_KEY"
  local trusted_ca="$DEFAULT_TRUSTED_CA"
  local cert=""
  
  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --public-key)
        assert_not_empty "$key" "$2"
        public_key="$2"
        shift
        ;;
      --trusted-ca)
        assert_not_empty "$key" "$2"
        trusted_ca="$2"
        shift
        ;;
      --cert)
        assert_not_empty "$key" "$2"
        cert="$2"
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        log_error "Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done
  
  configure_trusted_ca "$trusted_ca"
  if [[ -z "$cert" ]]; then;
    log_info "Will sign public key"
    cert=${public_key/.pub/-cert.pub}
    sign_public_key "$public_key" "$trusted_ca" "$cert"
  else
    log_info "Cert path provided: public key already signed."
  fi
  log_info "Configure cert for use"
  configure_cert "$cert"
  log_info "Complete!"
}

install "$@"