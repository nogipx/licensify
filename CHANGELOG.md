# Changelog

All notable changes to the Licensify package will be documented in this file.

## 1.2.0 - 2024-03-22

### Added
- Custom license types support beyond predefined ones
- WebAssembly (WASM) platform support for web applications
- LocalStorage-based persistence for web platforms

### Improved
- Replaced enum-based `LicenseType` with a flexible class implementation
- Enhanced error handling in storage implementations
- Streamlined web support focusing only on WASM platform
- Refactored web architecture for better maintainability
- Updated documentation with examples for custom types and WASM

## 1.1.0 - 2024-02-28

### Added
- Support for custom license features validation
- Improved license status checking

### Fixed
- Security improvements for signature verification
- Bug fixes in license expiration handling

## 1.0.0 - 2024-02-15

### Added
- Initial release with RSA-based license generation and validation
- Multiple storage options (file-based and in-memory)
- Standard license types (trial, standard, pro)
- Customizable license features and metadata
- License expiration management
- License status monitoring capabilities
