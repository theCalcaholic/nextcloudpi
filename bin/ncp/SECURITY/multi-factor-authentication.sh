#!/usr/bin/env bash

# Authentication Options:
# =======================
# * Password
# * Pubkey
# * TOTP + Password
# (* TOTP + Pubkey + Password) not yet supported
# * TOTP + Password / TOTP + Pubkey

PAMD_PATH="/etc/pam.d"
PAMD_BACKUP_PATH="/etc/pam.backup"
SSHD_CONFIG_PATH="/etc/ssh/sshd_config"


# Configure pam.d/sshd config
# ======================

patch_pam_ssh_config() {
  local cfg

  if [[ "$1" == "--reset" ]]
  then
    if [[ -f "${PAMD_BACKUP_PATH}/sshd" ]]; then
      echo "Restoring original configuration for '${PAMD_PATH}/sshd'..."
      mv "${PAMD_BACKUP_PATH}/sshd" "${PAMD_PATH}/sshd" || return 1
      rm "${PAMD_PATH}/sshd-mfa"
      return 0
    else
      echo "ERROR: Could not restore '${PAMD_PATH}/sshd' from backup '${PAMD_BACKUP_PATH}/sshd' (not found)!"
      return 1
    fi
  fi

  mkdir -p "$PAMD_BACKUP_PATH"
  [[ -f "${PAMD_BACKUP_PATH}/sshd" ]] || {
    echo "Backing up '${PAMD_PATH}/sshd'..."
    cp "${PAMD_PATH}/sshd" "${PAMD_BACKUP_PATH}/sshd"
  } || {
    echo "Error creating backup. '${PAMD_PATH}/sshd will remain unchanged!"
    return 1
  }

  echo "Writing pam configuration..."
  if [[ "$enable_totp_and_pw" != "yes" ]]
  then
    cp "${PAMD_BACKUP_PATH}/sshd" "${PAMD_PATH}/sshd" || return 1
    [[ -f "${PAMD_PATH}/sshd-mfa" ]] && rm "${PAMD_PATH}/sshd-mfa"
    return 0
  fi
  echo "" > "${PAMD_PATH}/sshd-mfa" || return 1

  if [[ "$enable_totp_and_pw" == "yes" ]]; then
    echo "auth required pam_google_authenticator.so nullok" >> "${PAMD_PATH}/sshd-mfa"
  fi
  echo "@include common-auth" >> "${PAMD_PATH}/sshd-mfa"

  sed 's/@include.*common-auth/@include sshd-mfa/g' "${PAMD_BACKUP_PATH}/sshd" > "${PAMD_PATH}/sshd" || return 1


}

# Configure sshd_config
# =====================

#sshd_authentication_options=("password" "publickey" "publickey,password" "keyboard-interactive"
#  "keyboard-interactive,publickey" "keyboard-interactive,publickey keyboard-interactive,password")
patch_sshd_config() {
  local cfg
  local auth_method="${1?}"

  if [[ "$auth_method" == "--reset" ]]
  then
    if [[ -f "${SSHD_CONFIG_PATH}.backup" ]]
    then
      echo "Restoring '${SSHD_CONFIG_PATH}' from '${SSHD_CONFIG_PATH}.backup'..."
      mv "${SSHD_CONFIG_PATH}.backup" "${SSHD_CONFIG_PATH}" || return 1
      return 0
    else
      echo "ERROR: Could not restore '${SSHD_CONFIG_PATH}' from '${SSHD_CONFIG_PATH}.backup' (not found)!"
      return 1
    fi
  fi

  # backup sshd_config
  mkdir -p /etc/pam.backup
  [[ -f "${SSHD_CONFIG_PATH}.backup" ]] || {
    echo "Backing up '${SSHD_CONFIG_PATH}'..."
    cp "$SSHD_CONFIG_PATH" "${SSHD_CONFIG_PATH}.backup"
  } || {
    echo "Error creating backup. '${PAMD_PATH}/sshd will remain unchanged!"
    return 1
  }

  # get sshd_config without google_authenticator
  cfg="$(
    grep -v -e "AuthenticationMethods" "${SSHD_CONFIG_PATH}.backup" |
      grep -v -e "ChallengeResponseAuthentication" |
      grep -v -e "PubkeyAuthentication" |
      grep -v -e "PasswordAuthentication" |
      grep -v -e "UsePAM"
  )"

  echo "Writing sshd configuration..."
  echo "$cfg" > "$SSHD_CONFIG_PATH" || return 1
  cat << EOF >> "$SSHD_CONFIG_PATH"

###################################

PasswordAuthentication yes
PubkeyAuthentication yes
ChallengeResponseAuthentication yes
UsePAM yes
AuthenticationMethods $auth_method

EOF

}

setup_configuration() {
  local auth_method=""

  [[ "$enable_pubkey_only" ]] && auth_method="publickey"
  [[ "$enable_pw_only" ]] && auth_method="${auth_method} password"

  [[ "$enable_totp_and_pw" == "yes" ]] && auth_method="keyboard-interactive"
  [[ "$enable_pubkey_and_pw" == "yes" ]] && auth_method="${auth_method} publickey,password"

  patch_pam_ssh_config || return 2
  patch_sshd_config "$auth_method" || return 1
}

