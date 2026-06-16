Account acc = new Account(Name='Dummy Account');
insert acc;
TriggerAccountExtensionAction.Request req = new TriggerAccountExtensionAction.Request();
req.accountId = acc.Id;
List<TriggerAccountExtensionAction.Result> res = TriggerAccountExtensionAction.triggerExtension(new List<TriggerAccountExtensionAction.Request>{req});
System.debug('Result: ' + JSON.serializePretty(res));
