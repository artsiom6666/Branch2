global with sharing class GlobalButtonsController {

	Webservice static void postToAffiliateAPI(String recordId) {
		String escapeRecordId = String.escapeSingleQuotes(recordId);
		List<Account> accounts = [SELECT Id, FirstName, LastName, Affiliate_Approval__c, PersonEmail FROM Account WHERE Id=:recordId];
			try {
				HttpRequest req = new HttpRequest();
				req.setEndpoint('callout:TouchCRBase__AffiliateSiteHeroku');
				req.setMethod('POST');
				Map<String, String> accountData = new Map<String, String>{
					'accountName' => (accounts[0].FirstName + ' ' + accounts[0].LastName),
					'accountEmail' => accounts[0].PersonEmail,
					'affiliateApproval' => accounts[0].Affiliate_Approval__c
				};
				req.setHeader('Content-Type', 'application/json');
				req.setHeader('Origin', 'Salesforce');

				String requestBody = JSON.serialize(accountData);
				req.setBody(requestBody);
				Http http = new Http();
				if(!Test.isRunningTest()){
					HTTPResponse res = http.send(req);
				}
			} catch (Exception e) {}	
	}

	Webservice static String setAffiliateFrozen(String recordId) {
		String escapeRecordId = String.escapeSingleQuotes(recordId);
		List<Account> accounts = [SELECT Id, FirstName, LastName, Affiliate_Approval__c, PersonEmail FROM Account WHERE Id=:recordId];
		if (!accounts.isEmpty()) {
			accounts[0].Affiliate_Approval__c = 'Frozen';
			try {
				SFDCAccessController.UpdateWithoutSharing (
					accounts[0],
					'GlobalButtonsController.cls [setAffiliateFrozen]',
					new List<Schema.DescribeFieldResult> {
						Account.Affiliate_Approval__c.getDescribe()
					}
				);
			} catch (Exception e) {return 'error';}
			return 'true';
		}
		return 'false';
	}

	Webservice static String setAffiliateUnFrozen(String recordId) {
		String escapeRecordId = String.escapeSingleQuotes(recordId);
		List<Account> accounts = [SELECT Id, FirstName, LastName, Affiliate_Approval__c, PersonEmail FROM Account WHERE Id=:recordId];
		if (!accounts.isEmpty()) {
			accounts[0].Affiliate_Approval__c = 'Approved';
			try {
				SFDCAccessController.UpdateWithoutSharing (
					accounts[0],
					'GlobalButtonsController.cls [setAffiliateFrozen]',
					new List<Schema.DescribeFieldResult> {
						Account.Affiliate_Approval__c.getDescribe()
					}
				);
			} catch (Exception e) {return 'error';}
			return 'true';
		}
		return 'false';
	}

	Webservice static String approveAccountToAffiliate(String recordId) {
		List<Account> accounts = [SELECT Id, FirstName, LastName, Affiliate_Approval__c, Company_Name__c, PersonEmail FROM Account WHERE id=:recordId];
		if (accounts[0].Affiliate_Approval__c == 'Waiting for Approval' 
			&& accounts[0].Company_Name__c != null) {
			RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' LIMIT 1];
			accounts[0].RecordTypeId = recType.Id;
			accounts[0].Affiliate_Approval__c = 'Approved';
			try {
				SFDCAccessController.UpdateWithoutSharing (
					accounts[0],
					'GlobalButtonsController.cls [approveAccountToAffiliate]',
					new List<Schema.DescribeFieldResult> {
						Account.Affiliate_Approval__c.getDescribe(),
						Account.RecordTypeId.getDescribe()
					}
				);
			} catch (Exception e) {return 'error';}
			return 'true';
		}
		return 'false';
	}

}