# Microsoft Graph API pipe
Pipe that returns an email address if a display name is given.
Tested with using bitbucket API for getting display name of the person who pushed and then uses Microsoft Graph API to get email from the given display name.

### YAML definition
Add the following snippet to the script section of your `bitbucket-pipelines.yml` file:
```yaml
- pipe: docker://europe-west1-docker.pkg.dev/mateco-interns/pipes/microsoftgraph:latest
   variables:
    CLIENT_ID: '<string>'
    CLIENT_SECRET: '<string>'
    DISPLAYNAME: "John Doe"
```

## Variables

| Variable        | Usage                                                                                                                                               |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| CLIENT_ID (*)| Client ID of the Microsoft Graph service account.                                                                        
| CLIENT_SECRET (*)     | Client secret of the Microsoft Graph service account. 
| DISPLAYNAME(*)     | Display name of the person you want to retrieve an email address from, can be full name or just first name. Full name is best used for getting the right email address.                                                                            
                                                                                                
_(*) = required variable._

## Prerequisites

If you want to use this pipe, you will need a service account on the Microsoft Graph API platform so you can authenticate to the platform. A displayname is required if none is given, the pipe will give an error status.

## Examples

Basic example:
    
```yaml
script:
- pipe: docker://europe-west1-docker.pkg.dev/mateco-interns/pipes/microsoftgraph:latest
  variables:
	client_id: $CLIENT_ID
	client_secret: $CLIENT_SECRET
	DISPLAYNAME: "John Doe"
```
###### Made by: Deny Shabouev & Michiel Blomme

