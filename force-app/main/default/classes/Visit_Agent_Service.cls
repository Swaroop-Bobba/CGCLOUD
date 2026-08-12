/**
 * @description Master Service class to handle Visit operations for Agentforce.
 */
public with sharing class Visit_Agent_Service implements IAgentService {
  /**
   * @description Executes the visit-related agent actions.
   * @param req The agent request.
   * @return Agent_Response The agent response.
   */
  public Agent_Response execute(Agent_Request req) {
    Agent_Response res = new Agent_Response();
    String action = req.actionType != null
      ? req.actionType.toLowerCase().trim()
      : '';

    try {
      if (action == 'getavailable') {
        res.visits = getAvailableVisits();
        Integer totalCount = [SELECT COUNT() FROM Visit WITH USER_MODE];
        res.totalVisits = totalCount;
        res.message =
          'Total visits in the database: ' +
          totalCount +
          '. Showing the top 20 matches. Please let me know if you would like to apply filters like account, status, or date range to narrow down the results.';
        res.success = true;
      } else if (action == 'getaccountvisits') {
        res.visits = getAccountVisits(req.accountId, req.searchOffset);
        res.success = true;
      } else if (action == 'getoosvisits') {
        res.visits = getOosVisits(req.accountId, req.searchOffset);
        res.success = true;
      } else if (action == 'search') {
        res.visits = searchVisits(req.searchQuery, req.searchOffset);
        Integer totalCount = [SELECT COUNT() FROM Visit];
        res.totalVisits = totalCount;
        if (
          String.isNotBlank(req.searchQuery) &&
          (req.searchQuery.trim().equalsIgnoreCase('all') ||
          req.searchQuery.trim().equalsIgnoreCase('all visits'))
        ) {
          res.message =
            'Total visits in the database: ' +
            totalCount +
            '. Showing the top 20 matches. Please let me know if you would like to apply filters like account, status, or date range to narrow down the results.';
        } else {
          res.message =
            'Total visits matching your search: ' +
            res.visits.size() +
            ' (out of ' +
            totalCount +
            ' in the org)';
        }
        res.success = true;
      } else if (
        action == 'updatevisit' ||
        action == 'update_visit_record' ||
        action == 'update_visit_status' ||
        action == 'update_visit_owner' ||
        action == 'update_visit_notes' ||
        action == 'update_visit_start_time' ||
        action == 'update_visit_end_time' ||
        action == 'update_visit_status_mobile_action' ||
        action == 'update_visit_owner_mobile_action' ||
        action == 'update_visit_notes_mobile_action' ||
        action == 'update_visit_start_time_mobile_action' ||
        action == 'update_visit_end_time_mobile_action'
      ) {
        res = updateVisit(req);
      } else if (action == 'get_visit_for_update') {
        res = getVisitForUpdate(req);
      } else if (
        action == 'createvisit' ||
        action == 'create_visit_record' ||
        action == 'create_visit_record_mobile'
      ) {
        createVisit(req, res);
      } else if (action == 'getstorebrief') {
        res.message = getStoreBrief(req.visitId, req.accountId);
        res.success = true;
      } else if (action == 'generatesummary') {
        res.message = generateVisitSummary(req.visitId);
        res.success = true;
      } else if (
        action == 'promptvisitmobile' ||
        action == 'prompt_visit_mobile'
      ) {
        promptVisitMobile(req, res);
      } else if (action == 'select_and_navigate_visit') {
        res = selectAndNavigateVisit(req);
      } else if (action == 'getstalevisits' || action == 'get_stale_visits') {
        res.staleVisits = getStaleVisits(req.accountId, req.searchOffset);
        res.success = true;
      } else if (action == 'sendvisitalerts' || action == 'send_visit_alerts') {
        res = sendVisitAlerts(req.visitIds);
      } else {
        res.success = false;
        res.message = 'Unknown actionType: ' + action;
      }
    } catch (Exception e) {
      res.success = false;
      res.message = e.getMessage();
    }
    return res;
  }

  // --- Search Delegates ---

  /**
   * @description Gets available visits for the current user.
   * @return List<Agent_Response.VisitOption> List of visit options.
   */
  @AuraEnabled
  public static List<Agent_Response.VisitOption> getAvailableVisits() {
    return Visit_Search_Helper.getAvailableVisits();
  }

  /**
   * @description Gets visits for a specific account.
   * @param accountId Account ID.
   * @param searchOffset Search offset.
   * @return List<Agent_Response.VisitOption> List of visit options.
   */
  public static List<Agent_Response.VisitOption> getAccountVisits(String accountId, String searchOffset) {
    return Visit_Search_Helper.getAccountVisits(accountId, searchOffset);
  }

  /**
   * @description Gets out-of-stock visits for an account.
   * @param accountId Account ID.
   * @param searchOffset Search offset.
   * @return List<Agent_Response.VisitOption> List of visit options.
   */
  public static List<Agent_Response.VisitOption> getOosVisits(String accountId, String searchOffset) {
    return Visit_Search_Helper.getOosVisits(accountId, searchOffset);
  }

  /**
   * @description Searches visits based on search query string.
   * @param searchQuery Search query.
   * @param searchOffset Search offset.
   * @return List<Agent_Response.VisitOption> List of visit options.
   */
  public static List<Agent_Response.VisitOption> searchVisits(String searchQuery, String searchOffset) {
    return Visit_Search_Helper.searchVisits(searchQuery, searchOffset);
  }

  // --- Action Delegates ---

  /**
   * @description Updates an existing visit record.
   * @param req Agent request.
   * @return Agent_Response Result of update.
   */
  public static Agent_Response updateVisit(Agent_Request req) {
    return Visit_Action_Helper.updateVisit(req);
  }

  /**
   * @description Retrieves visit details for full update.
   * @param req Agent request.
   * @return Agent_Response Visit update payload response.
   */
  public static Agent_Response getVisitForUpdate(Agent_Request req) {
    return Visit_Action_Helper.getVisitForUpdate(req);
  }

  /**
   * @description Creates a new visit record.
   * @param req Agent request.
   * @param res Agent response.
   */
  public static void createVisit(Agent_Request req, Agent_Response res) {
    Visit_Action_Helper.createVisit(req, res);
  }

  /**
   * @description Prompts the visit mobile.
   * @param req Agent request.
   * @param res Agent response.
   */
  public static void promptVisitMobile(Agent_Request req, Agent_Response res) {
    Visit_Action_Helper.promptVisitMobile(req, res);
  }

  /**
   * @description Selects a visit by ID and returns navigation payload.
   * @param req Agent request.
   * @return Agent_Response Agent response.
   */
  public static Agent_Response selectAndNavigateVisit(Agent_Request req) {
    return Visit_Action_Helper.selectAndNavigateVisit(req);
  }

  /**
   * @description Gets stale visits for an account.
   * @param accountId Account ID.
   * @param searchOffset Query offset.
   * @return List<Agent_Response.StaleVisitInfo> Stale visits list.
   */
  public static List<Agent_Response.StaleVisitInfo> getStaleVisits(String accountId, String searchOffset) {
    return Visit_Action_Helper.getStaleVisits(accountId, searchOffset);
  }

  /**
   * @description Sends custom notifications and creates tasks for specified visits.
   * @param visitIds List of visit IDs.
   * @return Agent_Response Result of sending alerts.
   */
  public static Agent_Response sendVisitAlerts(List<String> visitIds) {
    return Visit_Action_Helper.sendVisitAlerts(visitIds);
  }

  // --- Summary Delegates ---

  /**
   * @description Gets question summary counts for a visit.
   * @param visitId Visit ID.
   * @return Map<String, Integer> Question summary map.
   */
  public static Map<String, Integer> getQuestionsSummaryCounts(String visitId) {
    return Visit_Summary_Helper.getQuestionsSummaryCounts(visitId);
  }

  /**
   * @description Gets planned activity details for a visit.
   * @param visitId Visit ID.
   * @return String Formatted details text.
   */
  public static String getPlannedActivitiesDetails(String visitId) {
    return Visit_Summary_Helper.getPlannedActivitiesDetails(visitId);
  }

  /**
   * @description Gets activity counts for a visit.
   * @param visitId Visit ID.
   * @return Map<String, Integer> Activity counts map.
   */
  public static Map<String, Integer> getActivityCounts(String visitId) {
    return Visit_Summary_Helper.getActivityCounts(visitId);
  }

  /**
   * @description Generates store brief summary string.
   * @param visitId Visit ID.
   * @param accountId Account ID.
   * @return String Store brief text.
   */
  public static String getStoreBrief(String visitId, String accountId) {
    return Visit_Summary_Helper.getStoreBrief(visitId, accountId);
  }

  /**
   * @description Generates string summary for a visit.
   * @param visitId Visit ID.
   * @return String Summary text.
   */
  public static String generateVisitSummary(String visitId) {
    return Visit_Summary_Helper.generateVisitSummary(visitId);
  }

  /**
   * @description Generates object summary wrapper for a visit.
   * @param visitId Visit ID.
   * @return VisitSummaryWrapper Summary wrapper object.
   */
  public static VisitSummaryWrapper generateVisitSummaryObj(String visitId) {
    return Visit_Summary_Helper.generateVisitSummaryObj(visitId);
  }

  // --- AuraEnabled Lookup Delegates ---

  /**
   * @description Gets picklist options for Visit Status.
   * @return List<Map<String, String>> Options list.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getStatusOptions() {
    return Visit_Lookup_Helper.getStatusOptions();
  }

  /**
   * @description Gets active users.
   * @return List<Map<String, String>> Options list.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getActiveUsers() {
    return Visit_Lookup_Helper.getActiveUsers();
  }

  /**
   * @description Searches active users.
   * @param searchTerm Search query string.
   * @return List<Map<String, String>> Options list.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> searchUsers(String searchTerm) {
    return Visit_Lookup_Helper.searchUsers(searchTerm);
  }

  /**
   * @description Gets user name by ID.
   * @param userId User ID.
   * @return String User name.
   */
  @AuraEnabled(cacheable=true)
  public static String getUserName(Id userId) {
    return Visit_Lookup_Helper.getUserName(userId);
  }

  /**
   * @description Searches accounts.
   * @param searchTerm Search query string.
   * @return List<Map<String, String>> Options list.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> searchAccounts(String searchTerm) {
    return Visit_Lookup_Helper.searchAccounts(searchTerm);
  }

  /**
   * @description Gets account name by ID.
   * @param accountId Account ID.
   * @return String Account name.
   */
  @AuraEnabled(cacheable=true)
  public static String getAccountName(Id accountId) {
    return Visit_Lookup_Helper.getAccountName(accountId);
  }

  /**
   * @description Searches places (RetailStore and Location).
   * @param searchTerm Search query string.
   * @return List<Map<String, String>> Options list.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> searchPlaces(String searchTerm) {
    return Visit_Lookup_Helper.searchPlaces(searchTerm);
  }

  /**
   * @description Gets place name by ID.
   * @param placeId Place ID.
   * @return String Place name.
   */
  @AuraEnabled(cacheable=true)
  public static String getPlaceName(Id placeId) {
    return Visit_Lookup_Helper.getPlaceName(placeId);
  }

  /**
   * @description Searches visit templates.
   * @param searchTerm Search query string.
   * @return List<Map<String, String>> Options list.
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, String>> searchTemplates(String searchTerm) {
    return Visit_Lookup_Helper.searchTemplates(searchTerm);
  }

  /**
   * @description Gets template name by ID.
   * @param templateId Template ID.
   * @return String Template name.
   */
  @AuraEnabled(cacheable=true)
  public static String getTemplateName(Id templateId) {
    return Visit_Lookup_Helper.getTemplateName(templateId);
  }

  /**
   * @description Gets visit details to pre-populate LWC editor form.
   * @param visitId Visit ID.
   * @return CreateVisitWrapper Wrapper object with visit details.
   */
  @AuraEnabled(cacheable=true)
  public static CreateVisitWrapper getVisitDataForLwc(Id visitId) {
    return Visit_Lookup_Helper.getVisitDataForLwc(visitId);
  }

  /**
   * @description Gets responsible user context.
   * @return Map<String, Object> Context map.
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getResponsibleUserContext() {
    return Visit_Lookup_Helper.getResponsibleUserContext();
  }

  /**
   * @description Gets current field values of a visit for LWC editor pre-population.
   * @param visitId Visit ID.
   * @return Map<String, Object> Field values map.
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getVisitFieldValues(Id visitId) {
    return Visit_Lookup_Helper.getVisitFieldValues(visitId);
  }
}