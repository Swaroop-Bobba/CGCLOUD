import re
import os

files = [
    'force-app/main/default/classes/Account_Agent_Counts_Service.cls',
    'force-app/main/default/classes/Account_Agent_Products_Service.cls',
    'force-app/main/default/classes/Account_Agent_Records_Service.cls'
]

methods_code = []

for f in files:
    with open(f, 'r') as file:
        content = file.read()
        # Extract everything inside the class body
        match = re.search(r'class\s+\w+\s*\{([\s\S]*)\}', content)
        if match:
            methods_code.append(match.group(1))

merged_content = '''/**
 * @description Master Service class to handle Account operations for Agentforce.
 */
@SuppressWarnings('PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessivePublicCount, PMD.ExcessiveClassLength, PMD.TooManyFields, PMD.StdCyclomaticComplexity')
public with sharing class Account_Agent_Service {
''' + ''.join(methods_code) + '''
}
'''

with open('force-app/main/default/classes/Account_Agent_Service.cls', 'w') as out_file:
    out_file.write(merged_content)

print("Merge completed.")
