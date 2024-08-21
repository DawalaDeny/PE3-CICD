
# Wiz CLI pipe

Makes a scan of IAC code or a docker image using wiz.io. You can configure the Wiz CLI integration in the pipeline of your repository to get scan results on events such failures on predefined policies.

### YAML definition

Add the following snippet to the script section of your `bitbucket-pipelines.yml` file:

```yaml
- pipe: docker://europe-west1-docker.pkg.dev/mateco-interns/pipes/wizcli:latest
  variables:
    WIZ_CLIENT_ID: '<string>'
    WIZ_CLIENT_SECRET: '<string>'
    POLICY: '<string>'
    SCAN_TYPE: '<string>'
    # JSONFILE: '<string>' # Optional
    # GOOGLE_SERVICE_ACCOUNT: '<string>' # Optional
    # TAG: '<string>' #Optional
    # MAIL: '<boolean>'  # Optional.
    # TEAMS: '<boolean>'  # Optional.
    # TEAMS_WEBHOOK_URL: '<string>' # Optional.
```

## Variables

| Variable           | Usage                                                                                                                |
|--------------------|----------------------------------------------------------------------------------------------------------------------|
| WIZ_CLIENT_ID (*)  | Client ID of Wiz service account.                                                                                    
| WIZ_CLIENT_SECRET (*) | Client secret of Wiz service account.                                                                                
| POLICY (*)         | CI/CD admission policy, use misconfiguration policy with rules based on your needs.  
| SCAN_TYPE (*)         | Can only be `docker` or `iac`. Used for choosing the type of scan.         
| JSONFILE (1)         | The output of terraform plan.                           
|GOOGLE_SERVICE_ACCOUNT (2)| Required when using docker scan. Credentials of a GCP service account so the pipe can push to the repository.
| TAG (2)         | Required when using docker scan. Tag that the image needs to have.                                    
| MAIL               | Boolean if you want to get mail of person that pushed or not, returns mail in artifact, Default: `false`.
| TEAMS              | Boolean if you want to use teams or not, Default: `false`.                                                            
| TEAMS_WEBHOOK_URL | URL of the Teams channel webhook, must be used with variable TEAMS.                                                |

_(*) = required variable._
_(1) = required variable for IAC scan._
_(2) = required variable for docker scan._


## Prerequisites

If you want to use this scan, you must have an authorized service account on Wiz.io with an existing policy. For using Teams, you will need to add an `Incoming Webhook` to the Teams channel you want to post to.


## Examples

Basic example IAC:

```yaml
script:
  - pipe: docker://europe-west1-docker.pkg.dev/mateco-interns/pipes/wizcli:latest
    variables:
      WIZ_CLIENT_ID: $WIZ_CLIENT_ID
      WIZ_CLIENT_SECRET: $WIZ_CLIENT_SECRET
      POLICY: "pe3_misconfigs"
      SCAN_TYPE: "iac"
      JSONFILE: jsonfile.json
```
Basic example Docker:
```yaml
script:
  - pipe: docker://europe-west1-docker.pkg.dev/mateco-interns/pipes/wizcli:latest
    variables:
      WIZ_CLIENT_ID: $WIZ_CLIENT_ID
      WIZ_CLIENT_SECRET: $WIZ_CLIENT_SECRET
      POLICY: "matecoIT_vulnz"
      SCAN_TYPE: "docker"
      GOOGLE_SERVICE_ACCOUNT: $GOOGLE_SERVICE_ACCOUNT
      TAG: "europe-west1-docker.pkg.dev/project/repository/imagename:latest"
```
IAC scan with teams and mail
```yaml
script:
  - pipe: docker://europe-west1-docker.pkg.dev/mateco-interns/pipes/wizcli:latest
    variables:
      WIZ_CLIENT_ID: $WIZ_CLIENT_ID
      WIZ_CLIENT_SECRET: $WIZ_CLIENT_SECRET
      POLICY: "pe3_misconfigs"
      SCAN_TYPE: "iac"
      JSONFILE: jsonfile.json
      MAIL: 'true'
      TEAMS: 'true'
      TEAMS_WEBHOOK_URL: "https://matecocloud.webhook.office.com/webhookb2/abcd1234..."
```
Docker scan with teams and mail
```yaml
script:
  - pipe: docker://europe-west1-docker.pkg.dev/mateco-interns/pipes/wizcli:latest
    variables:
      WIZ_CLIENT_ID: $WIZ_CLIENT_ID
      WIZ_CLIENT_SECRET: $WIZ_CLIENT_SECRET
      POLICY: "matecoIT_vulnz"
      SCAN_TYPE: "docker"
      GOOGLE_SERVICE_ACCOUNT: $GOOGLE_SERVICE_ACCOUNT
      TAG: "europe-west1-docker.pkg.dev/project/repository/imagename:latest"
      MAIL: 'true'
      TEAMS: 'true'
      TEAMS_WEBHOOK_URL: "https://matecocloud.webhook.office.com/webhookb2/abcd1234..."
```
###### Made by: Deny Shabouev & Michiel Blomme
