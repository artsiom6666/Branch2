@isTest
private class GlobalButtonsControllerTest {

	@isTest
	static void setAffiliateFrozenUnFrozenTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Affiliate_Approval__c = 'Approved');
		Account accB = new Account(RecordTypeId = customerRecordType.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Affiliate_Approval__c = 'Frozen');
		insert new List<Account> {accA, accB};

		String result;
		result = GlobalButtonsController.setAffiliateFrozen(String.valueOf(accA.id));
		System.assertEquals(2, [SELECT COUNT() FROM Account WHERE Affiliate_Approval__c = 'Frozen']);
		System.assertEquals('true', result);

		result = GlobalButtonsController.setAffiliateUnFrozen(String.valueOf(accA.id));
		result = GlobalButtonsController.setAffiliateUnFrozen(String.valueOf(accB.id));
		GlobalButtonsController.postToAffiliateAPI(String.valueOf(accA.id));
		System.assertEquals(2, [SELECT COUNT() FROM Account WHERE Affiliate_Approval__c = 'Approved']);
		System.assertEquals('true', result);

	}

	@isTest
	static void approveAccountToAffiliateTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account accA = new Account(RecordTypeId = customerRecordType.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Company_Name__c = 'testCompany', Affiliate_Approval__c = 'Approved');
		Account accB = new Account(RecordTypeId = customerRecordType.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Company_Name__c = 'testCompany', Affiliate_Approval__c = 'Waiting for Approval');
		insert new List<Account> {accA, accB};

		GlobalButtonsController.approveAccountToAffiliate(String.valueOf(accB.id));
		System.assertEquals(2, [SELECT COUNT() FROM Account WHERE Affiliate_Approval__c = 'Approved']);

	}

}