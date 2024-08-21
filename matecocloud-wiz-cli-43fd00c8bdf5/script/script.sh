#!/usr/bin/env bash
#
# Pipe made for executing an wiz cli scan
#

#COLORS FOR OUTPUT PURPOSES
RED='\e[31m'
GREEN='\e[32m'
R='\e[0m'
#usage: echo -e "${RED}This is red text${R}"
 
#Required variables for IAC scan
JSONFILE=${JSONFILE:=""}

#Required variables for DOCKER scan
GOOGLE_SERVICE_ACCOUNT_KEY=${GOOGLE_SERVICE_ACCOUNT_KEY:=""}
TAG=${TAG:=""}

#Required variables for both
WIZ_CLIENT_ID=${WIZ_CLIENT_ID:?"WIZ CLIENT ID REQUIRED"}
WIZ_CLIENT_SECRET=${WIZ_CLIENT_SECRET:?"WIZ SECRET ID REQUIRED"}
POLICY=${POLICY:?"POLICY TYPE REQUIRED"}
SCAN_TYPE=${SCAN_TYPE:?"SCAN TYPE REQUIRED, IAC OR DOCKER"}

#Other variables
MAIL=${MAIL:='false'}
TEAMS=${TEAMS:='false'}
TEAMS_WEBHOOK_URL=${TEAMS_WEBHOOK_URL:=''}
 
iac_scan() {
    #Authenticate to wiz
    wizcli auth --id "$WIZ_CLIENT_ID" --secret "$WIZ_CLIENT_SECRET"
 
    #Scan wizcli
    wizcli iac scan --policy "$POLICY" --format json --path $JSONFILE > output.json
 
    #Beautify json for teams and mail
    jq . output.json > iac.json

    SUCCESS=$(jq -r '.status.verdict' < iac.json)

    if [[ "$SUCCESS" == "FAILED_BY_POLICY" ]]; then
        echo -e "${RED}FAILED BY POLICY, TOO MANY MISCONFIGURATIONS...${R}"
    fi
}

docker_scan(){

    #Authenticate to GCP
    echo -n ${GOOGLE_SERVICE_ACCOUNT_KEY} | docker login -u _json_key --password-stdin http://$TAG

    #Build the dockerfile
    docker build -f Dockerfile -t $TAG .

    #Authenticate to wiz
    wizcli auth --id "$WIZ_CLIENT_ID" --secret "$WIZ_CLIENT_SECRET"

    #Scan the dockerfile
    wizcli docker scan --image $TAG --policy $POLICY --format human --output /docker.json,json,true,default

    SUCCESS=$(jq -r '.status.verdict' < /docker.json)

    if [[ "$SUCCESS" == "FAILED_BY_POLICY" ]]; then
        echo -e "${RED}DOCKER IMAGE FAILED BY POLICY, NOT PUSHING...${R}"
        echo -e "${RED}EXITING PIPELINE...${R}"
        exit 1
    else
        echo -e "${GREEN}DOCKER IMAGE OK, PUSHING TO REPOSITORY..."
        docker push $TAG
    fi
}
 
