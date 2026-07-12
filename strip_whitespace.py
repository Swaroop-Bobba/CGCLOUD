with open('force-app/main/default/classes/Account_Agent_Counts_Service.cls', 'r') as file:
    lines = file.readlines()

with open('force-app/main/default/classes/Account_Agent_Counts_Service.cls', 'w') as file:
    for line in lines:
        file.write(line.rstrip() + '\n')
print('Removed trailing whitespace.')
