import re

file_path = 'force-app/main/default/classes/Account_Agent_Service.cls'

with open(file_path, 'r') as f:
    content = f.read()

# Strip trailing whitespaces
content = '\n'.join([line.rstrip() for line in content.split('\n')])

# Fix braces for specific patterns
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+(return\s+[^;]+;)\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+(score\s*\+=\s*\d+;)\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*for\s*\([^)]+\))\s+([a-zA-Z0-9_]+\.add\([^;]+;\))\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+([a-zA-Z0-9_\.]+\.put\([^;]+;\))\s*$', r'\1 {\n    \2\n}', content)

# Missing USER_MODE
content = content.replace('WHERE AccountId = :accId AND cgcloud__OOS_Issues__c = true\n                    LIMIT 50', 'WHERE AccountId = :accId AND cgcloud__OOS_Issues__c = true\n                    WITH USER_MODE\n                    LIMIT 50')

with open(file_path, 'w') as f:
    f.write(content)

print("Applied final fixes to Account_Agent_Service.cls")
