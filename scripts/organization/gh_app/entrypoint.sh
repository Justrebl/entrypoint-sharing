#!/usr/bin/env bash

#Importing functions from .functions.sh file, split for clarity
. entrypoint.functions.sh

set -o pipefail

# Retrieving environment variables in a clean format (with or without quotes) for ease of use
gh_app_private_key=$(clean_env_var "${GH_APP_PRIVATE_KEY}")
registration_token_api_url=$(clean_env_var "${REGISTRATION_TOKEN_API_URL}")
gh_url=$(clean_env_var "${GH_URL}")
labels=$(clean_env_var "${LABELS}")
gh_app_client_id=$(clean_env_var "${GH_APP_CLIENT_ID}")
gh_app_installation_id=$(clean_env_var "${GH_APP_INSTALLATION_ID}")

# Create JWT from GH app client id and private key
jwt=$(generate_jwt "${gh_app_client_id}" "${gh_app_private_key}")

if [ -n "$jwt" ]; then
    echo "JWT generated successfully"
else
    echo "Failed to generate JWT"
    exit 1
fi

# Get the access token
access_token=$(get_access_token "${gh_app_installation_id}" "${jwt}")

if [ -n "$access_token" ]; then
    echo "access token generated successfully : ${access_token}"
else
    echo "Failed to generate access token"
    exit 1
fi

# Retrieve a short lived runner registration token using the GH App Access Token
reg_token=$(get_registration_token "${registration_token_api_url}" "${access_token}")

if [ -n "$reg_token" ]; then
    echo "Registration token generated successfully : ${reg_token}"
else
    echo "Failed to generate registration token"
    exit 1
fi

# Configure and run the Github Self Hosted Runner
echo "Starting the Github Self Hosted Runner ..."
./config.sh --url ${gh_url} --token $reg_token --unattended --ephemeral --labels ${labels} && ./run.sh