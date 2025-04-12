# Licensify CLI Testing

This directory contains tools for testing the Licensify CLI tool. The main test script exercises all major functionalities of the tool, including:

- Client commands
- Server commands
- Key operations
- Complete licensing workflow

## Running Tests

To run all tests:

```bash
cd <project-root>
chmod +x test_cli/test_all_commands.sh
./test_cli/test_all_commands.sh
```

The test script automatically:

1. Creates a test environment in `test_cli/tmp`
2. Generates key pairs for testing
3. Creates license plans
4. Creates, decrypts, and responds to license requests
5. Verifies licenses
6. Imports/exports license plans

## Test Files

After running the tests, the `test_cli/tmp` directory will contain:

- `private.pem`/`public.pem`: Generated cryptographic keys
- `license_plans.json`: Exported license plans
- `license_request.bin`: Sample license request
- `license.licensify`: Generated standard license
- `trial.licensify`: Generated trial license
- `direct_license.licensify`: License generated directly (without request)

## Manual Verification

You can manually examine any of these files using the Licensify CLI, for example:

```bash
# View license details
dart bin/licensify.dart client show --license test_cli/tmp/license.licensify

# View plans
dart bin/licensify.dart server ls --app-id test.app.123
``` 