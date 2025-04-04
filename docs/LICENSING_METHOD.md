# Licensing Process

## Overview

This document describes the application licensing process based on cryptographic protection using asymmetric encryption and device binding. This approach provides reliable protection against unauthorized use while maintaining convenience for the end user.

## Workflow

### 1. License Request Generation

1. The user initiates the license acquisition process in the application
2. The application collects device data hash, which includes:
   - Device identifier (Android ID for Android, IDFV for iOS)
   - Device model
   - Device name
   - MAC address (if available)
3. The application creates a [license request JSON](#license-request-format)
   - Device data hash
   - Application identifier
   - Request creation date and time in ISO 8601 format (e.g., "2024-07-25T14:30:00Z")
   - Request expiration date and time in ISO 8601 format (typically +48 hours)
5. The resulting JSON is encrypted using a public key
6. The encrypted JSON is converted to bytes and saved to a license request file
7. The application opens a "Share" dialog to send the request file

### 2. Request Processing and License Issuance

1. The user sends the license request file to the backend (via Telegram bot or other channel)
2. The backend decrypts the request using the private key
3. The backend checks the request expiration date and rejects outdated requests
4. The backend extracts and saves the user's device data
5. The backend creates a [license file](#license-file-format)
6. The backend signs the license with the private key
7. The signed license file is sent to the user

### 3. License Activation

1. The user imports the license file into the application
2. The application reads the license file and decrypts the signature to obtain the data hash
3. The licensify package hashes the license data and compares it with the hash obtained from the signature
4. If the hashes match, the application collects current device data and generates a new hash
   - If the hashes don't match, the application reports that the license is invalid
5. The application compares the obtained device hash with the hash in the license metadata
   - If the hashes match, the license is activated and saved in secure storage
   - If the hashes don't match, the application reports that the license is activated on another device

### 4. License Verification at Startup

1. At each startup, the application checks:
   - License signature validity
   - Device identifier match
   - License expiration date (if applicable)
2. If any of the checks fail, the application restricts functionality

## Technical Details

### License File Format

The license file is a JSON containing the following fields:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "appId": "com.moniplan.app",
  "createdAt": "2024-07-25T14:30:00Z",
  "expirationDate": "2025-07-25T14:30:00Z",
  "type": "standard",
  "features": {
    "monisyncBackupPassword": false,
    "monisyncExportData": false,
    "analyticsInsights": false,
    "plannerAllowMany": false
  },
  "metadata": {
    "deviceHash": "Base64EncodedSignature...",
    "userHash": "Base64EncodedSignature..."
  },
  "signature": "Base64EncodedSignature..."
}
```

### License Request Format

The license request is an encrypted data string that, once decrypted, has the following JSON format:
```json
{
  "deviceHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "appId": "com.moniplan.app",
  "createdAt": "2024-07-25T14:30:00Z",
  "expiresAt": "2024-07-27T14:30:00Z",
}
```

This JSON object is encrypted with a public key and transferred as a file with the extension `.mlr` (MoniPlan License Request).

### Cryptography

- For asymmetric cryptography, ECDSA algorithm with a 256-521 bit key is used (P-256, P-384, P-521, secp256k1)
- SHA-512 is used for hashing
- flutter_secure_storage is used for secure storage on the device

## Approach Benefits

1. **Offline Operation**: internet connection is not required after license activation
2. **Resale Protection**: each license is bound to a specific device
3. **Activation Control**: all activations go through the backend, allowing for suspicious activity tracking
4. **Reliability**: even with access to the application source code, generating valid licenses is impossible without the private key
5. **User Convenience**: the activation process is simple and straightforward

### License Types

The `type` field can contain either predefined values (`standard`, `trial`, `pro`) or custom license types depending on your business needs. Custom types follow these rules:
- Must be 2-100 characters long
- May contain only latin letters, numbers, and symbols -_.@
- Will be automatically converted to lowercase

Examples of custom license types:
- `enterprise.premium`
- `business.2024`
- `dev-preview`
- `beta_tester`

### Application ID Validation

The `appId` field must follow these requirements:
- Must be 3-100 characters long
- May contain only latin letters, numbers, and symbols -_.
- Typically follows reverse domain format (e.g., com.example.app)

This validation ensures consistency across all licenses and helps prevent errors during license generation.

### Working with Features and Metadata

#### Features

The `features` field in a license contains functionality flags and settings for the application. Features can store values of different types:

```json
"features": {
  "maxUsers": 50,
  "premium": true,
  "modules": "analytics,reporting,export",
  "expirationWarningDays": 14,
  "allowBackup": false
}
```

When creating licenses through the CLI, each feature requires a separate flag:

```bash
licensify generate ... \
  --features maxUsers=50 \
  --features premium=true \
  --features modules=analytics:reporting:export
```

**CLI Value Format Tips:**
- For string values with spaces, use quotes: `--features "description=Some text"`
- For numeric values: `--features maxUsers=50`
- For boolean values: `--features premium=true`
- For list values, use colon as separator: `--features modules=analytics:reporting:export`
- Avoid commas in CLI values as they may cause parsing issues

**In Code vs. CLI:**
Note that while in your code you can use any format for feature values (including commas, JSON objects, etc.), the CLI has some limitations due to command-line argument parsing. The CLI stores all values as strings, so any type conversion needs to be handled in your application code.

#### Metadata

The `metadata` field stores additional information about the license that doesn't directly control functionality:

```json
"metadata": {
  "customerName": "ACME Corporation",
  "orderId": "ORD-12345",
  "deviceHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "purchaseDate": "2024-07-01",
  "notes": "Enterprise customer with priority support"
}
```

Similar to features, each metadata field requires a separate flag when using the CLI:

```bash
licensify generate ... \
  --metadata "customerName=ACME Corporation" \
  --metadata orderId=ORD-12345 \
  --metadata purchaseDate=2024-07-01
```

When generating a license from a request, the `deviceHash` is automatically included in the metadata, binding the license to a specific device.