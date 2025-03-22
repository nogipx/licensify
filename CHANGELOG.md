# Changelog

All notable changes to the Licensify package will be documented in this file.

## 1.3.0 - 2024-07-30

### Changed
- Redesigned storage architecture to be platform-independent
- Removed built-in file and web storage implementations
- Added clear examples for custom storage implementations
- Simplified API by removing platform-specific code
- Now fully compatible with all platforms including WASM

## 1.2.2 - 2024-07-29

### Fixed
- Removed direct dart:io imports for full WASM compatibility
- Added platform-conditional imports for file operations
- Ensured compatibility with both web and native platforms

## 1.2.1 - 2024-07-29

### Improved
- Refactored JS interop to be fully WASM-compatible using dart:js_interop
- Updated localStorage implementation to use modern WASM-compliant APIs
- Enhanced web platform support with proper WASM compatibility

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
