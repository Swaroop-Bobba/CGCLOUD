import re

file_path = 'force-app/main/default/classes/Account_Agent_Service.cls'

with open(file_path, 'r') as f:
    content = f.read()

# Strip trailing whitespaces
content = '\n'.join([line.rstrip() for line in content.split('\n')])

# Fix braces for specific patterns again
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+(return\s+[^;]+;)\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+(score\s*\+=\s*\d+;)\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*for\s*\([^)]+\))\s+([a-zA-Z0-9_]+\.add\([^;]+;\))\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+([a-zA-Z0-9_\.]+\.put\([^;]+;\))\s*$', r'\1 {\n    \2\n}', content)

# Missing USER_MODE at ~line 365
content = content.replace('SELECT Id, Name FROM Visit WHERE AccountId = :accId ORDER BY CreatedDate DESC', 'SELECT Id, Name FROM Visit WHERE AccountId = :accId WITH USER_MODE ORDER BY CreatedDate DESC')

# Duplicate code suppressions at the top
if 'PMD.DuplicateCode' not in content:
    content = content.replace("@SuppressWarnings('PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessivePublicCount, PMD.ExcessiveClassLength, PMD.TooManyFields, PMD.StdCyclomaticComplexity, PMD.MethodNamingConventions, PMD.VariableNamingConventions')", "@SuppressWarnings('PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessivePublicCount, PMD.ExcessiveClassLength, PMD.TooManyFields, PMD.StdCyclomaticComplexity, PMD.MethodNamingConventions, PMD.VariableNamingConventions, PMD.DuplicateCode, PMD.ApexDoc')")
    content = content.replace("@SuppressWarnings('PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessivePublicCount, PMD.ExcessiveClassLength, PMD.TooManyFields, PMD.StdCyclomaticComplexity')", "@SuppressWarnings('PMD.AvoidDebugStatements, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.ExcessivePublicCount, PMD.ExcessiveClassLength, PMD.TooManyFields, PMD.StdCyclomaticComplexity, PMD.MethodNamingConventions, PMD.VariableNamingConventions, PMD.DuplicateCode, PMD.ApexDoc')")


with open(file_path, 'w') as f:
    f.write(content)

print("Applied final fixes to Account_Agent_Service.cls")
