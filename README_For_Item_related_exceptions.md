This report shows a list of exceptions, which are actions taken by an operator (staff member) and are recorded in the circulation log. 
An example is when an item has been manually discharged or discharged by an operator. 

Data fields included are: Date range, location of action, description of action, the loan id on which the action was performed, item details (item id, barcode, and title),
patron name and email, patron group type, and operator id.

The report can be filtered on a date range, type of actions, and location where the action took place.
(There is a long list of actions: see https://s3.amazonaws.com/foliodocs/api/mod-audit/p/circulation-logs.html).

NOTE: This report includes patron personal information and operator identifying ID information, which is not GDPR-compliant. This is needed to identify whether the same 
patron has received an excessive number of fee or other waivers on items, and which operator is responsible for the actions.



Brief description:

This report generates data with the following format:
