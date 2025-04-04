# Licensify CLI

CLI tool for managing licenses directly from the command line.

## Installation

Global activation:

```bash
dart pub global activate licensify
```

Or use directly from a repository clone:

```bash
dart run bin/licensify.dart <command> [options]
```

## General Help

To get general help on commands, use:

```bash
licensify --help
```

This will display a list of available commands and general options.

## Command-specific Help

To get detailed help on any command, use:

```bash
licensify <command> --help
```

For example:

```bash
licensify generate --help
```

This will display a detailed description of the command, all available options, and usage examples.

## Available Commands

Licensify CLI supports the following commands:

- `keygen`: Generate an ECDSA key pair
- `generate`: Create and sign a new license
- `verify`: Verify an existing license
- `request`: Create a license request (client-side)
- `decrypt-request`: Decrypt and view a license request (server-side)
- `respond`: Process a license request and generate a license (server-side)

### Generating Keys

```bash
licensify keygen [options]
```

Options:
- `--output, -o`: Path to the directory for saving keys (default: './keys')
- `--name, -n`: Base name for key files (default: 'ecdsa')
- `--curve`: ECDSA curve to use (p256, p384, p521) (default: 'p256')

Example:
```bash
licensify keygen --output ./keys --name customer1
```

### Creating a License

```bash
licensify generate [options]
```

Required options:
- `--privateKey, -k`: Path to the private key file
- `--appId`: Application ID for this license
- `--expiration`: License expiration date (YYYY-MM-DD)

Additional options:
- `--output, -o`: Path to save the license file (default: 'license.licensify')
- `--id`: License ID (UUID). If not specified, it will be generated automatically
- `--type`: License type (trial, standard, pro) (default: 'standard')
- `--features, -f`: License features in key=value format (can specify multiple)
- `--metadata, -m`: License metadata in key=value format (can specify multiple)
- `--encrypt`: Encrypt the license file (default: false)
- `--encryptKey`: Key for encryption

Example:
```bash
licensify generate --privateKey ./keys/customer1.private.pem --appId com.example.app --expiration 2025-01-01 --output license.licensify --features maxUsers=10 --features premium=true --metadata customer=ACME
```

#### Working with Multiple Features and Metadata

When creating licenses, you often need to include multiple features and metadata fields. Each field requires a separate flag:

```bash
# Adding multiple features
licensify generate --privateKey ./keys/customer1.private.pem \
  --appId com.example.app \
  --expiration 2025-01-01 \
  --type pro \
  --features maxUsers=50 \
  --features premium=true \
  --features modules=analytics:reporting:export \
  --features exportFormats=pdf:csv:xls \
  --output license.licensify
```

Features can have various data types:
- Boolean values: `--features premium=true`
- Numeric values: `--features maxUsers=50`
- String values: `--features customerTier=enterprise`
- String values with spaces: `--features "customerName=John Doe"` (note the quotes)

> **Important**: When using the CLI, avoid using commas in feature values, as they may be incorrectly parsed as separate arguments. If you need to represent lists, consider:
> - Using an alternative separator: `--features modules=analytics:reporting:export`
> - Storing complex data in JSON format: `--features "config={"option1":"value1","option2":"value2"}"`
> - Or use a single value per feature: `--features module1=analytics --features module2=reporting`

Similarly, you can include multiple metadata fields:

```bash
# Adding multiple metadata fields
licensify generate --privateKey ./keys/customer1.private.pem \
  --appId com.example.app \
  --expiration 2025-01-01 \
  --metadata customerName="ACME Corporation" \
  --metadata orderId=ORD-12345 \
  --metadata purchaseDate=2024-07-01 \
  --metadata contactEmail=support@acme.com \
  --output license.licensify
```

You can combine multiple features and metadata in a single command:

```bash
# Complete example with multiple features and metadata
licensify generate --privateKey ./keys/customer1.private.pem \
  --appId com.example.app \
  --expiration 2025-01-01 \
  --type enterprise.premium \
  --features maxUsers=100 \
  --features premium=true \
  --features modules=analytics:reporting:export:admin \
  --metadata "customerName=ACME Corporation" \
  --metadata orderId=ORD-12345 \
  --metadata region=EMEA \
  --output license.licensify
```

### License Type Customization

Licensify supports both predefined (trial, standard, pro) and custom license types. Custom license types can be specified using the `--type` parameter when generating licenses.

Custom license type requirements:
- Must be 2-100 characters long
- May contain only latin letters, numbers, and symbols -_.@
- Will be automatically converted to lowercase

Example with custom license type:
```bash
licensify generate --privateKey ./keys/customer1.private.pem --appId com.example.app --expiration 2025-01-01 --type enterprise.premium --output license.licensify
```

### Field Validation

Licensify CLI validates key fields to ensure consistency:

**AppId validation requirements:**
- Must be 3-100 characters long
- May contain only latin letters, numbers, and symbols -_.
- Typically follows reverse domain format (e.g., com.example.app)

**License Type validation requirements:**
- Must be 2-100 characters long
- May contain only latin letters, numbers, and symbols -_.@

### Verifying a License

```bash
licensify verify [options]
```

Required options:
- `--license, -l`: Path to the license file
- `--publicKey, -k`: Path to the public key file

Additional options:
- `--decryptKey`: Key for decryption (if the license was encrypted)
- `--outputJson, -o`: Save verification results to a JSON file at the specified path

Example:
```bash
licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem
```

With JSON output:
```bash
licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem --outputJson results.json
```

