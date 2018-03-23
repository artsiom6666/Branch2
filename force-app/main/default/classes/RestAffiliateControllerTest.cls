@isTest
private class RestAffiliateControllerTest {

	@isTest
	static void setAffiliateOfferTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true];
		Account acc = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'TestA@gmail.com', Phone = '1234567890');
		insert acc;

		Offer__c offer = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert offer;

		Map<String, String> generalData = new Map<String, String> {
			'accountId' => acc.Id,
			'offerId' => offer.Id,
			'sub2' => 'Sub Text 2',
			'sub3' => 'Sub Text 3'
		};

		Test.startTest();
			String result;
			result = RestAffiliateController.setAffiliateOffer(generalData);
			System.assertEquals(true, result.contains('success'));

			generalData = new Map<String, String> {
				'accountId' => acc.Id,
				'offerId' => offer.Id,
				'sub1' => 'Sub Text 1',
				'sub5' => 'Sub Text 5'
			};

			result = RestAffiliateController.setAffiliateOffer(generalData);
			System.assertEquals(true, result.contains('success'));
			List<Affiliate_Offer__c> affiliateOffers = [SELECT Id, Sub1__c, Sub2__c, Sub3__c, Sub4__c, Sub5__c FROM Affiliate_Offer__c WHERE Account__c =:acc.Id AND Offer__c =:offer.Id LIMIT 1];
			System.assertEquals(affiliateOffers[0].Sub1__c, 'Sub Text 1');
			System.assertEquals(affiliateOffers[0].Sub2__c, null);
			System.assertEquals(affiliateOffers[0].Sub3__c, null);
			System.assertEquals(affiliateOffers[0].Sub4__c, null);
			System.assertEquals(affiliateOffers[0].Sub5__c, 'Sub Text 5');
			System.assertEquals(affiliateOffers.size(), 1);

			generalData = new Map<String, String> {
				'offerId' => offer.Id
			};

			result = RestAffiliateController.setAffiliateOffer(generalData);
			System.assertEquals(true, result.contains('not found'));

			//Wrong IDs
			generalData = new Map<String, String> {
				'accountId' => acc.Id,
				'offerId' => offer.Id,
				'sub1' => 'Sub Text 1',
				'sub5' => 'Sub Text 5',
				'pixelsIds' => acc.Id
			};
			result = RestAffiliateController.setAffiliateOffer(generalData);
