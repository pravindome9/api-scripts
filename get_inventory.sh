#!/bin/bash
# Alex@dome9.com 4/26/17
# pravin@dome9.com 11/12/2018 - updated changes to CSV parsing for AWS

api='false'
aws='false'
azure='false'
gcp='false'
DIRECTORY='/tmp/inventory_reports'

while getopts 'k:azg' flag; do
  case "${flag}" in
    k) api="${OPTARG}" ;;
    a) aws='true' ;;
    z) azure='true' ;;
    g) gcp='true' ;;
    *) echo "Unexpected option" ; exit 1 ;;
  esac
done

if [ "$api" = "false" ] ; then
        echo "Bash script for pulling inventory info from Dome9 API and exporting it as a CSV"
	    echo "Usage: ./get_inventory -k <api_key:api_secret> <clouds>"
	    echo "Ex: ./get_inventory -k asd858:346kjsjbg -a -g"
        echo ""
        echo "Files will be stored in /tmp/inventory_reports/"
        echo " "
        echo "Options:"
        echo "-k        your API ID & secret (ex asb523j:84jsksadgj)"
        echo "-a        run report for AWS instances"
        echo "-z        run report for Azure VMs"
        echo "-g        run report for GCP instances"
	exit 1
fi

if [ ! -d "$DIRECTORY" ]; then
    mkdir $DIRECTORY
fi

if [ "$aws" = true ] ; then
	echo "AssetId, name, region, vpc, cloudAccountId, isRunning, instanceType, publicDnsName, launchTime, platform" > /tmp/inventory_reports/aws_instances.csv
	curl -u $api -X GET 'https://api.dome9.com/v2/CloudInstance/' \
	| jq 'map([.externalId, .name, .region, .vpc, .cloudAccountId, (.isRunning|tostring), .instanceType, .publicDnsName, .launchTime, .platform] | join(", "))' | sed s/\"//g \
	| egrep -v '\[|\]'>> $DIRECTORY/aws_instances.csv
fi

if [ "$azure" = true ] ; then
	echo "cloudAccountId, name, region, resourceGroup, virtualNetworkName, isRunning, operatingSystem, size" > /tmp/inventory_reports/azure_instances.csv
	curl -u $api -X GET 'https://api.dome9.com/v2/azurevirtualmachine/' \
	| jq 'map([.cloudAccountId, .name, .region, .resourceGroup, .virtualNetworkName, (.isRunning|tostring), .operatingSystem, .size] | join(", "))' | sed s/\"//g \
	| egrep -v '\[|\]'>> $DIRECTORY/azure_instances.csv
fi

if [ "$gcp" = true ] ; then
	echo "creationTimestamp, machineType, status, zone, region, isRunning, cloudAccountId, name" > /tmp/inventory_reports/gcp_instances.csv
	curl -u $api -X GET 'https://api.dome9.com/v2/GoogleCloudVMInstance/' \
	| jq 'map([ .creationTimestamp, .machineType, .status, .zone, .region, (.isRunning|tostring), .cloudAccountId, .name] | join(", "))' | sed s/\"//g \
	| egrep -v '\[|\]'>> $DIRECTORY/gcp_instances.csv
fi
