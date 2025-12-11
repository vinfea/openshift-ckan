#!/bin/bash
echo "[INFO] *********** Starting CA bundle script ***********"

# Writable directory for the CA bundle
LOCAL_CA_DIR="/srv/app/ca-certs"
LOCAL_CA_BUNDLE="${LOCAL_CA_DIR}/ca-bundle.crt"

echo "[INFO] Creating local CA trust store..."

# Try to create directory, warn if it fails
mkdir -p "${LOCAL_CA_DIR}" || echo "[WARN] Failed to create ${LOCAL_CA_DIR}, continuing..."

# Write the env var value to a PEM file if set
if [ -n "${CKAN_CA_CERT:-}" ]; then
    echo "${CKAN_CA_CERT}" > "${LOCAL_CA_DIR}/ckan-dev-ca.pem" || \
        echo "[WARN] Failed to write CA certificate, continuing..."
else
    echo "[WARN] CKAN_CA_CERT env var not set."
fi

# Build the CA bundle, but don’t fail if no files exist
if compgen -G "${LOCAL_CA_DIR}/*.pem" > /dev/null; then
    cat "${LOCAL_CA_DIR}"/*.pem > "${LOCAL_CA_BUNDLE}" || \
        echo "[WARN] Failed to create CA bundle, continuing..."
    echo "[INFO] Local CA bundle created at ${LOCAL_CA_BUNDLE}"
else
    echo "[WARN] No PEM files found, skipping CA bundle creation."
fi

echo "[INFO] UPDATE SSL done..."
