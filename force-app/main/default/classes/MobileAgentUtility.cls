public with sharing class MobileAgentUtility {

    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class MatchResult {
        public Boolean success;
        public String matchedId;
        public String matchedName;
        public String message;
        public String suggestions;
    }

    /**
     * @description Auto-generated ApexDoc for class.
     */
    public class ScoredCandidate implements Comparable {
        public SObject record;
        public Double score;
        public ScoredCandidate(SObject record, Double score) {
            this.record = record;
            this.score = score;
        }
        /**
         * @description Auto-generated ApexDoc for method.
         */
        public Integer compareTo(Object compareTo) {
            ScoredCandidate other = (ScoredCandidate) compareTo;
            if (this.score == other.score) return 0;
            return (this.score > other.score) ? -1 : 1; // Sort descending
        }
    }

    /**
     * @description Auto-generated ApexDoc for method.
     */
    public static DateTime parseDateTime(String input) {
        if (String.isBlank(input)) {
            return null;
        }

        DateTime dt = tryParseStandardDateTime(input);
        if (dt != null) {
            return dt;
        }

        return parseNaturalLanguageDateTime(input);
    }

    /**
     * @description Auto-generated ApexDoc for method.
     */
    private static DateTime tryParseStandardDateTime(String input) {
        try {
            return (DateTime) JSON.deserialize('"' + input.trim() + '"', DateTime.class);
        } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        try {
            String cleanStr = input.trim();
            if (cleanStr.length() == 10 && cleanStr.contains('-')) {
                cleanStr += 'T00:00:00.000Z';
            } else if (cleanStr.length() == 16 && cleanStr.contains('-') && cleanStr.contains(' ')) {
                cleanStr = cleanStr.replace(' ', 'T') + ':00.000Z';
            } else if (!cleanStr.endsWith('Z') && !cleanStr.contains('+') && cleanStr.contains('T')) {
                cleanStr += 'Z';
            }
            return (DateTime) JSON.deserialize('"' + cleanStr + '"', DateTime.class);
        } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        try {
            return DateTime.valueOf(input.trim().replace('T', ' '));
        } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        return null;
    }

    /**
     * @description Auto-generated ApexDoc for method.
     */
    private static DateTime parseNaturalLanguageDateTime(String input) {
        String str = input.trim().toLowerCase();
        str = str.replaceAll('\\bat\\b', ' ');
        str = str.replaceAll('(\\d+)\\s*(am|pm)', '$1$2');
        str = str.replaceAll('\\s+', ' ').trim();

        Date d = null;
        Time t = Time.newInstance(0, 0, 0, 0);

        if (str.contains('today')) {
            d = Date.today();
            str = str.replace('today', '').trim();
        } else if (str.contains('tomorrow')) {
            d = Date.today().addDays(1);
            str = str.replace('tomorrow', '').trim();
        } else if (str.contains('yesterday')) {
            d = Date.today().addDays(-1);
            str = str.replace('yesterday', '').trim();
        }

        List<String> tokens = str.split(' ');
        String timeStr = '';
        List<String> dateTokens = new List<String>();

        for (String token : tokens) {
            if (token.contains(':') || token.endsWith('am') || token.endsWith('pm')) {
                timeStr = token;
            } else {
                if (String.isNotBlank(token)) {
                    dateTokens.add(token);
                }
            }
        }

        if (String.isNotBlank(timeStr)) {
            t = parseTimePart(timeStr);
        }

        if (d == null && !dateTokens.isEmpty()) {
            d = parseDatePart(dateTokens);
        }

        if (d == null) {
            return null;
        }
        return DateTime.newInstance(d, t);
    }

    private static Time parseTimePart(String timeStr) {
        String cleanTime = timeStr.trim().toLowerCase();
        Boolean isPm = cleanTime.contains('pm');
        Boolean isAm = cleanTime.contains('am');
        cleanTime = cleanTime.replace('am', '').replace('pm', '').trim();

        Integer hour = 0;
        Integer minute = 0;
        Integer second = 0;

        if (cleanTime.contains(':')) {
            List<String> parts = cleanTime.split(':');
            if (parts.size() >= 1) hour = Integer.valueOf(parts[0]);
            if (parts.size() >= 2) minute = Integer.valueOf(parts[1]);
            if (parts.size() >= 3) second = Integer.valueOf(parts[2]);
        } else {
            try {
                hour = Integer.valueOf(cleanTime);
            } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        }

        if (isPm && hour < 12) {
            hour += 12;
        } else if (isAm && hour == 12) {
            hour = 0;
        }

        return Time.newInstance(hour, minute, second, 0);
    }

    private static Date parseDatePart(List<String> dateTokens) {
        List<String> parts = new List<String>();
        if (dateTokens.size() == 1) {
            String token = dateTokens[0];
            if (token.contains('-')) {
                parts = token.split('-');
            } else if (token.contains('/')) {
                parts = token.split('/');
            } else if (token.contains('.')) {
                parts = token.split('\\.');
            } else {
                parts.add(token);
            }
        } else {
            parts = dateTokens;
        }

        if (parts.size() < 2) return null;

        Integer day = 0;
        Integer month = 0;
        Integer year = Date.today().year();

        try {
            day = Integer.valueOf(parts[0]);
        } catch(Exception e) {
            return null;
        }

        String monthPart = parts[1].toLowerCase();
        month = getMonthNumber(monthPart);
        if (month == 0) {
            try {
                month = Integer.valueOf(monthPart);
            } catch(Exception e) {
                return null;
            }
        }

        if (parts.size() >= 3) {
            try {
                year = Integer.valueOf(parts[2]);
                if (year < 100) {
                    year += 2000;
                }
            } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        }

        try {
            return Date.newInstance(year, month, day);
        } catch(Exception e) {
            return null;
        }
    }

    private static Integer getMonthNumber(String monthStr) {
        if (monthStr.startsWith('jan')) return 1;
        if (monthStr.startsWith('feb')) return 2;
        if (monthStr.startsWith('mar')) return 3;
        if (monthStr.startsWith('apr')) return 4;
        if (monthStr.startsWith('may')) return 5;
        if (monthStr.startsWith('jun')) return 6;
        if (monthStr.startsWith('jul')) return 7;
        if (monthStr.startsWith('aug')) return 8;
        if (monthStr.startsWith('sep')) return 9;
        if (monthStr.startsWith('oct')) return 10;
        if (monthStr.startsWith('nov')) return 11;
        if (monthStr.startsWith('dec')) return 12;
        return 0;
    }

    /**
     * @description Auto-generated ApexDoc for method.
     */
        public static MatchResult matchRecord(String input, String sObjectType, String previousSuggestions) {
        MatchResult res = new MatchResult();
        res.success = false;
        res.suggestions = '';

        if (String.isBlank(input)) {
            res.message = 'Input is empty.';
            return res;
        }

        String cleanInput = input.trim();

        // 1. Check index choice selection
        MatchResult indexRes = checkIndexChoice(cleanInput, previousSuggestions);
        if (indexRes != null) return indexRes;

        // 2. ID check
        MatchResult idRes = checkIdMatch(cleanInput, sObjectType);
        if (idRes != null) return idRes;

        // 3. Candidate query & Scoring
        List<ScoredCandidate> scoredList = getScoredCandidates(cleanInput, sObjectType);

        if (scoredList.isEmpty()) {
            res.success = false;
            res.message = 'No record found matching "' + input + '". Please try again.';
            return res;
        }

        if (scoredList[0].score >= 90.0 || (scoredList.size() == 1 && scoredList[0].score >= 50.0)) {
            res.success = true;
            res.matchedId = scoredList[0].record.Id;
            res.matchedName = (String) scoredList[0].record.get('Name');
            res.message = 'Matched: ' + res.matchedName;
            return res;
        }

        res.success = false;
        String prefix = 'I found multiple matching records for "' + input + '". Please reply with the number of your choice:\n';
        List<String> ids = new List<String>();
        Integer idx = 1;
        for (ScoredCandidate sc : scoredList) {
            if (idx > 5) break;
            prefix += idx + '. ' + sc.record.get('Name') + '\n';
            ids.add(sc.record.Id);
            idx++;
        }
        res.message = prefix.trim();
        res.suggestions = String.join(ids, ',');
        return res;
    }

    private static MatchResult checkIndexChoice(String cleanInput, String previousSuggestions) {
        if (cleanInput.isNumeric() && String.isNotBlank(previousSuggestions)) {
            List<String> ids = previousSuggestions.split(',');
            Integer index = Integer.valueOf(cleanInput) - 1;
            if (index >= 0 && index < ids.size()) {
                Id selectedId = (Id) ids[index];
                String objType = selectedId.getSObjectType().getDescribe().getName();
                String query = 'SELECT Id, Name FROM ' + objType + ' WHERE Id = :selectedId LIMIT 1';
                List<SObject> recs = Database.query(query);
                if (!recs.isEmpty()) {
                    MatchResult res = new MatchResult();
                    res.success = true;
                    res.matchedId = recs[0].Id;
                    res.matchedName = (String) recs[0].get('Name');
                    res.message = 'Matched: ' + res.matchedName;
                    return res;
                }
            }
        }
        return null;
    }

    private static MatchResult checkIdMatch(String cleanInput, String sObjectType) {
        if ((cleanInput.length() == 15 || cleanInput.length() == 18) && Pattern.matches('[a-zA-Z0-9]{15,18}', cleanInput)) {
            try {
                Id tempId = (Id) cleanInput;
                String objType = tempId.getSObjectType().getDescribe().getName();
                Boolean typeMatch = (sObjectType == 'Place') ? (objType == 'RetailStore' || objType == 'Location') : (objType == sObjectType);

                if (typeMatch) {
                    String query = 'SELECT Id, Name FROM ' + objType + ' WHERE Id = :tempId LIMIT 1';
                    List<SObject> recs = Database.query(query);
                    if (!recs.isEmpty()) {
                        MatchResult res = new MatchResult();
                        res.success = true;
                        res.matchedId = recs[0].Id;
                        res.matchedName = (String) recs[0].get('Name');
                        res.message = 'Matched: ' + res.matchedName;
                        return res;
                    }
                }
            } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        }
        return null;
    }

    private static List<ScoredCandidate> getScoredCandidates(String cleanInput, String sObjectType) {
        List<SObject> candidates = new List<SObject>();
        List<String> words = cleanInput.split('\\s+');

        if (sObjectType == 'Account') candidates = queryCandidates('Account', words);
        else if (sObjectType == 'cgcloud__Visit_Template__c') candidates = queryCandidates('cgcloud__Visit_Template__c', words);
        else if (sObjectType == 'User') candidates = queryUserCandidates(words);
        else if (sObjectType == 'Place') {
            candidates.addAll(queryCandidates('RetailStore', words));
            candidates.addAll(queryCandidates('Location', words));
        }

        List<ScoredCandidate> scoredList = new List<ScoredCandidate>();
        for (SObject cand : candidates) {
            String name = (String) cand.get('Name');
            scoredList.add(new ScoredCandidate(cand, getMatchScore(cleanInput, name)));
        }
        scoredList.sort();

        if (scoredList.isEmpty()) {
            return getFallbackScoredCandidates(cleanInput, sObjectType);
        }
        return scoredList;
    }

    private static List<SObject> queryCandidates(String objType, List<String> words) {
        List<SObject> candidates = new List<SObject>();
        String query = 'SELECT Id, Name FROM ' + objType + ' WHERE ';
        for (Integer i = 0; i < words.size(); i++) {
            if (i > 0) query += ' AND ';
            query += ' Name LIKE \'%\' + String.escapeSingleQuotes(words[i]) + \'%\'';
        }
        query += ' WITH USER_MODE LIMIT 20';
        try { candidates = Database.query(query); } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }

        if (candidates.isEmpty() && words.size() > 0) {
            String queryFallback = 'SELECT Id, Name FROM ' + objType + ' WHERE Name LIKE \'%\' + String.escapeSingleQuotes(words[0]) + \'%\' WITH USER_MODE LIMIT 10';
            try { candidates = Database.query(queryFallback); } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        }
        return candidates;
    }

    private static List<SObject> queryUserCandidates(List<String> words) {
        List<SObject> candidates = new List<SObject>();
        String query = 'SELECT Id, Name FROM User WHERE IsActive = true AND (';
        for (Integer i = 0; i < words.size(); i++) {
            if (i > 0) query += ' AND ';
            query += ' Name LIKE \'%\' + String.escapeSingleQuotes(words[i]) + \'%\'';
        }
        query += ') WITH USER_MODE LIMIT 20';
        try { candidates = Database.query(query); } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }

        if (candidates.isEmpty() && words.size() > 0) {
            String queryFallback = 'SELECT Id, Name FROM User WHERE IsActive = true AND Name LIKE \'%\' + String.escapeSingleQuotes(words[0]) + \'%\' WITH USER_MODE LIMIT 10';
            try { candidates = Database.query(queryFallback); } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        }
        return candidates;
    }

    private static List<ScoredCandidate> getFallbackScoredCandidates(String cleanInput, String sObjectType) {
        List<SObject> allRecs = new List<SObject>();
        if (sObjectType == 'Account') {
            allRecs = [SELECT Id, Name FROM Account WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT 50];
        } else if (sObjectType == 'Place') {
            try { allRecs.addAll((List<SObject>) [SELECT Id, Name FROM RetailStore WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT 25]); } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
            try { allRecs.addAll((List<SObject>) [SELECT Id, Name FROM Location WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT 25]); } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        } else if (sObjectType == 'cgcloud__Visit_Template__c') {
            try { allRecs = [SELECT Id, Name FROM cgcloud__Visit_Template__c WITH USER_MODE LIMIT 50]; } catch (Exception e) { System.debug(LoggingLevel.ERROR, e.getMessage()); }
        } else if (sObjectType == 'User') {
            allRecs = [SELECT Id, Name FROM User WHERE IsActive = true WITH USER_MODE LIMIT 50];
        }

        List<ScoredCandidate> scoredList = new List<ScoredCandidate>();
        for (SObject cand : allRecs) {
            String name = (String) cand.get('Name');
            Double score = getMatchScore(cleanInput, name);
            if (score > 35.0) {
                scoredList.add(new ScoredCandidate(cand, score));
            }
        }
        scoredList.sort();
        return scoredList;
    }

    /**
     * @description Auto-generated ApexDoc for method.
     */
    public static Double getMatchScore(String input, String target) {
        String lowerInput = input.toLowerCase();
        String lowerTarget = target.toLowerCase();

        if (lowerInput == lowerTarget) return 100.0;
        if (lowerTarget.startsWith(lowerInput)) return 90.0 + lowerInput.length();
        if (lowerTarget.contains(lowerInput)) return 80.0 + lowerInput.length();

        Integer dist = getLevenshteinDistance(lowerInput, lowerTarget);
        Double similarity = 1.0 - ((Double) dist / Math.max(lowerInput.length(), lowerTarget.length()));
        return similarity * 70.0;
    }

    /**
     * @description Auto-generated ApexDoc for method.
     */
    public static Integer getLevenshteinDistance(String s, String t) {
        if (s == t) return 0;
        if (s.length() == 0) return t.length();
        if (t.length() == 0) return s.length();

        List<Integer> d = new List<Integer>();
        Integer n = s.length();
        Integer m = t.length();

        for (Integer i = 0; i <= n; i++) {
            d.add(i);
        }

        for (Integer j = 1; j <= m; j++) {
            Integer prev = d[0];
            d[0] = j;
            for (Integer i = 1; i <= n; i++) {
                Integer temp = d[i];
                Integer cost = (s.substring(i-1, i) == t.substring(j-1, j)) ? 0 : 1;
                d[i] = Math.min(Math.min(d[i] + 1, d[i-1] + 1), prev + cost);
                prev = temp;
            }
        }
        return d[n];
    }
}
