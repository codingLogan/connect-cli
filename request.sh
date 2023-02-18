#!/bin/bash

# Example usage
# request.sh <user.sh> {p|s}

# Define colors you want
COLOR_ENV='\033[1;33m'
COLOR_LOCAL='\033[0;32m'
COLOR_RESET='\033[0m'
COLOR_ERROR='\033[31m'
COLOR_DATA='\033[35m'

left_echo()
{
  echo "| $1"
}

error_text()
{
  printf "${COLOR_ERROR}$1${COLOR_RESET}\n"
}

help_prompt()
{
  error_text "Expected Syntax: 'request.sh <user.sh> {p|s}'"
  error_text ""
  error_text "To open the help menu use the '-h' argument"
  error_text "request.sh -h"
}

header()
{
  left_echo "===================="
  left_echo "Connect CLI (alpha)"
  left_echo "===================="
  echo ""
}

user_options()
{
  error_text "A user.sh file must be provided.  You currently have these options in ./users"
  ls ./users
  echo ""
}

help()
{
  left_echo "=== Connect CLI Help ================"
  left_echo ""
  left_echo "This utility requires 2 params"
  left_echo "1. The name of the shell script that exports ENV variables with user info: ex: 'example.sh'"
  left_echo "2. An API option of either 'p' or 's'"
  left_echo ""
  left_echo "Syntax: 'request.sh <user.sh> {p|s}'"
  left_echo ""
  left_echo "p = Platform API"
  left_echo "s = SSO/Wormhole API"
  left_echo ""
  left_echo "example usage to request Connect using the Platform API..."
  left_echo "./request.sh example.sh p"
  left_echo ""
  left_echo "=== End Help ========================"
}

extract_url()
{
  WIDGET_DATA=$(</dev/stdin)

  # Use regex to get only the url from json
  REGEX_CONNECT_URL='"(http[^, "]*)'
  [[ $WIDGET_DATA =~ $REGEX_CONNECT_URL ]]

  printf "\n${COLOR_ENV}(Environment URL) ${COLOR_RESET}\n"
  echo "${BASH_REMATCH[1]}"

  REGEX_CONNECT_URL='"http[s]*:\/\/[^, "\/]*\/([^, "]*)'
  [[ $WIDGET_DATA =~ $REGEX_CONNECT_URL ]]

  printf "\n${COLOR_LOCAL}(Local URL) ${COLOR_RESET}\n"
  echo "http://localhost:3000/${BASH_REMATCH[1]}"
}

header

# Print the help menu if requested
if [ "$1" = "-h" ]
then
  help
  exit
fi

# No aruments provided
if [ "$1" = "" ]
then
  user_options
  help_prompt
  exit 1
fi

# Invalid API argument
if [ "$2" != "p" ] && [ "$2" != "s" ]
then
  error_text "A valid API option must be selected..."
  echo ""
  help_prompt
  exit 1
fi

# Import ENV VARS from user file in ./users/<user>.sh
# Using user provided values like this is likely dangerous
source ./users/$1
echo "Get URL for users ${USER_GUID}"

case $2 in
  "p")
    echo "Using Platform API"

    curl -i -X POST "https://api.${USER_ENVIRONMENT}.internal.mx/users/${USER_GUID}/widget_urls" \
    -H 'Accept: application/vnd.mx.api.v1+json' \
    -H 'Content-Type: application/json' \
    -H 'Accept-Language: en-US' \
    -u "${USER_CLIENT_EXTERNAL}:${USER_CLIENT_API_KEY}" \
    -d '{"widget_url":
    {
    "color_scheme": "light",
    "mode": "verification",
    "widget_type": "connect_widget",
    "current_institution_guid": "INS-075dd710-ec98-4ad4-9df3-1be9a5151be9",
    "disable_institution_search": true,
    "ui_message_version": 4
    }}' | tail -n 1 | extract_url
    ;;

  "s")
    echo "Using SSO/Wormhole"

    curl --location --request POST "https://sso.${USER_ENVIRONMENT}.internal.mx/${USER_CLIENT_EXTERNAL}/users/${USER_NAME_EXTERNAL}/urls.json" \
    --header 'Content-Type: application/vnd.moneydesktop.sso.v3+json' \
    --header 'Accept: application/vnd.moneydesktop.sso.v3+json' \
    --header 'Accept-Language: en-US' \
    --header "MD-API-KEY: ${USER_CLIENT_API_KEY}" \
    --data-raw '{"url": {"color_scheme":"dark","type": "connect_widget","mode":"verification", "disable_background_agg": true}}' | tail -n 1 | extract_url
    ;;

  *)
    echo "Invalid API selection, use p or s"
    exit 1;
    ;;
esac
