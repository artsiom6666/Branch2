@isTest
private class CommissionsEarnedTriggerTest {

	@isTest static void commissionsEarnedAndAffiliateOffer() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];

		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		insert accA;

		Offer__c offerA = new Offer__c(Commission_Payable__c = 20, Active__c = true);
		insert offerA;

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 15);
		insert affiliateOfferA;


		//Trigger.isAfter && Trigger.isInsert
		Commissions_Earned__c commissionsEarnedA = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerA.Id, Commission_Earned__c = 10);
		insert commissionsEarnedA;

		Affiliate_Offer__c affiliateOfferTestA = [SELECT Id, Commissions_Earned__c FROM Affiliate_Offer__c LIMIT 1];
		System.assertEquals(10, affiliateOfferTestA.Commissions_Earned__c);

		//Trigger.isAfter && Trigger.isUpdate
		commissionsEarnedA.Commission_Earned__c = 20;
		update commissionsEarnedA;
		Affiliate_Offer__c affiliateOfferTestB = [SELECT Id, Commissions_Earned__c FROM Affiliate_Offer__c LIMIT 1];
		System.assertEquals(20, affiliateOfferTestB.Commissions_Earned__c);

		//Trigger.isAfter && Trigger.isDelete
		delete commissionsEarnedA;
		Affiliate_Offer__c affiliateOfferTestC = [SELECT Id, Commissions_Earned__c FROM Affiliate_Offer__c LIMIT 1];
		System.assertEquals(0, affiliateOfferTestC.Commissions_Earned__c);

	}

}