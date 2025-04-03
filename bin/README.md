# Licensify CLI

Command-line tool for managing licenses using the Licensify library.

## Installation

The Licensify CLI is installed with the Licensify package. To use it:

```bash
dart pub global activate licensify
```

After activating the package, you can use the `licensify` command directly from the terminal.

## Usage

```bash
licensify <command> [options]
```

### Available Commands

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

### Verifying a License

```bash
licensify verify [options]
```

Required options:
- `--license, -l`: Path to the license file
- `--publicKey, -k`: Path to the public key file

Additional options:
- `--decryptKey`: Key for decryption (if the license was encrypted)

Example:
```bash
licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem
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

Example:
```bash
licensify decrypt-request --requestFile request.bin --privateKey ./keys/customer1.private.pem
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

## Notes

- The private key should be stored in a secure location and used only for license creation.
- The public key is included in your application for license verification.
- All dates should be in ISO format (YYYY-MM-DD).
- For production scenarios, it's recommended to use p384 or p521 curves for a higher level of security.
- License requests contain a device hash, which allows binding licenses to specific devices.
- License requests are encrypted using the public key and can only be decrypted with the corresponding private key. 