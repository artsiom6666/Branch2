@isTest
private class OfferTriggerTest {

	//OfferTrigger Test
	@isTest static void testCommissionPayable() {

		RecordType recordTypeItem = [SELECT Id FROM RecordType WHERE DeveloperName = 'Cart' LIMIT 1];

		Product2 iceCreamProduct = new Product2(Name = 'iceCreamProduct', ProductCode = 'iceCreamProductCode', IsActive = true );
		Product2 hotCreamProduct = new Product2(Name = 'hotCreamProduct', ProductCode = 'hotCreamProductCode', IsActive = true );
		insert new List<Product2> {iceCreamProduct, hotCreamProduct};

		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 pricebook2StandardName = new Pricebook2(Name = 'Standard Price Book', IsActive = true);
		insert pricebook2StandardName;

		PricebookEntry bookEntryA = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = pricebookId);
		PricebookEntry bookEntryB = new PricebookEntry (Product2Id = iceCreamProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = pricebook2StandardName.Id);

		PricebookEntry bookEntryC = new PricebookEntry (Product2Id = hotCreamProduct.Id, UnitPrice = 200, IsActive = true, Pricebook2Id = pricebookId);
		PricebookEntry bookEntryD = new PricebookEntry (Product2Id = hotCreamProduct.Id, UnitPrice = 200, IsActive = true, Pricebook2Id = pricebook2StandardName.Id);
		insert new List<PricebookEntry> {bookEntryA, bookEntryB, bookEntryC, bookEntryD};

		Offer__c offerA = new Offer__c(Active__c = false, Offer_Name__c = 'offerA', Commission_Payable__c = 10, Percent_Of_Price__c = 20, Product__c = iceCreamProduct.Id, RecordTypeId = recordTypeItem.Id);
		Offer__c offerB = new Offer__c(Active__c = false, Offer_Name__c = 'offerB', Commission_Payable__c = 10, Product__c = hotCreamProduct.Id, RecordTypeId = recordTypeItem.Id);
		insert new List<Offer__c> {offerA, offerB};

		offerA.Active__c = true;
		update new List<Offer__c> {offerA, offerB};

		Offer__c testOfferA = [SELECT Id, Commission_Payable__c FROM Offer__c WHERE Offer_Name__c = 'offerA' LIMIT 1];
		System.assertEquals(20, testOfferA.Commission_Payable__c);
		Offer__c testOfferB = [SELECT Id, Commission_Payable__c FROM Offer__c WHERE Offer_Name__c = 'offerB' LIMIT 1];
		System.assertEquals(10, testOfferB.Commission_Payable__c);
	}

}