//			System.assertEquals(true, result.contains('Wrong Pixel Id'));

			generalData = new Map<String, String> {
				'accountId' => acc.Id,
				'offerId' => acc.Id,
				'sub1' => 'Sub Text 1',
				'sub5' => 'Sub Text 5'
			};
			result = RestAffiliateController.setAffiliateOffer(generalData);
			System.assertEquals(true, result.contains('Wrong Offer Id'));

			generalData = new Map<String, String> {
				'accountId' => offer.Id,
				'offerId' => offer.Id,
				'sub1' => 'Sub Text 1',
				'sub5' => 'Sub Text 5'
			};
			result = RestAffiliateController.setAffiliateOffer(generalData);
			System.assertEquals(true, result.contains('Wrong Account Id'));

		Test.stopTest();
	}

	@isTest
	static void setAffiliatePayoutTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true];
		Account acc = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'TestA@gmail.com', Phone = '1234567890');
		insert acc;

		Offer__c offer = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert offer;

		Affiliate_Offer__c affiliateOffer = new Affiliate_Offer__c(Account__c = acc.Id, Offer__c = offer.Id);
		insert affiliateOffer;

		Map<String, String> generalData = new Map<String, String> {
			'accountId' => acc.Id,
			'amountToTransfer' => '0.00',
			'payoutType' => 'Card',
			'fullName' => 'Test Test',
			'cardNumber' => '4242424242424242'
		};

		String result;
		result = RestAffiliateController.setAffiliatePayout(generalData);
		System.assertEquals(true, result.contains('success'));

		generalData = new Map<String, String> {
			'accountId' => acc.Id,
			'amountToTransfer' => '0.00',
			'payoutType' => 'PayPal',
			'email' => 'test@test.com'
		};

		result = RestAffiliateController.setAffiliatePayout(generalData);
		System.assertEquals(true, result.contains('success'));

		generalData = new Map<String, String> {
			'accountId' => acc.Id,
			'amountToTransfer' => '10'
		};

		result = RestAffiliateController.setAffiliatePayout(generalData);
		System.assertEquals(true, result.contains('error'));

		generalData = new Map<String, String> {
			'amountToTransfer' => '6'
		};

		result = RestAffiliateController.setAffiliatePayout(generalData);
		System.assertEquals(true, result.contains('not found'));
	}

	@isTest
	static void getAffiliateOffersTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Available_Balance__c = 11.50);
		Account accB = new Account(RecordTypeId = accRT.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Available_Balance__c = 8.50);
		Account accC = new Account(RecordTypeId = accRT.Id, LastName = 'CAccount', FirstName = 'First', PersonEmail = 'testC@gmail.com', Phone = '1234567890', Available_Balance__c = 8.50);
		insert new List<Account> {accA, accB, accC};

		Offer__c offerA = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerC = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert new List<Offer__c> {offerA, offerB, offerC};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 11.50);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerB.Id, Sub1__c = 'Sub21', Commissions_Earned__c = 8.50);
		Affiliate_Offer__c affiliateOfferC = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerC.Id, Sub1__c = 'Sub31', Commissions_Earned__c = 8.50);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB, affiliateOfferC};

		String result;
		result = RestAffiliateController.getAffiliateOffers(new Map<String, String>{'accountId' => accA.Id});
		System.assertEquals(true, result.contains('success'));
		System.assertEquals(true, result.contains('Sub11'));
		System.assertEquals(true, result.contains('Sub21'));
		System.assertEquals(false, result.contains('Sub31'));

		result = RestAffiliateController.getAffiliateOffers(new Map<String, String>{'accountId' => accB.Id});
		System.assertEquals(true, result.contains('success'));
		System.assertEquals(true, result.contains('Sub31'));
		System.assertEquals(false, result.contains('Sub11'));
		System.assertEquals(false, result.contains('Sub21'));

		result = RestAffiliateController.getAffiliateOffers(new Map<String, String>{'accountId' => accC.Id});
		System.assertEquals(true, result.contains('error'));
	}

	@isTest
	static void setAffiliatePixelTest() {
		RecordType recTypeA = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		RecordType recTypeC = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];

		Account accA = new Account(LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', RecordTypeId = recTypeA.Id);
		Account accP = new Account(LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', RecordTypeId = recTypeC.Id);
		insert new List<Account> {accA, accP};

		String result;
		result = RestAffiliateController.setAffiliatePixel(new Map<String, String>{'accountId' => accA.Id, 'pixelName' => 'pixelNameTest1', 'pixelText' => 'pixelTextTest1'});
		System.assertEquals(true, result.contains('success'));

		Pixels__c insertedPixel = [SELECT Id, Name, Account__c, Pixel_Text__c FROM Pixels__c LIMIT 1];
		System.assertEquals(insertedPixel.Name, 'pixelNameTest1');
		System.assertEquals(insertedPixel.Account__c, accA.Id);
		System.assertEquals(insertedPixel.Pixel_Text__c, 'pixelTextTest1');


		result = RestAffiliateController.setAffiliatePixel(new Map<String, String>{'accountId' => accA.Id, 'pixelName' => 'pixelNameTest2', 'pixelText' => 'pixelTextTest2', 'pixelId' => insertedPixel.Id});
		Pixels__c updatedPixel = [SELECT Id, Name, Account__c, Pixel_Text__c FROM Pixels__c LIMIT 1];
		System.assertEquals(updatedPixel.Name, 'pixelNameTest2');
		System.assertEquals(updatedPixel.Account__c, accA.Id);
		System.assertEquals(updatedPixel.Pixel_Text__c, 'pixelTextTest2');

		result = RestAffiliateController.setAffiliatePixel(new Map<String, String>{'accountId' => accP.Id, 'pixelName' => 'pixelNameTest3', 'pixelText' => 'pixelTextTest3', 'pixelId' => insertedPixel.Id});
		System.assertEquals(true, result.contains('Affiliate Account was not found'));

		result = RestAffiliateController.setAffiliatePixel(new Map<String, String>{'accountId' => accA.Id, 'pixelName' => 'pixelNameTest4', 'pixelId' => insertedPixel.Id});
		System.assertEquals(true, result.contains('Pixel Text was not found'));

		result = RestAffiliateController.setAffiliatePixel(new Map<String, String>{'accountId' => accA.Id, 'pixelText' => 'pixelTextTest5', 'pixelId' => insertedPixel.Id});
		System.assertEquals(true, result.contains('Pixel Name was not found'));

		result = RestAffiliateController.setAffiliatePixel(new Map<String, String>{'pixelName' => 'pixelNameTest3', 'pixelText' => 'pixelTextTest3', 'pixelId' => insertedPixel.Id});
		System.assertEquals(true, result.contains('Account Id was not found'));

	}

	@isTest
	static void setAffiliateOfferLinkTest() {
		RecordType recTypeA = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		RecordType recTypeP = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];

		Account accA = new Account(LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', RecordTypeId = recTypeA.Id);
		Account accB = new Account(LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', RecordTypeId = recTypeP.Id);
		insert new List<Account> {accA, accB};

		Offer__c offerA = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerC = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert new List<Offer__c> {offerA, offerB, offerC};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 11.50);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerB.Id, Sub1__c = 'Sub21', Commissions_Earned__c = 8.50);
		Affiliate_Offer__c affiliateOfferC = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerC.Id, Sub1__c = 'Sub31', Commissions_Earned__c = 8.50);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB, affiliateOfferC};

		String result;
		result = RestAffiliateController.setAffiliateOfferLink(new Map<String, String>{'affiliateOfferId' => affiliateOfferA.Id, 'name' => 'test'});
		System.assertEquals(true, result.contains('success'));

		Affiliate_Offer_Link__c link = [SELECT Id FROM Affiliate_Offer_Link__c WHERE Affiliate_Offer__c =:affiliateOfferA.Id LIMIT 1];

		result = RestAffiliateController.setAffiliateOfferLink(new Map<String, String>{'affiliateOfferLinkId' => link.Id, 'name' => 'test'});
		System.assertEquals(true, result.contains('success'));

		result = RestAffiliateController.setAffiliateOfferLink(new Map<String, String>{'affiliateOfferLinkId' => link.Id});
		System.assertEquals(true, result.contains('Name was not found'));

	}

	@isTest
	static void getAffiliateOfferTest() {
		RecordType recTypeA = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Affiliate_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		RecordType recTypeP = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true AND IsActive = true LIMIT 1];

		Account accA = new Account(LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', RecordTypeId = recTypeA.Id);
		Account accB = new Account(LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', RecordTypeId = recTypeP.Id);
		insert new List<Account> {accA, accB};

		Offer__c offerA = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		Offer__c offerC = new Offer__c(Commission_Payable__c = 1, Active__c = true);
		insert new List<Offer__c> {offerA, offerB, offerC};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Sub1__c = 'Sub11', Commissions_Earned__c = 11.50);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerB.Id, Sub1__c = 'Sub21', Commissions_Earned__c = 8.50);
		Affiliate_Offer__c affiliateOfferC = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerC.Id, Sub1__c = 'Sub31', Commissions_Earned__c = 8.50);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB, affiliateOfferC};

		String result;

		result = RestAffiliateController.setAffiliateOfferLink(new Map<String, String>{'affiliateOfferId' => affiliateOfferA.Id, 'name' => 'test'});
		System.assertEquals(true, result.contains('success'));

		result = RestAffiliateController.getAffiliateOffer(new Map<String, String>{'affiliateOfferId' => affiliateOfferA.Id});
		System.assertEquals(true, result.contains('success'));

		result = RestAffiliateController.getAffiliateOffer(new Map<String, String>{'affiliateOfferId' => affiliateOfferA.Id+'123'});
		System.assertEquals(true, result.contains('error'));
	}


	@isTest
	static void getPixelsTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890', Affiliate_Approval__c = 'Frozen');
		Account accB = new Account(RecordTypeId = accRT.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890', Affiliate_Approval__c = 'Approved');
		Account accC = new Account(RecordTypeId = accRT.Id, LastName = 'CAccount', FirstName = 'First', PersonEmail = 'testC@gmail.com', Phone = '1234567890');
		insert new List<Account> {accA, accB, accC};

		Pixels__c pixelA = new Pixels__c (Name = 'PixelNameA', Account__c = accA.Id, Pixel_Text__c = 'PixelAText');
		Pixels__c pixelB = new Pixels__c (Name = 'PixelNameB', Account__c = accA.Id, Pixel_Text__c = 'PixelBText');
		Pixels__c pixelC = new Pixels__c (Name = 'PixelNameC', Account__c = accB.Id, Pixel_Text__c = 'PixelCText');
		insert new List<Pixels__c> {pixelA, pixelB, pixelC};

		String result;
		result = RestAffiliateController.getPixels(new Map<String, String>{'accountId' => accA.Id});
		System.assertEquals(true, result.contains('PixelAText'));
		System.assertEquals(true, result.contains('PixelBText'));
		System.assertEquals(false, result.contains('PixelCText'));
		System.assertEquals(true, result.contains('Frozen'));
		System.assertEquals(false, result.contains('Approved'));


		result = RestAffiliateController.getPixels(new Map<String, String>{'accountId' => accB.Id});
		System.assertEquals(true, result.contains('PixelCText'));
		System.assertEquals(false, result.contains('PixelBText'));
		System.assertEquals(false, result.contains('PixelAText'));
		System.assertEquals(true, result.contains('Approved'));
		System.assertEquals(false, result.contains('Frozen'));

		result = RestAffiliateController.getPixels(new Map<String, String>{'accountId' => accC.Id});
		System.assertEquals(true, result.contains('not found'));

		result = RestAffiliateController.getPixels(new Map<String, String>{'accountId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));


		Offer__c offerA = new Offer__c(Commission_Payable__c = 101, Active__c = true);
		insert offerA;
		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Commissions_Earned_for_Withdrawal__c = 101);
		insert affiliateOfferA;
		Affiliate_Offer_Pixels__c aOfferPixel = new Affiliate_Offer_Pixels__c (Affiliate_Offer__c = affiliateOfferA.Id, Pixels__c = pixelA.id);
		insert aOfferPixel;

		result = RestAffiliateController.getPixels(new Map<String, String>{'accountId' => accA.Id, 'offerId' => offerA.Id});
		System.assertEquals(true, result.contains('PixelAText'));
		System.assertEquals(false, result.contains('PixelBText'));
		System.assertEquals(false, result.contains('PixelCText'));
	}


	@isTest
	static void getDeletePixelTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		insert accA;

		Pixels__c pixelA = new Pixels__c (Name = 'PixelNameA', Account__c = accA.Id, Pixel_Text__c = 'PixelAText');
		Pixels__c pixelB = new Pixels__c (Name = 'PixelNameB', Account__c = accA.Id, Pixel_Text__c = 'PixelBText');
		insert new List<Pixels__c> {pixelA, pixelB};

		String result;
		result = RestAffiliateController.getPixel(new Map<String, String>{'pixelId' => pixelA.Id});
		System.assertEquals(true, result.contains('PixelAText'));
		System.assertEquals(false, result.contains('PixelBText'));

		result = RestAffiliateController.getPixel(new Map<String, String>{'pixelId' => pixelB.Id});
		System.assertEquals(true, result.contains('PixelBText'));
		System.assertEquals(false, result.contains('PixelAText'));

		result = RestAffiliateController.getPixel(new Map<String, String>{'pixelId' => 'a0Z4100000OY7Cp'});
		System.assertEquals(true, result.contains('not found'));

		result = RestAffiliateController.getPixel(new Map<String, String>{'pixelId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));

		//delete
		result = RestAffiliateController.deletePixel(new Map<String, String>{'pixelId' => pixelA.Id});
		System.assertEquals(1, [SELECT COUNT() FROM Pixels__c]);

		result = RestAffiliateController.deletePixel(new Map<String, String>{'pixelId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));

	}

	@isTest
	static void getPayoutsTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		Account accB = new Account(RecordTypeId = accRT.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890');
		Account accC = new Account(RecordTypeId = accRT.Id, LastName = 'CAccount', FirstName = 'First', PersonEmail = 'testC@gmail.com', Phone = '1234567890');
		insert new List<Account> {accA, accB, accC};

		//logic depends on the trigger on the object Payouts__c
		Offer__c offerA = new Offer__c(Commission_Payable__c = 101, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 202, Active__c = true);
		insert new List<Offer__c> {offerA, offerB};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Commissions_Earned_for_Withdrawal__c = 101);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerB.Id, Commissions_Earned_for_Withdrawal__c = 202);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB};

		Payouts__c payoutA = new Payouts__c (Account__c = accA.Id, Amount_Transferred__c = 101, Status__c = 'Waiting For Approval');
		Payouts__c payoutB = new Payouts__c (Account__c = accB.Id, Amount_Transferred__c = 202, Status__c = 'Waiting For Approval');
		insert new List<Payouts__c> {payoutA, payoutB};

		String result;
		result = RestAffiliateController.getPayouts(new Map<String, String>{'accountId' => accA.Id});
		System.assertEquals(true, result.contains('101'));
		System.assertEquals(false, result.contains('202'));

		result = RestAffiliateController.getPayouts(new Map<String, String>{'accountId' => accB.Id});
		System.assertEquals(true, result.contains('202'));
		System.assertEquals(false, result.contains('101'));

		result = RestAffiliateController.getPayouts(new Map<String, String>{'accountId' => accC.Id});
		System.assertEquals(true, result.contains('not found'));

		result = RestAffiliateController.getPayouts(new Map<String, String>{'accountId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));

	}

	@isTest
	static void getPayoutAndCommissionsEarnedTest() {
		RecordType accRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1];
		Account accA = new Account(RecordTypeId = accRT.Id, LastName = 'AAccount', FirstName = 'First', PersonEmail = 'testA@gmail.com', Phone = '1234567890');
		Account accB = new Account(RecordTypeId = accRT.Id, LastName = 'BAccount', FirstName = 'First', PersonEmail = 'testB@gmail.com', Phone = '1234567890');
		insert new List<Account> {accA, accB};

		//logic depends on the trigger on the object Payouts__c
		Offer__c offerA = new Offer__c(Commission_Payable__c = 101, Active__c = true);
		Offer__c offerB = new Offer__c(Commission_Payable__c = 202, Active__c = true);
		insert new List<Offer__c> {offerA, offerB};

		Affiliate_Offer__c affiliateOfferA = new Affiliate_Offer__c(Account__c = accA.Id, Offer__c = offerA.Id, Commissions_Earned_for_Withdrawal__c = 101);
		Affiliate_Offer__c affiliateOfferB = new Affiliate_Offer__c(Account__c = accB.Id, Offer__c = offerB.Id, Commissions_Earned_for_Withdrawal__c = 202);
		insert new List<Affiliate_Offer__c> {affiliateOfferA, affiliateOfferB};

		Payouts__c payoutA = new Payouts__c (Account__c = accA.Id, Amount_Transferred__c = 101, Status__c = 'Waiting For Approval');
		Payouts__c payoutB = new Payouts__c (Account__c = accB.Id, Amount_Transferred__c = 202, Status__c = 'Waiting For Approval');
		insert new List<Payouts__c> {payoutA, payoutB};

		Commissions_Earned__c commissionsA = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerA.Id, Commission_Earned__c = 50, Status__c = 'Not Available for Withdrawal', Payouts__c = payoutA.Id);
		Commissions_Earned__c commissionsB = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferA.id, Offer__c = offerA.Id, Commission_Earned__c = 51, Status__c = 'Not Available for Withdrawal', Payouts__c = payoutA.Id);
		Commissions_Earned__c commissionsC = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferB.id, Offer__c = offerB.Id, Commission_Earned__c = 62, Status__c = 'Not Available for Withdrawal', Payouts__c = payoutB.Id);
		Commissions_Earned__c commissionsD = new Commissions_Earned__c(Affiliate_Offer__c = affiliateOfferB.id, Offer__c = offerB.Id, Commission_Earned__c = 140, Status__c = 'Not Available for Withdrawal', Payouts__c = payoutB.Id);
		insert new List<Commissions_Earned__c> {commissionsA, commissionsB, commissionsC, commissionsD};

		String result;
		result = RestAffiliateController.getPayout(new Map<String, String>{'payoutId' => payoutA.Id});
		System.assertEquals(true, result.contains('101'));
		System.assertEquals(true, result.contains('50'));
		System.assertEquals(true, result.contains('51'));
		System.assertEquals(false, result.contains('202'));

		result = RestAffiliateController.getPayout(new Map<String, String>{'payoutId' => payoutB.Id});
		System.assertEquals(true, result.contains('202'));
		System.assertEquals(true, result.contains('62'));
		System.assertEquals(true, result.contains('140'));
		System.assertEquals(false, result.contains('101'));

		result = RestAffiliateController.getPayout(new Map<String, String>{'payoutId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));

		result = RestAffiliateController.getCommissionsEarned(new Map<String, String>{'accountId' => accA.Id});
		System.assertEquals(true, result.contains('50'));
		System.assertEquals(true, result.contains('51'));

		result = RestAffiliateController.getCommissionsEarned(new Map<String, String>{'accountId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));
	}

	@isTest
	static void getDeleteAffiliateOfferLinkTest() {
		Affiliate_Offer_Link__c aOfferLinkA = new Affiliate_Offer_Link__c(Name = 'LinkA', Sub1__c = 'SubA1', Sub2__c = 'SubA2', Sub3__c = 'SubA3', Sub4__c = 'SubA4', Sub5__c = 'SubA5',
																		Utm_Campaign__c = 'UTMACa', Utm_Content__c = 'UTMACo', Utm_Medium__c = 'UTMAMe', Utm_Source__c = 'UTMASo', Utm_Term__c = 'UTMATe');
		Affiliate_Offer_Link__c aOfferLinkB = new Affiliate_Offer_Link__c(Name = 'LinkB', Sub1__c = 'SubB1', Sub2__c = 'SubB2', Sub3__c = 'SubB3', Sub4__c = 'SubB4', Sub5__c = 'SubB5',
																		Utm_Campaign__c = 'UTMBCa', Utm_Content__c = 'UTMBCo', Utm_Medium__c = 'UTMBMe', Utm_Source__c = 'UTMBSo', Utm_Term__c = 'UTMBTe');

		insert new List<Affiliate_Offer_Link__c> {aOfferLinkA, aOfferLinkB};

		String result;

		result = RestAffiliateController.getAffiliateOfferLink(new Map<String, String>{'affiliateOfferLinkId' => aOfferLinkA.Id});
		System.assertEquals(true, result.contains('LinkA'));
		System.assertEquals(true, result.contains('UTMACa'));
		System.assertEquals(true, result.contains('UTMATe'));
		System.assertEquals(false, result.contains('LinkB'));

		result = RestAffiliateController.getAffiliateOfferLink(new Map<String, String>{'affiliateOfferLinkId' => aOfferLinkB.Id});
		System.assertEquals(true, result.contains('success'));
		System.assertEquals(true, result.contains('LinkB'));
		System.assertEquals(true, result.contains('UTMBCa'));
		System.assertEquals(true, result.contains('UTMBTe'));
		System.assertEquals(false, result.contains('LinkA'));

		result = RestAffiliateController.getAffiliateOfferLink(new Map<String, String>{'affiliateOfferLinkId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));

		//delete
		result = RestAffiliateController.deleteAffiliateOfferLink(new Map<String, String>{'affiliateOfferLinkId' => aOfferLinkA.Id});
		System.assertEquals(1, [SELECT COUNT() FROM Affiliate_Offer_Link__c]);

		result = RestAffiliateController.deleteAffiliateOfferLink(new Map<String, String>{'affiliateOfferLinkId' => 'InvalidId'});
		System.assertEquals(true, result.contains('error'));

	}


}