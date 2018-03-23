@isTest
private class PayoutTriggerTest {

	@isTest static void testPayoutTrigger() {

		//Trigger.isBefore && Trigger.isInsert
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];

		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Available_Balance__c = 10);
		Account accB = new Account(RecordTypeId = customerRecordType.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Available_Balance__c = 20);
		Account accC = new Account(RecordTypeId = customerRecordType.Id, LastName = 'CAccount', FirstName = 'First', PersonEmail = 'testC@gmail.com', Phone = '1234567890', Available_Balance__c = 30);
		insert new List<Account> {accA, accB, accC};

		Offer__c offerA = new Offer__c(Commission_Payable__c = 10, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 20, Active__c = true);
		insert new List<Offer__c> {offerA, offerB};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Commissions_Earned_for_Withdrawal__c = 10);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerB.Id, Commissions_Earned_for_Withdrawal__c = 20);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB};

		Payouts__c payoutA = new Payouts__c (Account__c = accA.Id, Amount_Transferred__c = 10, Status__c = 'Waiting For Approval');
		insert payoutA;

		Payouts__c payoutInserted = [SELECT Id, Amount_Transferred__c FROM Payouts__c LIMIT 1];
		System.assertEquals(payoutInserted.Amount_Transferred__c, 10);


		//Trigger.isAfter && Trigger.isUpdate
		Commissions_Earned__c commissionEarnedA = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.Id, Commission_Earned__c = 10, Payouts__c = payoutA.Id);
		insert commissionEarnedA;

		payoutA.Status__c = 'Approved';
		update payoutA;

		Commissions_Earned__c commissionA = [SELECT Id, Status__c, Payouts__r.Status__c FROM Commissions_Earned__c WHERE Payouts__c =:payoutA.Id LIMIT 1];
		System.assertEquals(commissionA.Status__c, 'Paid');


		//Trigger.isAfter && Trigger.isInsert
		Commissions_Earned__c commissionEarnedB = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferB.Id, Commission_Earned__c = 20, Status__c = 'Available for Withdrawal', Type__c = 'Sales');
		insert commissionEarnedB;
		Payouts__c payoutB = new Payouts__c (Account__c = accB.Id, Amount_Transferred__c = 20, Status__c = 'Waiting For Approval');
		insert payoutB;
		Commissions_Earned__c commissionTest = [SELECT Id, Payouts__c, Status__c FROM Commissions_Earned__c WHERE Affiliate_Offer__c =: affiliateOfferB.Id LIMIT 1];
		System.AssertEquals(commissionTest.Status__c, 'Pending Withdrawal');


		//Trigger.isBefore && Trigger.isInsert Error
		try {
			Payouts__c payoutC = new Payouts__c (Account__c = accC.Id, Amount_Transferred__c = 10, Status__c = 'Waiting For Approval');
			insert payoutC;
		} catch (Exception e){
			Boolean expectedExceptionThrown = (e.getMessage().contains('The amount of the transfer')) ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
		}

	}

}