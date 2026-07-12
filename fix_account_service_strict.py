import re

file_path = 'force-app/main/default/classes/Account_Agent_Service.cls'

with open(file_path, 'r') as f:
    content = f.read()

# Fix braces for single line ifs like: if (condition) return value;
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+(return\s+[^;]+;)\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+(continue;)\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+([a-zA-Z0-9_\.]+\s*\+?=\s*[^;]+;)\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*for\s*\([^)]+\))\s+([a-zA-Z0-9_\.]+\.add\([^;]+;\))\s*$', r'\1 {\n    \2\n}', content)
content = re.sub(r'(?m)^(\s*if\s*\([^)]+\))\s+([a-zA-Z0-9_\.]+\.put\([^;]+;\))\s*$', r'\1 {\n    \2\n}', content)

# Fix ApexDocs
content = content.replace('''    /**
     * @description Auto-generated ApexDoc for method.
     */
        public static String suggestProducts(String accountId) {''', '''    /**
     * @description Suggests products for the specified account based on promotions and historical orders.
     * @param accountId The ID of the account.
     * @return String A formatted string containing the recommended products.
     */
    public static String suggestProducts(String accountId) {''')

content = content.replace('''    /**
     * @description Auto-generated ApexDoc for class.
     */
    private class ScoredProduct implements Comparable {''', '''    /**
     * @description Helper class for sorting recommended products based on their calculated score.
     */
    private class ScoredProduct implements Comparable {''')

content = content.replace('''        /**
         * @description Auto-generated ApexDoc for method.
         */
        public Integer compareTo(Object other) {''', '''        /**
         * @description Compares two scored products.
         * @param other The other object to compare.
         * @return Integer The comparison result.
         */
        public Integer compareTo(Object other) {''')

content = content.replace('''        public static List<Agent_Response.RecordInfo> getRelatedRecords(String accountId, String recordType) {''', '''    /**
     * @description Gets the related records of a specific type for an account.
     * @param accountId The ID of the account.
     * @param recordType The type of records to get.
     * @return List<Agent_Response.RecordInfo> A list of RecordInfo objects representing the related records.
     */
    public static List<Agent_Response.RecordInfo> getRelatedRecords(String accountId, String recordType) {''')

with open(file_path, 'w') as f:
    f.write(content)

print("Applied strict fixes to Account_Agent_Service.cls")
