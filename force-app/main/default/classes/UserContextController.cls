/**
 * Retrieves the logged-in user's profile, role, and identity details
 * to personalize conversations and assign visit records.
 */
global with sharing class UserContextController {

    /**
     * @description Explicit zero-argument constructor for 2GP.
     */
    global UserContextController() {}

    /**
     * @description Input DTO for UserContextController.
     */
    global class Request {
        @InvocableVariable(description='Optional domain or action context.')
        global String domain;

        @InvocableVariable(description='Optional action type.')
        global String actionType;

        global Request() {}
    }

    /**
     * @description Output DTO for UserContextController.
     */
    global class Response {
        @InvocableVariable(description='True if the operation was successful.')
        global Boolean success;

        @InvocableVariable(description='The name of the user profile.')
        global String profileName;

        @InvocableVariable(description='Status message.')
        global String message;

        global Response() {}
    }

    @InvocableMethod(
        label='Get Current User Profile'
        description='Retrieves the logged-in user profile name.'
    )
    global static List<Response> execute(List<Request> requests) {
        List<Response> resList = new List<Response>();
        String profName = 'Standard User';
        try {
            Id profileId = UserInfo.getProfileId();
            List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
            if (!profiles.isEmpty()) {
                profName = profiles[0].Name;
            }
        } catch (Exception e) {
            profName = 'Standard User';
        }

        for (Integer i = 0; i < (requests != null && !requests.isEmpty() ? requests.size() : 1); i++) {
            Response res = new Response();
            res.success = true;
            res.profileName = profName;
            res.message = 'Success';
            resList.add(res);
        }
        return resList;
    }
}