setup_totp_secret() {
  local ssh_user="${1?}"
  local ssh_user_home="${2?}"

  [[ "$reset_totp_secret" == "yes" ]] \
  && [[ -f "$ssh_user_home/.google_authenticator" ]] \
  && su "$ssh_user" -c "rm '${ssh_user_home}/.google_authenticator'"

  if [[ "$enable_totp_and_pw" == "yes" ]] && [[ ! -f "${ssh_user_home}/.google_authenticator" ]]
  then
    echo "We will now generate TOTP a client secret for your ssh user ('$ssh_user')."
    echo "Please store the following information in a safe place. Use your secret key or scan the QR code (terminal only) to setup your authenticator app."
    echo ""
    su "$ssh_user" -c "google-authenticator -tdf -w 1 --no-rate-limit"
  fi
}

restore() {
  local ret=0
  patch_pam_ssh_config --reset
  ret=$((ret + $?))
  patch_sshd_config --reset
  ret=$((ret + $?))
  return $ret
}

################################################################

cleanup() {
  restore
  [[ -d "${PAMD_BACKUP_PATH}" ]] && rm -r "${PAMD_BACKUP_PATH}"
}

install() {
  apt install -y libpam-google-authenticator
}

is_active() {
  grep -q -e "AuthenticationMethods.*keyboard-interactive" -e "AuthenticationMethods.*publickey" "${SSHD_CONFIG_PATH}" \
  || grep -q -e "sshd-mfa" "${PAMD_PATH}/sshd"
}

configure() {

  local active enable_totp_and_pw enable_pubkey_and_pw enable_pubkey_only enable_pw_only reset_totp_secret ssh_pubkey
  enable_totp_and_pw="$ENABLE_TOTP_AND_PASSWORD"
  enable_pubkey_and_pw="$ENABLE_PUBLIC_KEY_AND_PASSWORD"
  enable_pubkey_only="$ENABLE_PUBLIC_KEY_ONLY"
  enable_pw_only="$ENABLE_PASSWORD_ONLY"
  reset_totp_secret="$RESET_TOTP_SECRET"
  active="$ACTIVE"
  ssh_pubkey="$(unescape "$SSH_PUBLIC_KEY")"

  trap 'restore' HUP INT QUIT PIPE TERM

  if [[ "$active" == "yes" ]] && [[ "$enable_totp_and_pw" != "yes" ]] \
  && [[ "$enable_pubkey_and_pw" != "yes" ]] && [[ "$enable_pubkey_only" != "yes" ]]
  then
    [[ $enable_pw_only ]] \
    || echo "WARNING: No authentication method has been enabled. Enabling default authentication (password only)..."
    active="no"
  fi

  if [[ "$active" != "yes" ]]
  then
    ret=0
    is_active && { restore || ret=$?; }
    systemctl is-enabled ssh -q && systemctl restart ssh
    return $ret
  else
#    ENABLE_TOTP_AND_PASSWORD=""
#    ENABLE_PUBLIC_KEY_AND_PASSWORD=""
#    ENABLE_PUBLIC_KEY_ONLY=""

    if [[ "$enable_totp_and_pw" == "yes" ]] || [[ "$enable_pubkey_and_pw" ]]
    then
      if [[ "$ENABLE_PUBLIC_KEY_ONLY" == "yes" ]]
      then
        echo "At least one multifactor authentication method has been enabled. Therefore, weaker authentication methods will be disabled automatically."
        echo "Disabling 'public key only' authentication"
        enable_pubkey_only=no
      fi
    fi
  fi

  echo "Setting up configuration files..."
  setup_configuration || {
    ret=$?
    restore
    return $ret
  }

  echo "Restarting ssh service..."
  systemctl is-enabled ssh -q && systemctl restart ssh

  # TODO: Should we rather provider an input field for the SSH user (what happens if it is changed in the ssh config)?
  SSH_USER="$(jq -r '.params[] | select(.id == "USER") | .value' < /usr/local/etc/ncp-config.d/SSH.cfg)"
  SSH_USER_HOME="$(sudo -Hu "$SSH_USER" bash -c 'echo "$HOME"')"

  [[ -n "$SSH_USER" ]] || id -u "$SSH_USER" > /dev/null || {
    echo "Setup incomplete. Please configure SSH via the ncp app and rerun."
    return 1
  }

  # Setup SSH public key if provided
  if [[ -n "$ssh_pubkey" ]]
  then
    echo "Setting up SSH public key..."
    echo "$ssh_pubkey" > "${SSH_USER_HOME}/.ssh/authorized_keys"
    chown "${SSH_USER}:" "${SSH_USER_HOME}/.ssh/authorized_keys"
  fi

  setup_totp_secret "$SSH_USER" "$SSH_USER_HOME"

  echo "Done."

}