construct_teams_body() {
    local json_file="$1"
    local content=''
    local number_card=1
    local title=""
    local description=""

    # Determine title and description based on success/failure
    if [[ $(jq -r '.status.verdict' < "$json_file") == "FAILED_BY_POLICY" ]]; then
        title="Pipeline build has failed"
    else
        title="Pipeline build has succeeded"
    fi

    description="Policy: ${POLICY}"$'\n'

    # Count how many times the severity is present
    declare -A severity_count
    while IFS= read -r i; do
        severity=$(jq -cr '.severity' <<< "$i")
        ((severity_count["$severity"]++))
    done < <(jq -cr '.result.ruleMatches[]' "$json_file")

    # Generate description based on severity counts
    local summary=""
    for severity in "${!severity_count[@]}"; do
        summary+="${severity_count[$severity]} $severity, "
    done
    summary="${summary%,*}"  # Remove trailing comma and space

    # Update description with severity summary
    severities="Total misconfigurations found: $summary."

    # Add title and updated description to content
    content+="{\"type\": \"TextBlock\",\"text\": \"$title\",\"weight\": \"Bolder\",\"wrap\": true,\"style\": \"default\",\"fontType\": \"Default\",\"size\": \"Large\",\"color\": \"Attention\",\"horizontalAlignment\": \"Center\"},"
    content+="{\"type\": \"TextBlock\",\"text\": \"$description\", \"wrap\": true, \"style\": \"default\", \"weight\": \"Lighter\",\"color\": \"Default\",\"isSubtle\": true,\"horizontalAlignment\": \"Center\" },"
    content+="{\"type\": \"TextBlock\",\"text\": \"$severities\", \"wrap\": true, \"style\": \"default\", \"weight\": \"Lighter\",\"color\": \"Default\",\"isSubtle\": true,\"horizontalAlignment\": \"Center\" },"

    # Iterate over rule matches and add details to content
    while IFS= read -r i; do
        severity=$(jq -cr '.severity' <<< "$i")
        
        # Check if severity is high or critical
        if [[ "$severity" == "HIGH" || "$severity" == "CRITICAL" ]]; then
            name=$(jq -cr '.rule.name' <<< "$i")
            found=$(jq -cr '.matches[0].found' <<< "$i")
            expected=$(jq -cr '.matches[0].expected' <<< "$i")

            # Add details to content
            content+="{\"type\": \"TextBlock\",\"text\": \"---\",\"spacing\": \"Medium\"},"
            content+="{ \"type\": \"TextBlock\", \"text\": \"[$number_card]: $name\", \"wrap\": true, \"weight\": \"Bolder\", \"spacing\": \"Small\", \"horizontalAlignment\": \"Left\" },"
            content+="{ \"type\": \"TextBlock\", \"text\": \"Found: $found\", \"wrap\": true, \"spacing\": \"Small\", \"horizontalAlignment\": \"Left\"  },"
            content+="{ \"type\": \"TextBlock\", \"text\": \"Expected: $expected\", \"wrap\": true, \"spacing\": \"Small\", \"horizontalAlignment\": \"Left\"  },"
            ((number_card++))
        fi
    done < <(jq -cr '.result.ruleMatches[]' "$json_file")
    
    echo "{\"type\":\"Container\",\"items\":[$content]}"
}

construct_mail_html() {
    SUCCESS=$(jq -r '.status.verdict' < iac.json)
 
    # Only send email if the scan fails due to policy violations
    if [[ "$SUCCESS" == "FAILED_BY_POLICY" ]]; then

        # Mail heading
        echo "<h1>Pipeline build has failed</h1>" > mail.html
 
        # Number for list
        NUMBER=1

        # Count how many times the severity is present
        declare -A severity_count
        while IFS= read -r i; do
            severity=$(jq -cr '.severity' <<< "$i")
            ((severity_count["$severity"]++))
        done < <(jq -cr '.result.ruleMatches[]' iac.json)

        # Generate description based on severity counts
        local summary=""
        for severity in "${!severity_count[@]}"; do
            summary+="${severity_count[$severity]} $severity, "
        done
        summary="${summary%,*}"  # Remove trailing comma and space

        echo "<p>Policy used: $POLICY</p>" >> mail.html
        # Update description with severity summary
        echo "<p>Total misconfigurations found: $summary.</p>" >> mail.html


        # Mail body
        while IFS= read -r i; do
            severity=$(jq -cr '.severity' <<< "$i")
            # Check if severity is high or critical
            if [[ "$severity" == "HIGH" || "$severity" == "CRITICAL" ]]; then
                severity=$(jq -cr '.severity' <<< "$i")
                name=$(jq -cr '.rule.name' <<< "$i")
                found=$(jq -cr '.matches[0].found' <<< "$i")
                expected=$(jq -cr '.matches[0].expected' <<< "$i")
    
                # Writing to HTML file
                {
                    echo "<h3>$NUMBER. $name</h3>"
                    echo "<ul>"
                    echo "<li>Severity: $severity</li>"
                    echo "<li>Found: $found</li>"
                    echo "<li>Expected: $expected</li>"
                    echo "</ul>"
                } >> mail.html
    
                ((NUMBER++))
            fi
        done < <(jq -cr '.result.ruleMatches[]' iac.json)
 
        # Link to origin repo
        echo "<a href=\"$BITBUCKET_GIT_HTTP_ORIGIN\">Visit Repo</a>" >> mail.html
 
        # Push to artifact directory -> used by other pipe, maybe integrate
        cat mail.html > "$BITBUCKET_PIPE_STORAGE_DIR/mail.html"
 
        echo -e "${GREEN}MAIL IS MADE${R}"
    fi
}
 
