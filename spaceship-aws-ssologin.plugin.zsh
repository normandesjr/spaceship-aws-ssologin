#
# AWS SSO Login
#
# This plugins shows you which AWS Account your are logged in when the method used 
# was sso login, like "aws sso login"

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_AWS_SSOLOGIN_SHOW="${SPACESHIP_AWS_SSOLOGIN_SHOW=true}"
SPACESHIP_AWS_SSOLOGIN_ASYNC="${SPACESHIP_AWS_SSOLOGIN_ASYNC=true}"
SPACESHIP_AWS_SSOLOGIN_PREFIX="${SPACESHIP_AWS_SSOLOGIN_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"}"
SPACESHIP_AWS_SSOLOGIN_SUFFIX="${SPACESHIP_AWS_SSOLOGIN_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_AWS_SSOLOGIN_SYMBOL="${SPACESHIP_AWS_SSOLOGIN_SYMBOL="☁️ "}"
SPACESHIP_AWS_SSOLOGIN_COLOR="${SPACESHIP_AWS_SSOLOGIN_COLOR="yellow"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show AWS SSO Login account name
spaceship_aws_ssologin() {
  [[ $SPACESHIP_AWS_SSOLOGIN_SHOW == false ]] && return

  aws_dir="${AWS_DIR:-$HOME/.aws}"
  cache_dir="$aws_dir/sso/cache"
  accounts_conf="$aws_dir/accounts.conf"

  account_names=()
  current_utc_epoch=$(date -u +%s)

  for file in $(find $cache_dir -type f -name "*.json"); do
    # Its mandatory to have startUrl property
    if ! jq -e '.startUrl != null' "$file" >/dev/null 2>&1; then
      continue
    fi

    expires_at_str=$(jq -r '.expiresAt' "$file")
    expires_at_epoch=$(date -u -d "$expires_at_str" +%s 2>/dev/null)
    if (( current_utc_epoch > expires_at_epoch )); then
      continue
    fi

    client_id=$(jq -r '.clientId' "$file")
    account_name=$(grep "^$client_id=" "$accounts_conf" 2>/dev/null | cut -d'=' -f2)
    if [[ -n "$account_name" ]]; then
        account_names+=("$account_name")
    else
        account_names+=("$client_id")
    fi
  done 

  if [[ ${#account_names[@]} -gt 0 ]]; then
    joined_account_names="${(j: :)account_names}"

  # Display AWS SSO Login section
    spaceship::section::v4 \
      --color "$SPACESHIP_AWS_SSOLOGIN_COLOR" \
      --prefix "$SPACESHIP_AWS_SSOLOGIN_PREFIX" \
      --suffix "$SPACESHIP_AWS_SSOLOGIN_SUFFIX" \
      --symbol "$SPACESHIP_AWS_SSOLOGIN_SYMBOL" \
      "$joined_account_names"
  else
    return
  fi
}
