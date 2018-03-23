public with sharing class RestNewOrderProcessControllerV2 {

	public static String setOrder(Map<String, String> orderFormData, RestHelper.DataForOrderItems dataForOrderItems) {
		try{
			String email = orderFormData.containsKey('email') ? orderFormData.get('email') : null;
			if (email == null) { return '{"error":"Email can not be empty","message":"error"}'; }

			String fname = orderFormData.containsKey('fname') ? orderFormData.get('fname') : null;
			String lname = orderFormData.containsKey('lname') ? orderFormData.get('lname') : null;
			String accountId;

			List<Account> anct = [SELECT Id, Type FROM Account WHERE PersonEmail =: email LIMIT 1];

			orderFormData.put('firstName', fname);
			orderFormData.put('lastName', lname);
			orderFormData.put('personEmail', email);

			if (!anct.isEmpty()) {
				orderFormData.put('id',anct[0].id);
			}
			String resultSetAccount = RestPersonAccountController.setPersonAccount(orderFormData);

			if (resultSetAccount.contains('error')) { return resultSetAccount; }
			Map<String, String> workData = (Map<String, String>)JSON.deserialize(resultSetAccount, Map<String, String>.class);
			accountId = (workData.get('accountId'));

			if (anct.isEmpty()) {
				List<Lead> lead = [SELECT Id from Lead WHERE Email =: email LIMIT 1];

				if (lead.size() > 0) {
					try {
						Database.LeadConvert lc = new Database.LeadConvert();
						lc.setLeadId(lead[0].Id);
						lc.setAccountId(accountId);
						LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
						lc.setConvertedStatus(convertStatus.MasterLabel);
						lc.setDoNotCreateOpportunity(true);
						Database.LeadConvertResult lcr = Database.convertLead(lc);
					}
					catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
				}
			} else {
				String response = getCustomerHistory(accountId);
				// -------- Black list or fraud founded --------
				if (response != 'true') { return response; }
			}

			orderFormData.put('accountId', accountId);

			return RestOrderController.setOrder(orderFormData, dataForOrderItems);


		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	/**
	* Check Custome previous record
	* String accountId - account Id
	*/


	public static String getCustomerHistory(String accountId) {
		// -------- Prepare 2 hours before date-time and fetch 2 hours old case related to account id --------
		DateTime earlier = Datetime.now().addMinutes(-120);

		List<Case> cs = [
			SELECT Id, Status
			FROM Case
			WHERE AccountId =: accountId
			AND CreatedDate >= :earlier
			AND Type =: 'Payment'
			AND Reason =: 'Unpaid Order'
			AND Status != : 'Closed'
		];

		if (!cs.isEmpty()) {
			// -------- if 2 hours old case founded make it close --------
			List<Case> caseToUpdate = new List<Case>{};
			for (Case c : cs) {
				c.Status = 'Closed';
				caseToUpdate.add(c);
			}
			update caseToUpdate;

			// -------- If transaction count greater than 4 then return Fraud --------
			List<Account> fraud = [SELECT Id FROM Account WHERE Id = :accountId AND Orders_Failed__c > 4];
			if (fraud.size() != 0) { return 'fraud'; }
		}

		// -------- Check Black list Record --------
		List<Account> acc = [SELECT Id FROM Account WHERE Id = :accountId AND Blacklist__c = : 'true'];
		return (acc.size() == 0) ? 'true' : 'no order allowed';
	}

}