# OpenCart Extension Creation Script

This script automates the creation of extensions for OpenCart, specifically targeting the creation of controllers, models, languages, views, and OCMOD files.

## Usage

### Prerequisites

Ensure you have the following prerequisites installed:

- **Composer**: Required for installing PHP libraries.
- **OpenCart**: Ensure OpenCart is installed and configured properly.

### Commands

1. **Create Extension**:
   ```bash
   ./vendor/bin/opencart.sh create-extension <type> <name> [-c]
   ```
   - `<type>`: Type of the extension (e.g., module, payment, shipping).
   - `<name>`: Name of the extension (e.g., my_extension_name).
   - `[-c]`: Optional flag to create catalog-side files.

2. **Install Validation Library**:
   ```bash
   ./vendor/bin/opencart.sh install-validation-library
   ```
   - Installs Code Corner's validation library via Composer.

3. **Create Library**:
   ```bash
   ./vendor/bin/opencart.sh create-library <name>
   ```
   - `<name>`: Name of the library to create.

4. **Create Model**:
   ```bash
   ./vendor/bin/opencart.sh create-model <path> <name>
   ```
   - `<path>`: Path to store the model (e.g., extension/payment).
   - `<name>`: Name of the model to create.

5. **Create Controller**:
   ```bash
   ./vendor/bin/opencart.sh create-controller <path> <name>
   ```
   - `<path>`: Path to store the controller (e.g., extension/payment).
   - `<name>`: Name of the controller to create.

6. **Create Language File**:
   ```bash
   ./vendor/bin/opencart.sh create-language <path> <name>
   ```
   - `<path>`: Path to store the language file (e.g., extension/payment).
   - `<name>`: Name of the language file to create.

7. **Create View Template**:
   ```bash
   ./vendor/bin/opencart.sh create-template <path> <name>
   ```
   - `<path>`: Path to store the template (e.g., extension/payment).
   - `<name>`: Name of the template to create.

8. **Create OCMOD XML File**:
   ```bash
   ./vendor/bin/opencart.sh create-ocmod <name> [-z]
   ```
   - `<name>`: Name of the OCMOD XML file.
   - `[-z]`: Optional flag to create a zip file.

### Notes

- Always ensure paths and names are specified correctly to avoid errors.
- Modify the script as per your specific requirements and file structure.
- Ensure proper permissions are set for script execution (`chmod +x opencart.sh`).

---

This README provides a structured overview of how to use the script and its various functionalities. Adjust the content based on your specific script's features and usage guidelines.