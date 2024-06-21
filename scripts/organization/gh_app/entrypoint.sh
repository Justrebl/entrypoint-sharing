#!/usr/bin/env bash

#Importing functions from .functions.sh file, split for clarity
. entrypoint.functions.sh

set -o pipefail

# set local variables from ENV variables for clarity and ease of potential future evolutions
# pem=${PRIVATE_KEY}
# org=${GH_URL}
# reg_url=${REGISTRATION_TOKEN_API_URL}
# labels=${LABELS}
# client_id=${GH_APP_CLIENT_ID}
# inst_id=${}

# Create JWT from GH app client id and private key
jwt=$(generate_jwt "${GH_APP_CLIENT_ID}" "${PRIVATE_KEY}")

if [ -n "$jwt" ]; then
    echo "JWT generated successfully : ${jwt}"
else
    echo "Failed to generate JWT"
    exit 1
fi

# Get the access token
access_token=$(get_access_token "${GH_APP_INSTALLATION_ID}" "${jwt}")

if [ -n "$access_token" ]; then
    echo "access token generated successfully : ${access_token}"
else
    echo "Failed to generate access token"
    exit 1
fi

# Retrieve a short lived runner registration token using the GH App Access Token
reg_token=$(get_registration_token "${REGISTRATION_TOKEN_API_URL}" "${access_token}")

if [ -n "$reg_token" ]; then
    echo "Registration token generated successfully : ${reg_token}"
else
    echo "Failed to generate registration token"
    exit 1
fi

# Configure and run the Github Self Hosted Runner
echo "Starting the Github Self Hosted Runner ..."
./config.sh --url $GH_URL --token $reg_token --unattended --ephemeral --labels $LABELS && ./run.sh