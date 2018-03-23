@isTest
private class OfferCommissionTriggerTest {

	@isTest static void testPercentOfPrice() {

		Product2 iceCreamProduct = new Product2(Name = 'iceCreamProduct', ProductCode = 'iceCreamProductCode', IsActive = true);
		insert iceCreamProduct;

		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 pricebook2GoldMember = new Pricebook2(Name = 'Gold Member', IsActive = true);
		insert pricebook2GoldMember;

		PricebookEntry bookEntryStandart = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = pricebookId);
		PricebookEntry bookEntryGold = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 50, IsActive = true, Pricebook2Id = pricebook2GoldMember.Id);
		insert new List<PricebookEntry> {bookEntryStandart, bookEntryGold};

		Offer__c offerA = new Offer__c(Active__c = false, Offer_Name__c = 'offerA', Commission_Payable__c = 10, Product__c = iceCreamProduct.Id);
		insert offerA;

		offerA.Active__c = true;
		update offerA;

		Offer_Commission__c offerCommissionGold = new Offer_Commission__c (Percent_Of_Price__c = 10, Pricebook_Eligibility__c = pricebook2GoldMember.id, Offer__c = offerA.id);
		insert offerCommissionGold;
		Offer_Commission__c offerCommissionTestA = [SELECT Id, Commission_Payable__c FROM Offer_Commission__c WHERE Percent_Of_Price__c = 10 LIMIT 1];
		System.assertEquals(offerCommissionTestA.Commission_Payable__c, 5);

		offerCommissionGold.Percent_Of_Price__c = 20;
		update offerCommissionGold;
		Offer_Commission__c offerCommissionTestB = [SELECT Id, Commission_Payable__c FROM Offer_Commission__c WHERE Percent_Of_Price__c = 20 LIMIT 1];
		System.assertEquals(offerCommissionTestB.Commission_Payable__c, 10);
	}

	@isTest static void testFixedAmount() {
		Product2 iceCreamProduct = new Product2(Name = 'iceCreamProduct', ProductCode = 'iceCreamProductCode', IsActive = true );
		insert iceCreamProduct;

		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 pricebook2GoldMember = new Pricebook2(Name = 'Gold Member', IsActive = true);
		insert pricebook2GoldMember;

		PricebookEntry bookEntryStandart = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = pricebookId);
		PricebookEntry bookEntryGold = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 50, IsActive = true, Pricebook2Id = pricebook2GoldMember.Id);
		insert new List<PricebookEntry> {bookEntryStandart, bookEntryGold};

		Offer__c offerA = new Offer__c(Active__c = false, Offer_Name__c = 'offerA', Commission_Payable__c = 10, Product__c = iceCreamProduct.Id);
		insert offerA;

		offerA.Active__c = true;
		update offerA;

		Offer_Commission__c offerCommissionGold = new Offer_Commission__c (Fixed_Amount__c = 10, Pricebook_Eligibility__c = pricebook2GoldMember.id, Offer__c = offerA.id);
		insert offerCommissionGold;
		Offer_Commission__c offerCommissionTestA = [SELECT Id, Commission_Payable__c FROM Offer_Commission__c WHERE Fixed_Amount__c = 10 LIMIT 1];
		System.assertEquals(offerCommissionTestA.Commission_Payable__c, 10);

		offerCommissionGold.Fixed_Amount__c = 20;
		update offerCommissionGold;
		Offer_Commission__c offerCommissionTestB = [SELECT Id, Commission_Payable__c FROM Offer_Commission__c WHERE Fixed_Amount__c = 20 LIMIT 1];
		System.assertEquals(offerCommissionTestB.Commission_Payable__c, 20);
	}


}