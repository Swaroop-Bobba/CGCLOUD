global class ApexWrapperTemplate {
    @AuraEnabled
    @InvocableVariable(required=true description='Value placeholder')
    global String valuePlaceholder;
    
    global ApexWrapperTemplate() {}
}
