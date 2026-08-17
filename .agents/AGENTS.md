# Workspace Rules

## Permission Set Management Rule
Always update the `Visit_Intel_Access` permission set (`Visit_Intel_Access.permissionset-meta.xml`) with the required accesses (e.g. Apex classes, wrappers, handlers, or flows) whenever custom Apex classes, actions, or flows are added, updated, or created for the Agent.

## Account Summary Direct Google Maps Link Rule
For Account Summary features across all agents (including `VisitIntelDesktop` and `VisitIntelMobile`), Google Maps navigation links MUST be generated directly as web URLs (`https://www.google.com/maps?q=...`) without routing through Visualforce pages (`/apex/GoogleMapRedirect?q=...`), matching direct protocol behavior like `mailto:` and `tel:`.

