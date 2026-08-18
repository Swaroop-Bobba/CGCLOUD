# Second-Generation Packaging (2GP) & Fresh Dev Hub Setup Guide

This guide provides step-by-step instructions for setting up a fresh Salesforce Dev Hub, linking namespaces, configuring project settings, and building/releasing 2GP packages for **CGC_AI_Agent** (`VisitIntel`).

---

## 1. Prerequisites & Dev Hub Org Configuration

### Step 1.1: Enable Dev Hub in Salesforce Org
1. Log in to your primary Salesforce Dev Hub org (Developer Edition or Partner Business Org) with System Administrator credentials.
2. In Salesforce Setup, search for **Dev Hub** in the Quick Find box.
3. Turn **ON** the following toggles:
   - **Enable Dev Hub**: `Enabled`
   - **Enable Unlocked Packages and Second-Generation Managed Packages**: `Enabled`

### Step 1.2: Link Namespace Registry (For Managed 2GP)
If your package is a **Managed 2GP** using the namespace `VisitIntel`:
1. In the Dev Hub org, search for **Namespace Registries** in Quick Find.
2. Click **Link Namespace**.
3. Log in using the credentials of the Developer Edition org where the `VisitIntel` namespace is registered.
4. Grant access. The `VisitIntel` namespace will now be associated with this Dev Hub.

*(Note: If you are building an Unlocked 2GP without a namespace, namespace linking is optional).*

---

## 2. Salesforce CLI Authentication

Authenticate your new Dev Hub using Salesforce CLI:

```bash
# Web login to your fresh Dev Hub org
sf org login web --set-default-dev-hub --alias MyDevHub

# Verify connection and Dev Hub capabilities
sf org display --target-org MyDevHub --json
```

To list all authorized orgs and confirm your default Dev Hub:
```bash
sf org list
```

---

## 3. Prepare `sfdx-project.json` for Fresh Dev Hub

When connecting to a brand-new Dev Hub, the previous package IDs (`0Ho...`) and package version IDs (`04t...`) from other orgs will not exist in the new Dev Hub.

Before running `package create`:
- Keep the `packageDirectories` configuration.
- Clear out obsolete `packageAliases` if starting completely fresh, or let the CLI append the new package alias.

Example base [sfdx-project.json](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGC_AI_Agent/sfdx-project.json):
```json
{
  "packageDirectories": [
    {
      "versionName": "ver 0.1",
      "versionNumber": "0.1.0.NEXT",
      "path": "force-app",
      "default": true,
      "package": "CGC_AI_Agent",
      "versionDescription": "",
      "postInstallScript": "PostInstallScript"
    }
  ],
  "name": "CGC_AI_Agent",
  "namespace": "VisitIntel",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "67.0",
  "packageAliases": {}
}
```

---

## 4. Register the 2GP Package on the New Dev Hub

Run the package creation command to create the package container (`0Ho` ID) on your new Dev Hub:

### For Managed 2GP (with `VisitIntel` namespace):
```bash
sf package create --name CGC_AI_Agent --package-type Managed --path force-app --target-dev-hub MyDevHub
```

### For Unlocked 2GP (without namespace):
```bash
sf package create --name CGC_AI_Agent --package-type Unlocked --path force-app --target-dev-hub MyDevHub
```

> **Result:** The CLI will automatically register the `0Ho...` package ID inside your `sfdx-project.json` under `packageAliases`.

---

## 5. Build Scratch Org Definition (`project-scratch-def.json`)

Consumer Goods Cloud and Agentforce require specific platform features enabled in the temporary build scratch org. Ensure [config/project-scratch-def.json](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGC_AI_Agent/config/project-scratch-def.json) includes:

```json
{
  "orgName": "CGC Agent 2GP Build Org",
  "edition": "Developer",
  "features": ["EnableSetPasswordInApi", "RetailExecution", "IndustriesConsumerGoods"],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    }
  }
}
```

---

## 6. Create & Validate a 2GP Package Version

Generate a package version (`04t` ID) with Apex test validation and code coverage:

```bash
sf package version create \
  --package CGC_AI_Agent \
  --definition-file config/project-scratch-def.json \
  --code-coverage \
  --installation-key-bypass \
  --wait 30 \
  --target-dev-hub MyDevHub
```

### Key Flags:
- `--code-coverage`: Validates that Apex tests achieve at least 75% coverage across the package.
- `--installation-key-bypass`: Bypasses password protection (ideal for internal testing / CI/CD).
- `--wait 30`: Keeps the terminal active while the package builds in the cloud.

---

## 7. Test the Package in a Scratch Org or Sandbox

1. **Create a fresh scratch org**:
   ```bash
   sf org create scratch --definition-file config/project-scratch-def.json --alias TestScratchOrg --set-default --duration-days 7
   ```

2. **Install the package version**:
   ```bash
   sf package install --package CGC_AI_Agent@0.1.0-1 --target-org TestScratchOrg --wait 15
   ```

3. **Assign Permission Set**:
   ```bash
   sf org assign permset --name Visit_Intel_Access --target-org TestScratchOrg
   ```

4. **Verify Components**:
   ```bash
   sf org open --target-org TestScratchOrg
   ```

---

## 8. Promote Package Version for Production/Subscriber Use

Once tested and validated, promote the package version to remove beta status:

```bash
sf package version promote --package CGC_AI_Agent@0.1.0-1 --target-dev-hub MyDevHub
```

---

## 9. Troubleshooting & Best Practices

- **Missing Permissions / Dependencies:** Always ensure [Visit_Intel_Access](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGC_AI_Agent/force-app/main/default/permissionsets/Visit_Intel_Access.permissionset-meta.xml) grants access to all Apex classes, custom controllers, and Agentforce actions.
- **Apex Code Coverage:** Run local tests before packaging using:
  ```bash
  sf apex run test --code-coverage --result-format human
  ```
- **Post Install Script:** If your package includes [PostInstallScript](file:///c:/Users/Bhanu%20Bobba/Videos/CGCLOUD/CGC_AI_Agent/force-app/main/default/classes/PostInstallScript.cls), verify that `InstallHandler` methods handle initial org setup cleanly without unhandled exceptions.
