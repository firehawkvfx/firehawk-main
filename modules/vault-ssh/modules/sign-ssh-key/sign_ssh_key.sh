#!/bin/bash

set -e

EXECDIR="$(pwd)"
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script
readonly SCRIPT_NAME="$(basename "$0")"
cd "$SCRIPTDIR"

readonly DEFAULT_PUBLIC_KEY="$HOME/.ssh/id_rsa.pub"
readonly DEFAULT_TRUSTED_CA="/etc/ssh/trusted-user-ca-keys.pem"
readonly DEFAULT_SSH_KNOWN_HOSTS="/etc/ssh/ssh_known_hosts"
readonly DEFAULT_SSH_KNOWN_HOSTS_FRAGMENT=$HOME/.ssh/ssh_known_hosts_fragment

# These helper functions are from the sign_ssh_key.sh Hashicorp script



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
  echo "Example: Sign this hosts public key with Vault."
  echo
  echo "  sign_ssh_key.sh"
  echo
  echo "Example: Sign a non-default public key with Vault.  If the key does not exist at this location, user will be prompted to paste the key in."
  echo
  echo "  sign_ssh_key.sh --public-key ~/.ssh/remote_host/id_rsa.pub"
  echo
  echo "Example: On a Remote host configure a provided cert file and trusted CA file where vault access is unavailable."
  echo
  echo "  sign_ssh_key.sh --trusted-ca ~/Downloads/trusted-user-ca-keys.pem --cert ~/Downloads/id_rsa-cert.pub"
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

function request_trusted_ca {
  local -r trusted_ca="$1"
  # Aquire the public CA cert to approve an authority for known hosts.
  vault read -field=public_key ssh-client-signer/config/ca | sudo tee $trusted_ca
}

function configure_trusted_ca {
  local -r trusted_ca="$1"
  sudo chmod 0644 "$trusted_ca"
  # If TrustedUserCAKeys not defined, then add it to sshd_config
  sudo grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo 'TrustedUserCAKeys' | sudo tee -a /etc/ssh/sshd_config
  # Ensure the value for TrustedUserCAKeys is configured correctly
  # sudo sed -i "s@TrustedUserCAKeys.*@TrustedUserCAKeys $trusted_ca@g" /etc/ssh/sshd_config 
  sudo python $SCRIPTDIR/replace_value.py -f /etc/ssh/sshd_config "TrustedUserCAKeys " "$trusted_ca"
}

function configure_cert {
  local -r cert="$1"
  sudo chmod 0644 "$cert"

  # View result metadata
  ssh-keygen -Lf "$cert"

  log_info "Restarting SSH service..."
  # mac / centos / amazon linux, restart ssh service
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
  else
    sudo systemctl restart sshd
  fi

  log_info "Done signing SSH client key."
}

function request_sign_public_key {
  local -r public_key="$1"
  local -r trusted_ca="$2"
  local -r cert="$3"
  local -r ssh_known_hosts="$DEFAULT_SSH_KNOWN_HOSTS"

  if [[ "$public_key"!="$DEFAULT_PUBLIC_KEY" ]]; then
    log "Copying $trusted_ca to $(dirname $public_key). Ensure you download this file to $trusted_ca if you intend to connect from a remote client."
    sudo cp $trusted_ca $(dirname $public_key)
    log "Configuring known hosts. To ensure $ssh_known_hosts is current before copying to homedir for download."
    $SCRIPTDIR/../known-hosts/known_hosts.sh
    log "Copying $DEFAULT_SSH_KNOWN_HOSTS_FRAGMENT to $(dirname $public_key).  Ensure you download this file to a remote client if you intend to connect from that client, ensuring ssh hosts have valid certs."
    sudo rm -fv "$DEFAULT_SSH_KNOWN_HOSTS_FRAGMENT" # if the file is the same, cp will raise a non 0 exit code, so we remove it.
    sudo cp -f "$DEFAULT_SSH_KNOWN_HOSTS_FRAGMENT" "$(dirname $public_key)"
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
  local trusted_ca=""
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
  
  if [[ -z "$trusted_ca" ]]; then # if no trusted ca provided, request it from vault and store in default location.
    trusted_ca="$DEFAULT_TRUSTED_CA"
    log_info "Requesting Vault provide the trusted CA..."
    request_trusted_ca "$trusted_ca"
  else
    log_info "Trusted CA path provided. Skipping vault request. Copy to standard path..."
    cp -frv "$trusted_ca" "$DEFAULT_TRUSTED_CA"
    trusted_ca="$DEFAULT_TRUSTED_CA"
  fi
  log_info "Configure this host to use trusted CA"
  configure_trusted_ca "$trusted_ca" # configure trusted ca for our host

  if [[ -z "$cert" ]]; then # if no cert provided, request it from vault and store in along side the public key.
    # if public key doesn't exist, allow user to paste it in
    if test ! -f "$public_key"; then
      log_info "Public key not present at location."
      log_info "You can paste the contents of the new file here (read the public key on the remote host eg: cat ~/.ssh/id_rsa.pub):"
      mkdir -p $(dirname "$public_key")
      read public_key_content
      echo "$public_key_content" | tee "$public_key"
    fi
    log_info "Requesting Vault sign public key for this SSH client..."
    cert=${public_key/.pub/-cert.pub}
    request_sign_public_key "$public_key" "$trusted_ca" "$cert"
  else
    log_info "Cert path provided: public key already signed. copying to default ssh dir ~/.ssh"
    sudo cp -frv "$cert" ~/.ssh
    cert="$(sudo basename $cert)"
    cert="$HOME/.ssh/$cert"
  fi
  log_info "Configure cert for use: $cert"
  configure_cert "$cert"
  log_info "Complete!"
}

install "$@"

cd $EXECDIR