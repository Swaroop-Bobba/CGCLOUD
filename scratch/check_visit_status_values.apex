Schema.DescribeFieldResult fieldResult = Visit.Status.getDescribe();
List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

System.debug('=== Visit Status Picklist Values ===');
for (Schema.PicklistEntry entry : ple) {
    System.debug('Label: ' + entry.getLabel() + ' | API Value: ' + entry.getValue() + ' | Active: ' + entry.isActive());
}
