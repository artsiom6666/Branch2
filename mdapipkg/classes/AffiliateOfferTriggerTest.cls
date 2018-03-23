@isTest
private class AffiliateOfferTriggerTest {

	// method name: checkForDublicate
	// created: 01/24/2018
	// Author: Stanislau Yarashchuk
	// Create dublicate Affiliate Offer 
	@isTest static void checkForDublicate() {

		List<RecordType> personRecordTypeList = [
			SELECT Id, Name, SobjectType, IsPersonType
			FROM RecordType
			WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true
		];

		System.assertEquals(!personRecordTypeList.isEmpty(), true);

		List<Account> accountList = new List<Account>();
		for (Integer i = 0; i < 200; i++) {
			accountList.add(
				new Account(
					RecordTypeId = personRecordTypeList[0].Id, LastName = 'lastName'+i, FirstName = 'FirstName'+i, PersonEmail = 'testA@gmail'+i+'.com', Phone = '123456789'+i
				)
			);
		}
		insert accountList;
		System.assertEquals(accountList.size(), 200);

		List<Offer__c> offerList = new List<Offer__c>();
		for (Integer i = 0; i < 200; i++) {
			offerList.add(
				new Offer__c(
					Active__c = true
				)
			);
		}
		insert offerList;
		System.assertEquals(offerList.size(), 200);


		List<Affiliate_Offer__c> affiliateOfferList = new List<Affiliate_Offer__c>();
		for (Integer i = 0; i < 200; i++) {
			affiliateOfferList.add(
				new Affiliate_Offer__c(
					Account__c = accountList[i].Id, Offer__c = offerList[0].Id
				)
			);
		}
		insert affiliateOfferList;
		System.assertEquals(affiliateOfferList.size(), 200);

		try {
			List<Affiliate_Offer__c> affiliateOfferNewList = new List<Affiliate_Offer__c>();
			for (Integer i = 0; i < 200; i++) {
				affiliateOfferNewList.add(
					new Affiliate_Offer__c(
						Account__c = accountList[i].Id, Offer__c = offerList[0].Id
					)
				);
			}
			insert affiliateOfferNewList;
		} catch(Exception e) {
			System.AssertEquals(e.getMessage().contains('Duplicate record'), true);
		}

	}

	// method name: checkForDublicate
	// created: 01/25/2018
	// Author: Stanislau Yarashchuk
	// Create commissions earned for calculate comissions on the Affiliate Offer record
	@isTest static void recalculateAffiliateOffer1() {

		List<RecordType> personRecordTypeList = [
			SELECT Id, Name, SobjectType, IsPersonType
			FROM RecordType
			WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true
		];


		List<Account> accountList = new List<Account>();
		for (Integer i = 0; i < 200; i++) {
			accountList.add(
				new Account(
					RecordTypeId = personRecordTypeList[0].Id, LastName = 'lastName'+i, FirstName = 'FirstName'+i, PersonEmail = 'testA@gmail'+i+'.com', Phone = '123456789'+i
				)
			);
		}
		insert accountList;
		System.assertEquals(accountList.size(), 200);

		List<Offer__c> offerList = new List<Offer__c>();
		for (Integer i = 0; i < 200; i++) {
			offerList.add(
				new Offer__c(
					Active__c = true
				)
			);
		}
		insert offerList;
		System.assertEquals(offerList.size(), 200);


		List<Affiliate_Offer__c> affiliateOfferList = new List<Affiliate_Offer__c>();
		for (Integer i = 0; i < 200; i++) {
			affiliateOfferList.add(
				new Affiliate_Offer__c(
					Account__c = accountList[i].Id, Offer__c = offerList[0].Id
				)
			);
		}
		insert affiliateOfferList;
		System.assertEquals(affiliateOfferList.size(), 200);

		List<TouchCRBase__Order__c> orderList = new List<TouchCRBase__Order__c>();
		for (Integer i = 0; i < 200; i++) {
			orderList.add(
				new TouchCRBase__Order__c(
					TouchCRBase__Subtotal__c = 100
				)
			);
		}
		insert orderList;
		System.assertEquals(orderList.size(), 200);

		List<Commissions_Earned__c> commissionEarnedList = new List<Commissions_Earned__c>();
		for (Integer i = 0; i < 200; i++) {
			commissionEarnedList.add(
				new Commissions_Earned__c(
					Affiliate_Offer__c = affiliateOfferList[0].Id,
					Commission_Earned__c = 10,
					Offer__c = offerList[0].Id,
					Order__c = orderList[i].Id,
					Price__c = 100,
					Status__c = 'Not Available for Withdrawal',
					Type__c = 'Sales'
				)
			);
		}
		insert commissionEarnedList;
		System.assertEquals(commissionEarnedList.size(), 200);

		List<Affiliate_Offer__c> affiliateOfferCalculated = [
			SELECT Id, Name, Commissions_Earned__c, Commissions_Earned_for_Withdrawal__c, Commissions_Paid__c, Commissions_Refunded__c,
				Total_Commissions__c, Commissions_Paid_And_Refunded__c, Commission_Not_Passed_Refund_Period__c, Commissions_Pending_Withdrawal__c, 
				Total_Transactions__c, Refund_Transactions__c, Total_Revenue__c, Average_Order_Value__c
			FROM Affiliate_Offer__c
			WHERE Id = :affiliateOfferList[0].Id
		];

		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned_for_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Commissions__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid_And_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commission_Not_Passed_Refund_Period__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Pending_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Refund_Transactions__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Revenue__c, 20000);
		System.assertEquals(affiliateOfferCalculated[0].Average_Order_Value__c, 100);

