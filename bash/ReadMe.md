# Synchronize in-memory objects over multiple instances in IBM CLOUD Cloud Foundry Apps using Bash script

## Prerequisites
* [Bluemix account](https://console.ng.bluemix.net/registration/)
* [Cloud Foundry CLI](https://github.com/cloudfoundry/cli#downloads)
----
## Installation
1. Install IBM Cloud CLI on your machine. Follow the instructions from here - [Getting started with the IBM Cloud CLI](https://console.bluemix.net/docs/cli/reference/bluemix_cli/get_started.html)

2. Follow the instructions from here - [Creating an API key](https://console.bluemix.net/docs/iam/userid_keys.html#userapikey )(Optional)
----
## Usage
### With APIKEY:
```
sh refreshCache.sh -o=MyOrg -s=dev -a=Python-Refresh-Cache-Multiple-Instances -p=YOUR_API_KEY -d=True
```

### With Bluemix ID: 
Note: The user will be prompted interactively for the SSO token.
```
sh refreshCache.sh -o=MyOrg -s=dev -a=Python-Refresh-Cache-Multiple-Instances -u=xyz@pqr.com -d=True
```

## Script parameters description 
```
    -o
        Name of the organization
    -s
        Name of the space/environment within the organization
    -a
        Name of the CF application deployed on IBM Cloud(Bluemix)
    -p
        Your API KEY
    -u
        Your Bluemix/IBM ID
    -d
        Debug True/False
```
