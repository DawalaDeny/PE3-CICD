
# Wiz CLI with implemented Microsoft Graph API

This is the project of 2 students applied informatics Vives Kortrijk. It is made for the course practice enterprise 3. The project includes a use for the wiz cli for scanning IAC terraform code and dockers files. The pipe also uses the Microsoft graph API for finding email addresses based on the UUID of the person who commits. As build image, there is an alpine image that includes curl, jq, Wizcli and Terraform placed on the GCP artifact registry of MatecoIT.

## Stage 1: Retrieving Display Name and Email from Microsoft Graph API

#### 1.1. Triggering Pull Request

When a pull request is made, the UUID of the person initiating the request is retrieved using the Bitbucket API. This UUID is stored in an artifact named `name.txt`.

#### 1.2. Retrieving Display Name

From the UUID obtained, the display name of the user is extracted from the Bitbucket API output. This display name is stored for further processing.

#### 1.3. Retrieving Email Address

Using the Microsoft Graph API, the email address associated with the UUID is obtained. The Graph API pipe is utilized for this purpose. For detailed instructions on retrieving email addresses using the Graph API, refer to the documentation within the pipeline itself.

##### Relevant Resources:

-   [Variables and Secrets Documentation](https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/)
-   [Bitbucket API Documentation](https://developer.atlassian.com/server/bitbucket/rest/v818/intro/)
-   [Microsoft Graph API Pipe](https://bitbucket.org/matecocloud/microsoft-graph/src/main/)


## Stage 2: Wiz CLI Docker scan

#### 3.1. Initialization

The Wiz CLI pipe is invoked with specific variables:

-   `WIZ_CLIENT_ID` and `WIZ_CLIENT_SECRET` for authenticating to wiz.io.
-   `SCAN_TYPE`: Defines the type of scan, in this case, IAC for scanning Terraform code.
-   `POLICY`: Specifies the policy defined on wiz.io, where `pe3_misconfigs` is utilized. This policy includes rules for GCP and Terraform.
- `GOOGLE_SERVICE_ACCOUNT_KEY`: The credentials of a service account that has read/write rights to the repository you're trying to push to.
- `TAG`: The tag i.e. `europe-west1-docker.pkg.dev/project/repository/imagename:latest`
-  `MAIL`: Boolean if you want to get mail of person that pushed or not, returns mail in artifact, Default: false.
-  `TEAMS`: Boolean if you want to use teams or not, Default: false.
-  `TEAMS_WEBHOOK_URL`: URL of the Teams channel webhook, must be used with variable TEAMS.

#### 3.2. Scan and Policy Evaluation

The Wiz CLI builds the docker container and authorizes to the docker repository on GCP Artifact Registry. If the image is not compliant to the policy, the pipeline fails.

#### 3.3. Handling Failures

In case of policy failure, the pipeline stops and displays what vulnerabilities the container has. At the time of writing this, the container stops if a minimum of 2 critical vulnerabilities has been found.
#### 3.4. Pushing image

The images pushes automatically to the repository if the policy doesn't fail.
##### Relevant Resources:

-   [Wiz CLI Repository](https://bitbucket.org/matecocloud/wiz-cli/src/main/)

## Stage 3: Wiz CLI IAC scan

#### 2.1. Initialization

The Wiz CLI pipe is invoked with specific variables:

-   `WIZ_CLIENT_ID` and `WIZ_CLIENT_SECRET` for authenticating to wiz.io.
-   `SCAN_TYPE`: Defines the type of scan, in this case, IAC for scanning Terraform code.
-   `POLICY`: Specifies the policy defined on wiz.io, where `pe3_misconfigs` is utilized. This policy includes rules for GCP and Terraform.
-  `SCAN_TYPE`: Type of scan that needs to be done, docker or iac.
-  `GOOGLE_SERVICE_ACCOUNT`: Service account that connects to google artifact registry (for pushing images).
-  `TAG`: Tag name of the image.
-  `MAIL`: Boolean if you want to get mail of person that pushed or not, returns mail in artifact, Default: false.
-  `TEAMS`: Boolean if you want to use teams or not, Default: false.
-  `TEAMS_WEBHOOK_URL`: URL of the Teams channel webhook, must be used with variable TEAMS.

#### 2.2. Scan and Policy Evaluation

The Wiz CLI performs the scan on the Terraform code and evaluates it against the specified policy. If the policy fails, the pipe fails as well.

#### 2.3. Handling Failures

In case of policy failure, an email notification is sent using the `atlassian/email-notify:0.13.1` pipe. The email content is retrieved from the output of the Wiz scan. The sender's email address (FROM) is configured to "mateco-interns@mateco.eu", but it can be changed to anything you want as long as it ends with @mateco.eu.

##### Relevant Resources:

-   [Wiz CLI Repository](https://bitbucket.org/matecocloud/wiz-cli/src/main/)


## Stage 4: Deploying Infrastructure

#### 4.1. Manual Deployment

Upon successful completion of the scan and policy evaluation, there's an option for manual deployment of the Terraform infrastructure. This step ensures that a developer reviews the Terraform plan before proceeding with deployment.

###### Made by: Deny Shabouev, Michiel Blomme