		for (Commissions_Earned__c item : commissionEarnedList) {
			item.Status__c = 'Available for Withdrawal';
		}
		update commissionEarnedList;

		affiliateOfferCalculated = [
			SELECT Id, Name, Commissions_Earned__c, Commissions_Earned_for_Withdrawal__c, Commissions_Paid__c, Commissions_Refunded__c,
				Total_Commissions__c, Commissions_Paid_And_Refunded__c, Commission_Not_Passed_Refund_Period__c, Commissions_Pending_Withdrawal__c, 
				Total_Transactions__c, Refund_Transactions__c, Total_Revenue__c, Average_Order_Value__c
			FROM Affiliate_Offer__c
			WHERE Id = :affiliateOfferList[0].Id
		];

		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned_for_Withdrawal__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Commissions__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid_And_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commission_Not_Passed_Refund_Period__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Pending_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Refund_Transactions__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Revenue__c, 20000);
		System.assertEquals(affiliateOfferCalculated[0].Average_Order_Value__c, 100);


		for (Commissions_Earned__c item : commissionEarnedList) {
			item.Status__c = 'Pending Withdrawal';
		}
		update commissionEarnedList;

		affiliateOfferCalculated = [
			SELECT Id, Name, Commissions_Earned__c, Commissions_Earned_for_Withdrawal__c, Commissions_Paid__c, Commissions_Refunded__c,
				Total_Commissions__c, Commissions_Paid_And_Refunded__c, Commission_Not_Passed_Refund_Period__c, Commissions_Pending_Withdrawal__c, 
				Total_Transactions__c, Refund_Transactions__c, Total_Revenue__c, Average_Order_Value__c
			FROM Affiliate_Offer__c
			WHERE Id = :affiliateOfferList[0].Id
		];

		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned_for_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Commissions__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid_And_Refunded__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commission_Not_Passed_Refund_Period__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Pending_Withdrawal__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Total_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Refund_Transactions__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Revenue__c, 20000);
		System.assertEquals(affiliateOfferCalculated[0].Average_Order_Value__c, 100);

		for (Commissions_Earned__c item : commissionEarnedList) {
			item.Status__c = 'Refund';
			item.Paid__c = true;
		}
		update commissionEarnedList;

		affiliateOfferCalculated = [
			SELECT Id, Name, Commissions_Earned__c, Commissions_Earned_for_Withdrawal__c, Commissions_Paid__c, Commissions_Refunded__c,
				Total_Commissions__c, Commissions_Paid_And_Refunded__c, Commission_Not_Passed_Refund_Period__c, Commissions_Pending_Withdrawal__c, 
				Total_Transactions__c, Refund_Transactions__c, Total_Revenue__c, Average_Order_Value__c
			FROM Affiliate_Offer__c
			WHERE Id = :affiliateOfferList[0].Id
		];

		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Earned_for_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Refunded__c, -2000);
		System.assertEquals(affiliateOfferCalculated[0].Total_Commissions__c, 2000);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Paid_And_Refunded__c, -2000);
		System.assertEquals(affiliateOfferCalculated[0].Commission_Not_Passed_Refund_Period__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Commissions_Pending_Withdrawal__c, 0);
		System.assertEquals(affiliateOfferCalculated[0].Total_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Refund_Transactions__c, 200);
		System.assertEquals(affiliateOfferCalculated[0].Total_Revenue__c, 20000);
		System.assertEquals(affiliateOfferCalculated[0].Average_Order_Value__c, 100);
	}
}