### Creating a License Request

```bash
licensify request [options]
```

Required options:
- `--appId`: Application ID for this license request
- `--publicKey, -k`: Path to the public key file (from license issuer)

Additional options:
- `--output, -o`: Path to save the license request file (default: 'license_request.bin')
- `--deviceId`: Device identifier (will be hashed, random if not provided)
- `--validHours`: Request validity period in hours (default: '48')

Example:
```bash
licensify request --appId com.example.app --publicKey ./keys/customer1.public.pem --output request.bin
```

### Decrypting a License Request

```bash
licensify decrypt-request [options]
```

Required options:
- `--requestFile, -r`: Path to the license request file
- `--privateKey, -k`: Path to the private key file

Additional options:
- `--outputJson, -o`: Save request details to a JSON file at the specified path

Example:
```bash
licensify decrypt-request --requestFile request.bin --privateKey ./keys/customer1.private.pem
```

With JSON output:
```bash
licensify decrypt-request --requestFile request.bin --privateKey ./keys/customer1.private.pem --outputJson request-info.json
```

### Responding to a License Request

```bash
licensify respond [options]
```

Required options:
- `--requestFile, -r`: Path to the license request file
- `--privateKey, -k`: Path to the private key file
- `--expiration`: License expiration date (YYYY-MM-DD)

Additional options:
- `--output, -o`: Path to save the license file (default: 'license.licensify')
- `--type`: License type (trial, standard, pro) (default: 'standard')
- `--features, -f`: License features in key=value format (can specify multiple)
- `--metadata, -m`: Additional license metadata in key=value format (can specify multiple)
- `--encrypt`: Encrypt the license file (default: false)
- `--encryptKey`: Key for encryption

Example:
```bash
licensify respond --requestFile request.bin --privateKey ./keys/customer1.private.pem --expiration 2025-01-01 --type pro --features maxUsers=100
```

Custom license types are also supported with the `respond` command:

```bash
licensify respond --requestFile request.bin --privateKey ./keys/customer1.private.pem --expiration 2025-01-01 --type business.plus --features maxUsers=250
```

The same principles for specifying multiple features and metadata apply to the `respond` command:

```bash
# Responding to request with multiple features and metadata
licensify respond --requestFile request.bin \
  --privateKey ./keys/customer1.private.pem \
  --expiration 2025-01-01 \
  --type business.enterprise \
  --features maxUsers=200 \
  --features premium=true \
  --features modules=analytics:reporting:admin \
  --features supportTier=priority \
  --metadata "customerName=Client Corporation" \
  --metadata region=APAC \
  --metadata "salesAgent=John Doe" \
  --output client-license.licensify
```

Note that when responding to a license request, the device hash is automatically included in the metadata.

## Workflow Examples

### Complete License Creation and Verification Process

```bash
# 1. Generate a key pair
licensify keygen --output ./keys --name customer1

# 2. Create a license
licensify generate --privateKey ./keys/customer1.private.pem --appId com.example.app --expiration 2025-01-01 --features maxUsers=10 --output license.licensify

# 3. Verify the license
licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem
```

### License Request Workflow

```bash
# 1. Generate a key pair (done by license issuer)
licensify keygen --output ./keys --name customer1

# 2. Create a license request (done by client)
licensify request --appId com.example.app --publicKey ./keys/customer1.public.pem --output request.bin

# 3. View the license request details (optional, done by license issuer)
licensify decrypt-request --requestFile request.bin --privateKey ./keys/customer1.private.pem

# 4. Process the license request and generate a license (done by license issuer)
licensify respond --requestFile request.bin --privateKey ./keys/customer1.private.pem --expiration 2025-01-01 --type pro --features maxUsers=100 --output license.licensify

# 5. Verify the generated license (done by client)
licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem
```

### Output to JSON Examples

```bash
# Verify a license and save results to JSON
licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem --outputJson verification.json

# Decrypt a license request and save details to JSON
licensify decrypt-request --requestFile request.bin --privateKey ./keys/customer1.private.pem --outputJson request-details.json
```

## Notes

- The private key should be stored in a secure location and used only for license creation.
- The public key is included in your application for license verification.
- All dates should be in ISO format (YYYY-MM-DD).
- For production scenarios, it's recommended to use p384 or p521 curves for a higher level of security.
- License requests contain a device hash, which allows binding licenses to specific devices.
- License requests are encrypted using the public key and can only be decrypted with the corresponding private key.
- JSON output files can be used for integration with other systems or for automated processing.

## CLI Tips

### Working with Complex Values

When using the CLI, consider these tips for the best experience:

1. **Quoting values with spaces**
   Use quotes around values that contain spaces:
   ```bash
   --metadata "customerName=ACME Corporation"
   ```

2. **Avoid commas in values**
   The CLI may interpret commas as argument separators. Instead:
   - Use colon as an alternative separator: `--features modules=analytics:reporting:export`
   - Use separate flags for each item: `--features module1=analytics --features module2=reporting`

3. **All values are stored as strings**
   The CLI stores all feature and metadata values as strings. Your application should handle type conversion as needed.

4. **Using shell variables**
   You can use shell variables to make complex commands more readable:
   ```bash
   KEY_PATH="./keys/customer1.private.pem"
   APP_ID="com.example.app"
   licensify generate --privateKey $KEY_PATH --appId $APP_ID --expiration 2025-01-01
   ```

5. **Escaping special characters**
   If you need to include special characters like quotes within values, you'll need to escape them according to your shell's rules. 