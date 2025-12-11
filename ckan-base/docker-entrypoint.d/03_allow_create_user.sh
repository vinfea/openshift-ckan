#!/bin/bash

set -e

INI_FILE="/srv/app/ckan.ini"

# Ensure the file exists
if [ ! -f "$INI_FILE" ]; then
  echo "Error: $INI_FILE not found!"
  exit 1
fi

# Update or append the settings
grep -q "^ckan.auth.create_user_via_api" "$INI_FILE" \
  && sed -i 's/^ckan.auth.create_user_via_api.*/ckan.auth.create_user_via_api = true/' "$INI_FILE" \
  || echo "ckan.auth.create_user_via_api = true" >> "$INI_FILE"

grep -q "^ckan.auth.create_user_via_web" "$INI_FILE" \
  && sed -i 's/^ckan.auth.create_user_via_web.*/ckan.auth.create_user_via_web = true/' "$INI_FILE" \
  || echo "ckan.auth.create_user_via_web = true" >> "$INI_FILE"

echo "Updated CKAN user creation settings in $INI_FILE"
