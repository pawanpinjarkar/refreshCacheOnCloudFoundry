#!/bin/bash
# @author Pawan Pinjarkar
#

# Clear the terminal screen
clear;

usage () {
	cat <<USAGE

NAME
    $(basename $0) - Refresh the cache on multiple instances of the specified CF application on IBM Cloud (Bluemix). Synchronize in-memory objects over multiple instances of Cloud Foundary Apps in IBM Cloud.

SYNOPSIS
    $(basename $0) -o= -s= -a= -p= -d=      OR      $(basename $0) -o= -s= -a= -u= -d=

ARGUMENTS
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

USAGE
}

ibmcloud config --check-version=false

echo "---------------------------------------------------------------------------------------------"
echo "Synchronize in-memory objects over multiple instances of Cloud Foundary Apps in IBM Cloud."
echo "---------------------------------------------------------------------------------------------"

# Initialize flags
DEBUG=false
EMAIL_PRESENT=0
APIKEY_PRESENT=0

shopt -s nocasematch

# Check for number of parameters
if [ $# -eq 0 ]
  then
    echo "ERROR: No parameters supplied."
    echo "Goodbye!"
    usage >&2
    exit 1
fi

# Read command line parameters
for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d= )
    VALUE=$(echo $ARGUMENT | cut -f2 -d= )   

    case "$KEY" in
            -u)     
                USER_EMAIL=${VALUE}
                EMAIL_PRESENT=1;;
            -o)     ORGANIZATION=${VALUE} ;;
            -a)     APPNAME=${VALUE} ;;
            -s)     SPACE=${VALUE} ;;
            -p)     
                APIKEY=${VALUE}
                APIKEY_PRESENT=1;;
            -d)
                DEBUG=$(echo ${VALUE} | awk '{print toupper($0)}')
                if [ $DEBUG == "TRUE" ]; then
                    echo "INFO: Debug mode is on."
                fi
                if [ "$DEBUG" != "TRUE" ] && [ "$DEBUG" != "FALSE" ]; then
                    echo "ERROR: Incorrect value for debug flag."
                    echo "Goodbye!"
                    usage >&2
                    exit 1
                fi;;
            *)   
                echo "ERROR: Invalid parameters supplied."
                echo "Goodbye!"
                usage >&2
                exit 1;;
    esac    
done

# Check if required parameters are provided
if [ "$ORGANIZATION" == "" ] || [ "$SPACE" == "" ] || [ "$APPNAME" == "" ]; then
    echo "ERROR: Organization, space and app name are required parameters."
    echo "Goodbye!"
    usage >&2
    exit 1
fi

# Check if Bluemix id and APIKEY both are provided
if [ $EMAIL_PRESENT -eq 1 ] && [ $APIKEY_PRESENT -eq 1 ]; then
        echo "ERROR: Bluemix id and APIKEY both were provied. Please provide any one of them."
        echo "Goodbye!"
        usage >&2
        exit 1
fi

# Check if neither Bluemix id nor APIKEY provided.
if [ $EMAIL_PRESENT -eq 0 ] && [ $APIKEY_PRESENT -eq 0 ]; then
        echo "ERROR: Bluemix id or APIKEY was not provied. Please provide any one of them."
        echo "Goodbye!"
        usage >&2
        exit 1
fi

# Print provided parameters
echo "Organization = $ORGANIZATION"
echo "Space = $SPACE"
echo "App name = $APPNAME"
if [ $EMAIL_PRESENT -eq 1 ]; then
    echo "Bluemix ID = $USER_EMAIL"
fi
# Print APIKEY with * 
COUNTER=${#APIKEY}
ENCODED_APIKEY=${APIKEY:0:5}

while [  $COUNTER -gt 5 ]; do
 ENCODED_APIKEY+="*"
 COUNTER=COUNTER-1 
done
if [ $APIKEY_PRESENT -eq 1 ]; then 
    echo "APIKEY = $ENCODED_APIKEY"
fi

if [ $EMAIL_PRESENT -eq 1 ];then
    if [[ "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
        if [ "$DEBUG" = "TRUE" ] ; then 
            echo "INFO: Bluemix ID (Email address) $USER_EMAIL is valid."
        fi
    else
        echo "ERROR: Bluemix ID (Email address) $USER_EMAIL is invalid."
        echo "Goodbye!"
        exit 1;
    fi
fi

# Public IBM Cloud URL
BLUEMIX_URL='https://api.ng.bluemix.net'
INSTANCES=-1
ROUTE='https://python-refresh-cache-multiple-instances-forgiving-rhinocerous.mybluemix.net'

# ibmcloud login with bluemix id and SSO token
if [ $EMAIL_PRESENT -eq 1 ]; then
      ibmcloud login -a "$BLUEMIX_URL" -o "$ORGANIZATION" -s $SPACE -u $USER_EMAIL --sso
fi
# ibmcloud login with APIKEY
if [ $APIKEY_PRESENT -eq 1 ]; then
      ibmcloud login -a "$BLUEMIX_URL" -o "$ORGANIZATION" -s $SPACE -u "apikey" --apikey $APIKEY
fi

if [ "$DEBUG" = "TRUE" ] ; then
    echo "INFO: Below are the CF apps available for you: "
    eval $"ibmcloud app list"
    echo "INFO: Retrieving the GUID of your app..."
fi

guid=$(eval $"ibmcloud cf app $APPNAME --guid")
guid=($guid)
guid=${guid[5]}
echo "GUID is = $guid"

# Configure the number of your app instances. In this example, the app has 3 instances hence 
# here the while loop iterates upto 2 (app instance are based onindex starting from 0)
while [ $INSTANCES -lt 2 ]; do
    let INSTANCES=INSTANCES+1 
    echo "INFO: Synchronizing in-memory objects over instance number $INSTANCES of $APPNAME Cloud Foundary App in IBM Cloud. ..."
    echo ""
    HTTP_STATUS=$(curl -LI $ROUTE/api/v1/refresh -H "X-CF-APP-INSTANCE":"$guid:$INSTANCES" -o /dev/null -w '%{http_code}' -s );
    if [[ "$HTTP_STATUS" == "200" ]]; then
        echo " Success: Synchronized in-memory objects on app instance $INSTANCES."
        sleep 2
    else
        echo " Error: In-memory objects were not successfully synchronized on app instance $INSTANCES. Reason - HTTP Status Code: $HTTP_STATUS"
        sleep 2
    fi
    echo ""
done
