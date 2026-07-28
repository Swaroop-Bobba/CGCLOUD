# Custom Inputs and Lightning Types in Agentforce

## 1. Overview
Agentforce actions by default use plain-text inputs. To override the chat UI with rich inputs (like picklists, date-time pickers, or custom forms), you can build Custom Lightning Web Components (LWCs) and register them as **Custom Lightning Types** (CLTs).

---

## 2. Technical Architecture & File Directory Setup

To map a parameter to a custom input component:
1. Declare the action parameter in your `.agent` script as an `object` with `complex_data_type_name` pointing to your Custom Lightning Type (e.g. `c__myCustomInputType`).
2. Create a folder in `force-app/main/default/lightningTypes/myCustomInputType/`.
3. Create `schema.json` mapping to a global Apex class wrapper.
4. Create `lightningDesktopGenAi/editor.json` to bind the Custom Lightning Type to your LWC component definition.
5. In the LWC metadata `js-meta.xml`, expose the target `lightning__AgentforceInput` and set `<targetType>` to your CLT name.

---

## 3. Reference Implementation Code Templates

### A. Apex Wrapper Class
Agentforce complex types require global outer classes. Inner classes are not supported.

```apex
global class CustomInputWrapper {
    @AuraEnabled
    @InvocableVariable(required=true description='Selected value from custom input UI.')
    global String inputValue;
    
    global CustomInputWrapper() {}
}
```

### B. Custom Lightning Type Metadata
* **`lightningTypes/myCustomInputType/schema.json`**:
```json
{
  "title": "My Custom Input Schema",
  "lightning:type": "@apexClassType/c__CustomInputWrapper"
}
```

* **`lightningTypes/myCustomInputType/lightningDesktopGenAi/editor.json`**:
```json
{
  "editor": {
    "componentOverrides": {
      "$": {
        "definition": "c/customInputEditor"
      }
    }
  }
}
```

### C. Lightning Web Component
* **`lwc/customInputEditor/customInputEditor.html`**:
```html
<template>
    <div class="slds-form-element slds-p-around_small">
        <label class="slds-form-element__label slds-text-title_bold">{label}</label>
        <div class="slds-form-element__control">
            <lightning-combobox
                name="inputValue"
                value={selectedVal}
                placeholder="Select option..."
                options={options}
                onchange={handleChange}
                required>
            </lightning-combobox>
        </div>
    </div>
</template>
```

* **`lwc/customInputEditor/customInputEditor.js`**:
```javascript
import { LightningElement, api } from 'lwc';

export default class CustomInputEditor extends LightningElement {
    @api value; // The raw input value object from the agent reasoner
    _selectedValue;

    options = [
        { label: 'Option A', value: 'A' },
        { label: 'Option B', value: 'B' }
    ];

    get selectedVal() {
        return this._selectedValue !== undefined ? this._selectedValue : (this.value ? this.value.inputValue : '');
    }

    handleChange(event) {
        event.stopPropagation();
        this._selectedValue = event.detail.value;
        
        // Dispatch Custom Event valuechange to notify the Atlas Reasoner
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    inputValue: this._selectedValue
                }
            }
        }));
    }
}
```

* **`lwc/customInputEditor/customInputEditor.js-meta.xml`**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__AgentforceInput</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__AgentforceInput">
            <targetType name="c__myCustomInputType"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

---

## 4. Key Troubleshooting Rules
1. **Breaking Change error during `sf project deploy start`**: 
   * **Cause**: Salesforce blocks editing `lightning:type` on a deployed Custom Lightning Type.
   * **Resolution**: Delete the old type directories locally (so they don't get compiled in the deploy payload) and create a new type under a different name (e.g. append `WrapperType`).
2. **Component does not render (falls back to plain text)**:
   * Confirm the LWC metadata target is `lightning__AgentforceInput` and the `<targetType>` is spelled exactly like the CLT.
   * Ensure `editor.json` is located under the `lightningDesktopGenAi` subfolder within the CLT directory.
   * Confirm the Apex Wrapper is defined as a `global` outer class.
