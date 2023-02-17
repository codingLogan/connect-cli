#!/bin/bash

# Example usage
# request.sh <userfile> [p|s]

echo "============================================================================="
echo "Connect CLI (alpha)"
echo ""
echo "Syntax:"
echo "./request.sh <userfile> [p|s]"
echo "p = Platform API"
echo "s = SSO/Wormhole"
echo ""
echo "example usage to request Connect using the Platform API..."
echo "./request.sh example.sh p"
echo "============================================================================="
echo ""

if [ "$1" = "" ]
then
  echo "============================================================================="
  echo "A user.sh file must be provided.  You currently have these options in ./users"
  echo ""
  echo "Copy example.sh, rename it, and provide your information to get started :)"
  echo "============================================================================="
  ls ./users
  exit
fi

# Import ENV VARS from user file in ./users/<user>.sh
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
    }}';;

  "s")
    echo "Using SSO/Wormhole"

    curl --location --request POST "https://sso.${USER_ENVIRONMENT}.internal.mx/${USER_CLIENT_EXTERNAL}/users/${USER_NAME_EXTERNAL}/urls.json" \
    --header 'Content-Type: application/vnd.moneydesktop.sso.v3+json' \
    --header 'Accept: application/vnd.moneydesktop.sso.v3+json' \
    --header 'Accept-Language: en-US' \
    --header "MD-API-KEY: ${USER_CLIENT_API_KEY}" \
    --data-raw '{"url": {"color_scheme":"dark","type": "connect_widget","mode":"verification", "disable_background_agg": true}}'
    ;;

  *)
    echo "Invalid API selection, use p or s"
    exit 1;
    ;;
esac
