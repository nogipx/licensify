## 2.0.0 - 2025-04-03
- **BREAKING CHANGE**: Deprecated RSA for all cryptographic operations except key generation
- Improved cryptographic operations with dedicated `ECDHCryptoUtils` class
- Enhanced encryption using `ECCipher` for better security and performance
- Optimized key derivation using industry-standard HKDF implementation
- Refactored license request generation and decryption process
- Added comprehensive documentation on customizing encryption parameters

## 1.7.1 - 2025-03-27
- Update README.md

## 1.7.0 - 2025-03-27
- Removed automatic key type detection to ensure more stable and predictable behavior
- Added new key models: `LicensifyKey`, `LicensifyPrivateKey`, `LicensifyPublicKey`, and `LicensifyKeyPair` for better type safety
- Added `LicensifyKeyType` enum for key types
- Updated examples to reflect new required parameter and key models
- Added ECDSA key generation support as an alternative to RSA
- Added utilities for comparing and choosing between RSA and ECDSA

## 1.6.2 - 2025-03-24
- Update README.md

## 1.6.1 - 2025-03-23
- Fixed validation logic in LicenseSchema for proper error handling
- Improved ValidationResult mechanism for returning validation results
- Fixed license schema validation tests
- Added LicenseSchema support in LicenseValidator
- Added validateLicenseWithSchema method for comprehensive validation

## 1.6.0 - 2025-03-23
- Added license schema validation system
- Support for feature and metadata structure validation
- Validators for different data types (string, number, array, object)
- Custom validation rules (min/max length, patterns, ranges)
- Example for schema validation usage

## 1.5.0 - 2025-03-23
- Removed license monitoring functionality
- Simplified API by removing redundant components and nested directory structure
- Refactored public API for more intuitive usage
- Replaced LicenseFileFormat with LicenseEncoder for better clarity
- Flattened export structure for easier imports
- Added docs/ directory to .pubignore

## 1.4.0 - 2025-03-22
- Remove redutant dependencies

## 1.3.1 - 2025-03-22
- Added pre-commit hook for automatic code formatting
- Configured formatting compatibility with pub.dev requirements (80 characters)
- Automated lint-issues fixing in pre-commit hook

## 1.3.0 - 2025-03-22
- Redesigned storage architecture to be platform-independent
- Removed built-in file and web storage implementations
- Added clear examples for custom storage implementations
- Simplified API by removing platform-specific code
- Now fully compatible with all platforms including WASM

## 1.2.2 - 2025-03-22
- Removed direct dart:io imports for full WASM compatibility
- Added platform-conditional imports for file operations
- Ensured compatibility with both web and native platforms

## 1.2.1 - 2025-03-22
- Refactored JS interop to be fully WASM-compatible using dart:js_interop
- Updated localStorage implementation to use modern WASM-compliant APIs
- Enhanced web platform support with proper WASM compatibility

## 1.2.0 - 2025-03-22
- Custom license types support beyond predefined ones
- WebAssembly (WASM) platform support for web applications
- LocalStorage-based persistence for web platforms
- Replaced enum-based `LicenseType` with a flexible class implementation
- Enhanced error handling in storage implementations
- Streamlined web support focusing only on WASM platform
- Refactored web architecture for better maintainability
- Updated documentation with examples for custom types and WASM

## 1.1.0 - 2025-03-22
- Support for custom license features validation
- Improved license status checking
- Security improvements for signature verification
- Bug fixes in license expiration handling

## 1.0.0 - 2025-03-22
- Initial release with RSA-based license generation and validation
- Multiple storage options (file-based and in-memory)
- Standard license types (trial, standard, pro)
- Customizable license features and metadata
- License expiration management
- License status monitoring capabilities
