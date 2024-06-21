#entrypoint_org_gh_app.functions.sh

generate_jwt() {
    local client_id="$1"
    local private_key="$2"
    echo "private_key is $private_key"

    local now=$(date +%s)
    local iat=$((${now} - 60)) # Issues 60 seconds in the past
    local exp=$((${now} + 600)) # Expires 10 minutes in the future

    b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

    local header_json='{
        "typ":"JWT",
        "alg":"RS256"
    }'
    # Header encode
    local header=$(echo -n "${header_json}" | b64enc)

    local payload_json='{
        "iat":'"${iat}"',
        "exp":'"${exp}"',
        "iss":'"${client_id}"'
    }'
    # Payload encode
    local payload=$(echo -n "${payload_json}" | b64enc)

    # Signature
    local header_payload="${header}"."${payload}"
    local signature=$(
        openssl dgst -sha256 -sign <(echo -n "${private_key}") \
        <(echo -n "${header_payload}") | b64enc
    )

    # Create JWT
    local jwt="${header_payload}"."${signature}"
    echo "${jwt}"
}

get_access_token() {
    local inst_id="$1"
    local jwt="$2"

    # Appel API pour obtenir le token d'accès
    local access_token_response="$(curl --request POST \
    --url "https://api.github.com/app/installations/${inst_id}/access_tokens" \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: Bearer ${jwt}" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    -fsSL)"

    # Extraction du token d'accès de la réponse
    local token=$(echo "${access_token_response}" | jq -r '.token')

    echo "${token}"
}

get_registration_token() {
    local reg_url="$1"
    local token="$2"

    # Appel API pour obtenir le token d'enregistrement
    local reg_token="$(curl --request POST \
        --url $reg_url \
        --header 'Accept: application/vnd.github.v3+json' \
        --header "Authorization: Bearer ${token}" \
        --header 'X-GitHub-Api-Version: 2022-11-28' \
        -fsSL \
      | jq -r '.token')"
    echo "${reg_token}"
}

clean_env_var() {
  echo "$1" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"
}