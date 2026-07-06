/**
 * @description Global handler for routing agent requests to specific domain services.
 */
public with sharing class Agent_Global_Handler {

    /**
     * @description Auto-generated ApexDoc for method.
     * @param requests List of Agent_Request objects containing routing and payload information.
     * @return List of Agent_Response objects containing the result of the routed execution.
     */
    @InvocableMethod(label='Global Agent Handler' description='Universal handler that dynamically routes to the appropriate Service class based on the Domain parameter.')
    public static List<Agent_Response> execute(List<Agent_Request> requests) {
        List<Agent_Response> results = new List<Agent_Response>();

        for (Agent_Request req : requests) {
            Agent_Response res = new Agent_Response();
            try {
                if (String.isBlank(req.domain)) {
                    if (String.isNotBlank(req.actionType)) {
                        String act = req.actionType.toLowerCase().trim();
                        if (act == 'getavailable' || act == 'getaccountvisits' || act == 'getoosvisits' || 
                            act == 'updatevisit' || act.startsWith('update_visit') || act == 'generate_visit_summary' ||
                            act == 'promptvisitmobile' || act == 'createvisit' || act == 'create_visit_record' || 
                            act == 'create_visit_record_mobile' || act == 'generatesummary') {
                            req.domain = 'Visit';
                        } else if (act == 'getcounts' || act == 'getrecords' || act == 'suggestproducts' || act == 'getproducts') {
                            req.domain = 'Account';
                        } else if (act == 'getaccountsummary' || act == 'getvisitsummary' || act == 'getlineitems' || act == 'updatenotes') {
                            req.domain = 'Order';
                        } else if (act == 'search') {
                            if (String.isBlank(req.agentName)) {
                                req.domain = 'Visit';
                            } else {
                                req.domain = 'User';
                            }
                        }
                    }
                }

                if (String.isBlank(req.domain)) {
                    res.success = false;
                    res.message = 'Domain parameter is required.';
                    results.add(res);
                    continue;
                }

                // Resolve the service class name based on domain to avoid standard object conflicts
                String domain = req.domain.trim();
                String className = domain;
                
                if (domain.equalsIgnoreCase('Visit')) {
                    className = 'Visit_Agent_Service';
                } else if (domain.equalsIgnoreCase('Account')) {
                    className = 'Account_Agent_Service';
                } else if (domain.equalsIgnoreCase('Order')) {
                    className = 'Order_Agent_Service';
                } else if (domain.equalsIgnoreCase('User')) {
                    className = 'User_Agent_Service';
                } else if (domain.equalsIgnoreCase('OrderRecommendation')) {
                    className = 'Order_Recommendation_Service';
                } else if (domain.equalsIgnoreCase('VisitActivity')) {
                    className = 'Visit_Activity_Service';
                }
                
                Type serviceType = Type.forName(className);
                if (serviceType == null && className == domain) {
                    className = domain + '_Agent_Service';
                    serviceType = Type.forName(className);
                }

                if (serviceType == null) {
                    res.success = false;
                    res.message = 'Unknown domain service: ' + className;
                    results.add(res);
                    continue;
                }

                IAgentService service = (IAgentService) serviceType.newInstance();
                res = service.execute(req);

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error executing ' + req.domain + ' action: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}
