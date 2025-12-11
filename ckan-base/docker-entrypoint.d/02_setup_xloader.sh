#!/bin/bash

echo "************************SETUP XLOADER FILE************************"
echo "CKAN_INI = $CKAN_INI"
echo "CKAN__PLUGINS = $CKAN__PLUGINS"
echo "CKAN__XLOADER__API_TOKEN = ${CKAN__XLOADER__API_TOKEN:-<not set>}"
echo "---------------------------------------------------------------"

if [[ $CKAN__PLUGINS == *"xloader"* ]]; then
   # Datapusher settings have been configured in the .env file
   # Set API token if necessary
   if [ -z "$CKAN__XLOADER__API_TOKEN" ] ; then
      echo "No API token provided; generating a new one..."
      echo "Set up ckanext.xloader.api_token in the CKAN config file"
      ckan config-tool $CKAN_INI "ckanext.xloader.api_token=$(ckan -c $CKAN_INI user token add ckan_admin xloader | tail -n 1 | tr -d '\t')"
   else
      echo "API token already provided: ${CKAN__XLOADER__API_TOKEN:0:6}******"
   fi
else
   echo "Not configuring xloader"
fi

echo "---------------------------------------------------------------"
echo "[INFO] Checking CKAN_SQLALCHEMY_URL for jobs_db.uri configuration..."
echo "[INFO] CKAN_SQLALCHEMY_URL = ${CKAN_SQLALCHEMY_URL:-<not set>}"

if [[ -z "${CKAN_SQLALCHEMY_URL:-}" ]]; then
   echo "[ERROR] CKAN_SQLALCHEMY_URL is not set! Cannot configure jobs_db.uri."
   exit 1
else
   echo "[INFO] Setting ckanext.xloader.jobs_db.uri in CKAN config..."
   ckan config-tool "$CKAN_INI" "ckanext.xloader.jobs_db.uri=${CKAN_SQLALCHEMY_URL}"
   echo "[INFO] Successfully updated ckanext.xloader.jobs_db.uri in $CKAN_INI"
fi
echo "************************SETUP COMPLETE************************"