main() {
    case $SCAN_TYPE in
        "iac")
            # Check if required parameters are filled in
            if [[ -z $JSONFILE ]]; then
                echo -e "${RED}JSONFILE environment variable is not set. Please do terraform plan and give the json file${R}"
                exit 1
            fi
            echo -e "${GREEN}EXECUTING WIZ AUTH AND IAC SCAN ${R}"

            # Authenticate and scan wiz cli
            iac_scan
            ;;
        "docker")
            # Check if required parameters are filled in
            if [[ -z $GOOGLE_SERVICE_ACCOUNT_KEY ]]; then
                echo -e "${RED}GOOGLE_SERVICE_ACCOUNT_KEY environment variable is not set. Please enter the credentials to push to AR.${R}"
                exit 1
            fi
            if [[ -z $TAG ]]; then
                echo -e "${RED}TAG environment variable is not set. Please enter the tag of the image.${R}"
                exit 1
            fi
            echo -e "${GREEN}EXECUTING WIZ AUTH AND DOCKER SCAN ${R}"

            # Authenticate and scan wiz cli
            docker_scan
            ;;
        *)
            echo "Unknown SCAN_TYPE: $SCAN_TYPE"
            exit 1
            ;;
    esac

    #Set TEAMS parameter to true in pipeline to use teams webhook
   
    if [[ $TEAMS == 'true' ]]; then
        echo -e "${GREEN}ATTEMPTING TO MAKE TEAMS CARD${R}"
        #Call method to construct teams body, give json of wiz scan
        teams_body=$(construct_teams_body "iac.json")
         
        if [[ -n $TEAMS_WEBHOOK_URL ]]; then
            teams_message="{\"type\":\"message\",\"attachments\":[{\"contentType\":\"application/vnd.microsoft.card.adaptive\",\"contentUrl\":null,\"content\":{\"type\":\"AdaptiveCard\",\"$schema\":\"http://adaptivecards.io/schemas/adaptive-card.json\",\"version\":\"1.5\",\"body\":[$teams_body]}}]}"
            echo $teams_message > teamsmessage.json
            echo -e ${GREEN}SENDING TO TEAMS CHANNEL...${R}
            if ! curl -X POST -H "Content-Type:application/json" -d @teamsmessage.json $TEAMS_WEBHOOK_URL; then
                echo -e "${RED}FAILED TO SEND MESSAGE TO TEAMS CHANNEL...${R}"
                exit 1
            fi
        else
            echo -e "${RED}There is no teams webhook specified${R}"
        fi
    fi
 
    #Set MAIL parameter to true in pipeline to use mail
    if [[ $MAIL == 'true' ]]; then
        echo -e "${GREEN}ATTEMPTING TO MAKE MAIL${R}"
        construct_mail_html
    fi

    if [[ $SCAN_TYPE = "iac" ]] then
        SUCCESS=$(jq -r '.status.verdict' < iac.json)
        if [[ "$SUCCESS" == "FAILED_BY_POLICY" ]]; then
            #Block pipeline
            exit 1
        fi
    elif [[ $SCAN_TYPE = "docker" ]] then
        SUCCESS=$(jq -r '.status.verdict' < /docker.json)
        if [[ "$SUCCESS" == "FAILED_BY_POLICY" ]]; then
            #Block pipeline
            exit 1
        fi
    fi
}
 
main