#!/usr/bin/env bash
#
# Script for getting user info based on name
#
#

#Set variables
DISPLAYNAME=${DISPLAYNAME:?"DISPLAYNAME REQUIRED"}
REQUIREDVARIABLE=${REQUIREDVARIABLE:='mail'}
#Required variables for authentication
client_id=${CLIENT_ID:?"GRAPH API CLIENT ID REQUIRED"}
client_secret=${CLIENT_SECRET:?"GRAPH API SECRET ID REQUIRED"}

#Obtain access token
function get_access_token {
    token_url='https://login.microsoftonline.com/mateco.eu/oauth2/v2.0/token'

    scope='https://graph.microsoft.com/.default'

    token_response=$(curl -s -X POST "$token_url" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "client_id=$client_id" \
        --data-urlencode "scope=$scope" \
        --data-urlencode "client_secret=$client_secret" \
        --data-urlencode "grant_type=client_credentials")

    token_object=$(echo "$token_response" | jq -r '.access_token')
    echo "$token_object"
}


#Get user info from Graph API
function get_users {
    access_token=$(get_access_token)
    graph_api_url="https://graph.microsoft.com/v1.0/users?%24filter=startswith(displayName,%20%27${DISPLAYNAME}%27)"

    graph_response=$(curl -s -X GET "$graph_api_url" \
        -H "Authorization: Bearer $access_token")

    users=$(echo "$graph_response" | jq '.')
    echo $users
}


#Main script
function display_users_info {
    QUERY=$(get_users | jq -r ".value[0].$REQUIREDVARIABLE")
    echo "MAIL=$QUERY"  > "$BITBUCKET_PIPE_STORAGE_DIR/mail.txt"

}

#Run script
display_users_info