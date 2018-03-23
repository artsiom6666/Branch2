public with sharing class RestAffiliateController {

	public static String setAffiliateOffer(Map<String, String> generalData) {
		try {
			Id accountId = generalData.containsKey('accountId') ? Id.valueOf(generalData.get('accountId')) : null;
			Id offerId = generalData.containsKey('offerId') ? Id.valueOf(generalData.get('offerId')) : null;
			String pixelsIds = generalData.containsKey('pixelsIds') ? String.valueOf(generalData.get('pixelsIds')) : null;
			String baseUrl = generalData.containsKey('baseurl') ? String.valueOf(generalData.get('baseurl')) : null;
			String token = generalData.containsKey('token') ? String.valueOf(generalData.get('token')) : null;
			String sub1 = generalData.containsKey('sub1') ? String.valueOf(generalData.get('sub1')) : null;
			String sub2 = generalData.containsKey('sub2') ? String.valueOf(generalData.get('sub2')) : null;
			String sub3 = generalData.containsKey('sub3') ? String.valueOf(generalData.get('sub3')) : null;
			String sub4 = generalData.containsKey('sub4') ? String.valueOf(generalData.get('sub4')) : null;
			String sub5 = generalData.containsKey('sub5') ? String.valueOf(generalData.get('sub5')) : null;

			//verification of input data
			if (accountId == null || offerId == null) { return '{"error":"Account Id or Offer Id was not found","message":"error"}'; }

			List<Account> verifyAccounts = [SELECT Id FROM Account WHERE Id =:accountId LIMIT 1];
			List<Offer__c> verifyOffers = [SELECT Id FROM Offer__c WHERE Id =:offerId LIMIT 1];
			if (verifyAccounts.isEmpty()) { return '{"error":"Wrong Account Id","message":"error"}'; }
			if (verifyOffers.isEmpty()) { return '{"error":"Wrong Offer Id","message":"error"}'; }

			List<Affiliate_Offer__c> affiliateOffersToUpdate = [SELECT Id FROM Affiliate_Offer__c WHERE Account__c =:accountId AND Offer__c =:offerId LIMIT 1];

			Affiliate_Offer__c affiliateOfferToUpdate = new Affiliate_Offer__c();

			if (!affiliateOffersToUpdate.isEmpty()) {
				affiliateOfferToUpdate.Id = affiliateOffersToUpdate[0].Id;
			} else {
				affiliateOfferToUpdate.Account__c = accountId;
				affiliateOfferToUpdate.Offer__c = offerId;              
			}

			affiliateOfferToUpdate.Base_URL__c = baseUrl;
			affiliateOfferToUpdate.Token__c = token;
			affiliateOfferToUpdate.Sub1__c = sub1;
			affiliateOfferToUpdate.Sub2__c = sub2;
			affiliateOfferToUpdate.Sub3__c = sub3;
			affiliateOfferToUpdate.Sub4__c = sub4;
			affiliateOfferToUpdate.Sub5__c = sub5;

			try {
				SFDCAccessController.UpsertWithoutSharing (
					affiliateOfferToUpdate,
					'RestAffiliateController.cls [setAffiliateOffer]',
					new List<Schema.DescribeFieldResult>{
						Affiliate_Offer__c.Account__c.getDescribe(), Affiliate_Offer__c.Offer__c.getDescribe(),
						Affiliate_Offer__c.Base_URL__c.getDescribe(), Affiliate_Offer__c.Token__c.getDescribe(),
						Affiliate_Offer__c.Sub1__c.getDescribe(), Affiliate_Offer__c.Sub2__c.getDescribe(),
						Affiliate_Offer__c.Sub3__c.getDescribe(), Affiliate_Offer__c.Sub4__c.getDescribe(),
						Affiliate_Offer__c.Sub5__c.getDescribe()

					}
				);
			} catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }

//			if (pixelsIds != null && pixelsIds != '') {
				List<Id> pixelsList = pixelsIds != null && pixelsIds != '' ? pixelsIds.split(',') : new List<Id>();

//				List<Pixels__c> verifyPixels = [SELECT Id FROM Pixels__c WHERE Id IN :pixelsList];
//				if (verifyPixels.isEmpty()) { return '{"error":"Wrong Pixel Id","message":"error"}'; }

				Set<Id> pixelsSet = pixelsList.isEmpty() ? new Set<Id>() : new Set<Id>(pixelsList);
				Map<Id, Affiliate_Offer_Pixels__c> affiliateOfferPixelsMap = new Map<Id, Affiliate_Offer_Pixels__c>([
					SELECT Id, Pixels__c, Affiliate_Offer__c
					FROM Affiliate_Offer_Pixels__c
					WHERE Affiliate_Offer__c = :affiliateOfferToUpdate.Id
				]);

				for (Affiliate_Offer_Pixels__c item : affiliateOfferPixelsMap.values()) {
					if (pixelsSet.contains(item.Pixels__c)) {
						affiliateOfferPixelsMap.remove(item.Id);
						pixelsSet.remove(item.Pixels__c);
					}
				}

				List<Affiliate_Offer_Pixels__c> affiliateOfferPixelsListNew = new List<Affiliate_Offer_Pixels__c>();
				for (Id item : pixelsSet) {
					affiliateOfferPixelsListNew.add(
						new Affiliate_Offer_Pixels__c(
							Pixels__c = item,
							Affiliate_Offer__c = affiliateOfferToUpdate.Id
						)
					);
				}

				try {
					if (!affiliateOfferPixelsListNew.isEmpty()) {
						SFDCAccessController.InsertWithoutSharing (
							affiliateOfferPixelsListNew,
							'RestAffiliateController.cls [setAffiliateOffer]',
							new List<Schema.DescribeFieldResult> {
								Affiliate_Offer_Pixels__c.Pixels__c.getDescribe(), Affiliate_Offer_Pixels__c.Affiliate_Offer__c.getDescribe()
							}
						);
					}

					List<Affiliate_Offer_Pixels__c> deletePixels = affiliateOfferPixelsMap.values();
					if (!deletePixels.isEmpty()) {
						SFDCAccessController.DeleteWithoutSharing (
							deletePixels,
							'RestAffiliateController.cls [setAffiliateOffer]'
						);
					}
				} catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }

//			}

			return '{"affiliateOfferId":"' + String.valueOf(affiliateOfferToUpdate.Id) + '","message":"success"}';

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String getAffiliateOffers(Map<String, String> params) {
		try {
			Id accountId = params.containsKey('accountId') ? Id.valueOf(params.get('accountId')) : null;
			//verification of input data
			if (accountId == null ) { return '{"error":"Account Id was not found","message":"error"}'; }

			List<Account> verifyAccounts = [SELECT Id FROM Account WHERE Id =:accountId LIMIT 1];

			if (verifyAccounts.isEmpty()) { return '{"error":"Account or Offer was not found","message":"error"}'; }

			List<Affiliate_Offer__c> affiliateOffers = [
				SELECT Id, Sub1__c, Sub2__c, Sub3__c, Sub4__c, Sub5__c, Account__c, Base_URL__c, Commissions_Earned__c, Offer__c, Token__c, Commissions_Earned_for_Withdrawal__c
				FROM Affiliate_Offer__c 
				WHERE Account__c =:accountId LIMIT 9999
			];

			Map<Id,List<Id>> pixelsMap = new Map<Id,List<Id>>();

			List<Affiliate_Offer_Pixels__c> affiliateOfferPixelsList = [
				SELECT Id, Pixels__c, Affiliate_Offer__c
				FROM Affiliate_Offer_Pixels__c
				WHERE Affiliate_Offer__r.Account__c = :accountId
			];

			for (Affiliate_Offer_Pixels__c item : affiliateOfferPixelsList) {
				List<Id> pixelList = pixelsMap.get(item.Affiliate_Offer__c) != NULL ? pixelsMap.get(item.Affiliate_Offer__c) : new List<Id>();
				pixelList.add(item.Pixels__c);
				pixelsMap.put(item.Affiliate_Offer__c, pixelList);
			}

			List<Map<String, Object>> result = new List<Map<String, Object>>();
			for (Affiliate_Offer__c item : affiliateOffers) {
				result.add(new Map<String, Object>{
					'accountId' => item.Account__c,
					'affiliateOfferId' => item.Id,
					'baseUrl' => item.Base_URL__c,
					'commissionsEarned' => String.valueOf(item.Commissions_Earned__c),
					'CommissionsEarnedForWithdrawal' => String.valueOf(item.Commissions_Earned_for_Withdrawal__c),
					'offerId' => item.Offer__c,
					'pixelsIds' => pixelsMap.get(item.Id) != NULL ? pixelsMap.get(item.Id) : new List<Id>(),
					'sub1' => item.Sub1__c,
					'sub2' => item.Sub2__c,
					'sub3' => item.Sub3__c,
					'sub4' => item.Sub4__c,
					'sub5' => item.Sub5__c,
					'token' => item.Token__c
				});
			}

			if (result.isEmpty()) {
				return '{"error":"affiliate Offers are not found","message":"error"}';
			}
			return JSON.serialize(new Map<String, Object>{
				'affiliateOffers' => result,
				'message' => 'success'
			});

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String getAffiliateOffer(Map<String, String> params) {
		try {
			Id affiliateOfferId = params.containsKey('affiliateOfferId') ? Id.valueOf(params.get('affiliateOfferId')) : null;
			Id accountId = params.containsKey('accountId') ? Id.valueOf(params.get('accountId')) : null;
			Id offerId = params.containsKey('offerId') ? Id.valueOf(params.get('offerId')) : null;
			//verification of input data
			if (affiliateOfferId == null && accountId == null && offerId == null) { return '{"error":"Affiliate Offer Id was not found","message":"error"}'; }

			List<Affiliate_Offer__c> affiliateOffers = new List<Affiliate_Offer__c>();
			if (affiliateOfferId != null) {
				affiliateOffers = [
					SELECT Id, Account__c, Base_URL__c, Commissions_Earned__c, Offer__c, Token__c, Commissions_Earned_for_Withdrawal__c
					FROM Affiliate_Offer__c 
					WHERE Id =:affiliateOfferId
					LIMIT 1
				];
			}
			else if (accountId != null && offerId != null) {
				affiliateOffers = [
					SELECT Id, Account__c, Base_URL__c, Commissions_Earned__c, Offer__c, Token__c, Commissions_Earned_for_Withdrawal__c
					FROM Affiliate_Offer__c 
					WHERE Account__c = :accountId
					AND Offer__c = :offerId
					LIMIT 1
				];
			}

			if (affiliateOffers.isEmpty()) { return '{"error":"Affiliate Offer was not found","message":"error"}'; }

			affiliateOfferId = affiliateOffers[0].Id;

			List<Affiliate_Offer_Pixels__c> affiliateOfferPixelsList = [
				SELECT Id, Pixels__c
				FROM Affiliate_Offer_Pixels__c
				WHERE Affiliate_Offer__c = :affiliateOfferId
			];

			List<Id> pixelsList = new List<Id>();
			for (Affiliate_Offer_Pixels__c item : affiliateOfferPixelsList) {
				pixelsList.add(item.Pixels__c);
			}

			List<Affiliate_Offer_Link__c> affiliateOfferList = [
				SELECT Id, Name, Sub1__c, Sub2__c, Sub3__c, Sub4__c, Sub5__c, Utm_Campaign__c, Utm_Content__c, Utm_Medium__c, Utm_Source__c, Utm_Term__c, CreatedDate
				FROM Affiliate_Offer_Link__c
				WHERE Affiliate_Offer__c = :affiliateOfferId
				ORDER BY Name ASC
			];

			List<Map<String, Object>> links = new List<Map<String, Object>>();
			for (Affiliate_Offer_Link__c item : affiliateOfferList) {
				links.add(
					new Map<String, Object> {
						'affiliateOfferLinkId' => item.Id,
						'createdDate' => item.CreatedDate,
						'name' => item.Name,
						'sub1' => item.Sub1__c,
						'sub2' => item.Sub2__c,
						'sub3' => item.Sub3__c,
						'sub4' => item.Sub4__c,
						'sub5' => item.Sub5__c,
						'utmCampaign' => item.Utm_Campaign__c,
						'utmContent' => item.Utm_Content__c,
						'utmMedium' => item.Utm_Medium__c,
						'utmSource' => item.Utm_Source__c,
						'utmTerm' => item.Utm_Term__c
					}
				);
			}

			List<Commissions_Earned__c> commissionsEarnedList = [
				SELECT Id, Name, Affiliate_Offer__c, Commission_Earned__c, Offer__c, Order__c, Paid__c, Payouts__c, Payout_Date__c, Price__c, Product__c, Status__c, 
					Type__c, CreatedDate
				FROM Commissions_Earned__c
				WHERE Affiliate_Offer__c = :affiliateOfferId AND Type__c = 'Sales'
				ORDER BY CreatedDate DESC
			];

			List<Map<String, Object>> commissions = new List<Map<String, Object>>();
			for (Commissions_Earned__c item : commissionsEarnedList) {
				commissions.add(
					new Map<String, Object> {
						'id' => item.Id,
						'name' => item.Name,
						'affiliateOfferId' => item.Affiliate_Offer__c,
						'commissionEarned' => item.Commission_Earned__c,
						'OfferId' => item.Offer__c,
						'OrderId' => item.Order__c,
						'Paid' => item.Paid__c,
						'PayoutId' => item.Payouts__c,
						'PayoutDate' => item.Payout_Date__c,
						'Price' => item.Price__c,
						'ProductId' => item.Product__c,
						'Status' => item.Status__c,
						'Type' => item.Type__c,
						'createdDate' => item.CreatedDate
					}
				);
			}

			Map<String, Object> result = new Map<String, Object>();
			for (Affiliate_Offer__c item : affiliateOffers) {
				result = new Map<String, Object>{
					'accountId' => item.Account__c,
					'affiliateOfferId' => item.Id,
					'baseUrl' => item.Base_URL__c,
					'commissionsEarnedTotal' => String.valueOf(item.Commissions_Earned__c),
					'CommissionsEarnedForWithdrawal' => String.valueOf(item.Commissions_Earned_for_Withdrawal__c),
					'offerId' => item.Offer__c,
					'pixelsIds' => pixelsList,
					'AffiliateOfferLinks' => links,
					'commissionsEarned' => commissions
				};
			}

			if (result.isEmpty()) {
				return '{"error":"affiliate Offers are not found","message":"error"}';
			}
			return JSON.serialize(new Map<String, Object>{
				'affiliateOffer' => result,
				'message' => 'success'
			});

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String setAffiliatePayout(Map<String, String> generalData) {
		try {
			Id accountId = generalData.containsKey('accountId') ? Id.valueOf(generalData.get('accountId')) : null;
			Decimal amountToTransfer = generalData.containsKey('amountToTransfer') ? Decimal.valueOf(generalData.get('amountToTransfer')) : null;
			Decimal cardNumber = generalData.containsKey('cardNumber') && !String.isBlank(generalData.get('cardNumber')) ? Decimal.valueOf(generalData.get('cardNumber')) : null;
			String email = generalData.containsKey('email') && !String.isBlank(generalData.get('email')) ? String.valueOf(generalData.get('email')) : null;
			String fullName = generalData.containsKey('fullName') && !String.isBlank(generalData.get('fullName')) ? String.valueOf(generalData.get('fullName')) : null;
			String payoutType = generalData.containsKey('payoutType') && !String.isBlank(generalData.get('payoutType')) ? String.valueOf(generalData.get('payoutType')) : null;

			if (accountId == null || payoutType == null) { return '{"error":"Payout Type or Account Id was not found","message":"error"}'; }
			
			List<Payout_Mechanisms__c> payoutMechanismList = new List<Payout_Mechanisms__c>();
			if (payoutType == 'PayPal') {
				payoutMechanismList = [
					SELECT Id, Account__c, Email__c, Type__c
					FROM Payout_Mechanisms__c
					WHERE Account__c = :accountId AND Email__c = :email
				];
			}
			else if (payoutType == 'Card') {
				payoutMechanismList = [
					SELECT Id, Account__c, Card_Number__c, Full_Name__c, Type__c
					FROM Payout_Mechanisms__c
					WHERE Account__c = :accountId AND Card_Number__c = :cardNumber AND Full_Name__c = :fullName
				];
			}

			List<RecordType> recordTypeList = [
				SELECT Id, Name
				FROM RecordType
				WHERE SobjectType = 'TouchCRBase__Payout_Mechanisms__c'
			];
			Map<String,Id> recordTypeMap = new Map<String,Id>();
			for (RecordType item : recordTypeList) {
				recordTypeMap.put(item.Name, item.Id);
			}

			if (payoutMechanismList.isEmpty() && payoutType == 'PayPal' && email == null) { return '{"error":"Email was not found","message":"error"}'; } 
			if (payoutMechanismList.isEmpty() && payoutType == 'Card' && (fullName == null ||  cardNumber == null)) { return '{"error":"fullName or cardNumber was not found","message":"error"}'; } 

			Payout_Mechanisms__c payoutMechanism = new Payout_Mechanisms__c();
			if (!payoutMechanismList.isEmpty()) {
				payoutMechanism = payoutMechanismList[0];
			}
			else if (payoutMechanismList.isEmpty() && payoutType == 'PayPal')  {
				payoutMechanism.RecordTypeId = recordTypeMap.get(payoutType) != NULL ? recordTypeMap.get(payoutType) : NULL;
				payoutMechanism.Email__c = email;
				payoutMechanism.Account__c = accountId;
				payoutMechanism.Type__c = payoutType;
			}
			else if (payoutMechanismList.isEmpty() && payoutType == 'Card') {
				payoutMechanism.RecordTypeId = recordTypeMap.get(payoutType) != NULL ? recordTypeMap.get(payoutType) : NULL;
				payoutMechanism.Full_Name__c = fullName;
				payoutMechanism.Card_Number__c = cardNumber;
				payoutMechanism.Account__c = accountId;
				payoutMechanism.Type__c = payoutType;
			}

			if (payoutMechanism.Id == NULL) {
				try {
					SFDCAccessController.InsertWithoutSharing (
						payoutMechanism,
						'RestAffiliateController.cls [setAffiliatePayout]',
						new List<Schema.DescribeFieldResult> {
							Payout_Mechanisms__c.RecordTypeId.getDescribe(), Payout_Mechanisms__c.Email__c.getDescribe(),
							Payout_Mechanisms__c.Account__c.getDescribe(), Payout_Mechanisms__c.Type__c.getDescribe(),
							Payout_Mechanisms__c.Full_Name__c.getDescribe(), Payout_Mechanisms__c.Card_Number__c.getDescribe()
						}
					);
				} catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }
			}

			if (accountId == null || amountToTransfer == null) { return '{"error":"Amount to Transfer or Account Id was not found","message":"error"}'; }

			Payouts__c payout = new Payouts__c (Account__c = accountId, Amount_Transferred__c = amountToTransfer, Status__c = 'Waiting For Approval', Payout_Mechanisms__c = payoutMechanism.Id);

			try {
				SFDCAccessController.InsertWithoutSharing (
					payout,
					'RestAffiliateController.cls [setAffiliatePayout]',
					new List<Schema.DescribeFieldResult> {
						Payouts__c.Account__c.getDescribe(), Payouts__c.Amount_Transferred__c.getDescribe(),
						Payouts__c.Status__c.getDescribe(), Payouts__c.Payout_Mechanisms__c.getDescribe()
					}
				);
			} catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }



			return '{"payoutId":"' + String.valueOf(payout.id) + '","message":"success"}';

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String setAffiliatePixel(Map<String, String> generalData) {
		try {
			Id accountId = generalData.containsKey('accountId') ? Id.valueOf(generalData.get('accountId')) : null;
			Id pixelId = generalData.containsKey('pixelId') ? Id.valueOf(generalData.get('pixelId')) : null;
			String pixelName = generalData.containsKey('pixelName') ? String.valueOf(generalData.get('pixelName')) : null;
			String pixelText = generalData.containsKey('pixelText') ? String.valueOf(generalData.get('pixelText')) : null;

			if (accountId == null) { return '{"error":"Account Id was not found","message":"error"}'; }
			if (pixelName == null) { return '{"error":"Pixel Name was not found","message":"error"}'; }
			if (pixelText == null) { return '{"error":"Pixel Text was not found","message":"error"}'; }

			RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Affiliate_Account' AND SobjectType = 'Account' LIMIT 1];
			List<Account> affiliateAccounts = [SELECT Id FROM Account WHERE id=:accountId AND RecordTypeId =: recType.Id];
			if (affiliateAccounts.isEmpty()) { return '{"error":"Affiliate Account was not found","message":"error"}'; }

			Pixels__c pixel = (pixelId == null) ? new Pixels__c() : new Pixels__c (Id = pixelId);
			pixel.Name = pixelName;
			pixel.Account__c = accountId;
			pixel.Pixel_Text__c = pixelText;

			try {
				SFDCAccessController.UpsertWithoutSharing (
					pixel,
					'RestAffiliateController.cls [setAffiliatePixel]',
					new List<Schema.DescribeFieldResult>{
						Pixels__c.Name.getDescribe(), Pixels__c.Account__c.getDescribe(),
						Pixels__c.Pixel_Text__c.getDescribe()
					}
				);
			} catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }

			return '{"pixelId":"' + String.valueOf(pixel.Id) + '","message":"success"}';

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String setAffiliateOfferLink(Map<String, String> generalData) {
		try {

			Id affiliateOfferId = generalData.containsKey('affiliateOfferId') ? Id.valueOf(generalData.get('affiliateOfferId')) : null;
			Id affiliateOfferLinkId = generalData.containsKey('affiliateOfferLinkId') ? Id.valueOf(generalData.get('affiliateOfferLinkId')) : null;
			String name = generalData.containsKey('name') ? String.valueOf(generalData.get('name')) : null;
			String sub1 = generalData.containsKey('sub1') ? String.valueOf(generalData.get('sub1')) : null;
			String sub2 = generalData.containsKey('sub2') ? String.valueOf(generalData.get('sub2')) : null;
			String sub3 = generalData.containsKey('sub3') ? String.valueOf(generalData.get('sub3')) : null;
			String sub4 = generalData.containsKey('sub4') ? String.valueOf(generalData.get('sub4')) : null;
			String sub5 = generalData.containsKey('sub5') ? String.valueOf(generalData.get('sub5')) : null;
			String utmCampaign = generalData.containsKey('utmCampaign') ? String.valueOf(generalData.get('utmCampaign')) : null;
			String utmContent = generalData.containsKey('utmContent') ? String.valueOf(generalData.get('utmContent')) : null;
			String utmMedium = generalData.containsKey('utmMedium') ? String.valueOf(generalData.get('utmMedium')) : null;
			String utmSource = generalData.containsKey('utmSource') ? String.valueOf(generalData.get('utmSource')) : null;
			String utmTerm = generalData.containsKey('utmTerm') ? String.valueOf(generalData.get('utmTerm')) : null;

			//verification of input data
			if (affiliateOfferId == null && affiliateOfferLinkId == null) { return '{"error":"Affiliate Offer Id or Affiliate Offer Link Id was not found","message":"error"}'; }
			if (name == null) { return '{"error":"Name was not found","message":"error"}'; }

			if (affiliateOfferId != null) {
				List<Affiliate_Offer__c> verifyAffiliateOffer = [SELECT Id FROM Affiliate_Offer__c WHERE Id =:affiliateOfferId LIMIT 1];
				if (verifyAffiliateOffer.isEmpty()) { return '{"error":"Wrong Affiliate Offer Id","message":"error"}'; }
			}

			if (affiliateOfferLinkId != null) {
				List<Affiliate_Offer_Link__c> verifyAffiliateOfferLink = [SELECT Id FROM Affiliate_Offer_Link__c WHERE Id =:affiliateOfferLinkId LIMIT 1];
				if (verifyAffiliateOfferLink.isEmpty()) { return '{"error":"Wrong Affiliate Offer Link Id","message":"error"}'; }
			}

			Affiliate_Offer_Link__c affiliateOfferLinkToUpdate = new Affiliate_Offer_Link__c();

			if (affiliateOfferLinkId != null) {
				affiliateOfferLinkToUpdate.Id = affiliateOfferLinkId;
			} else if (affiliateOfferId != null) {
				affiliateOfferLinkToUpdate.Affiliate_Offer__c = affiliateOfferId;               
			}
			affiliateOfferLinkToUpdate.Name = name;
			affiliateOfferLinkToUpdate.Sub1__c = sub1;
			affiliateOfferLinkToUpdate.Sub2__c = sub2;
			affiliateOfferLinkToUpdate.Sub3__c = sub3;
			affiliateOfferLinkToUpdate.Sub4__c = sub4;
			affiliateOfferLinkToUpdate.Sub5__c = sub5;
			affiliateOfferLinkToUpdate.Utm_Campaign__c = utmCampaign;
			affiliateOfferLinkToUpdate.Utm_Content__c = utmContent;
			affiliateOfferLinkToUpdate.Utm_Medium__c = utmMedium;
			affiliateOfferLinkToUpdate.Utm_Source__c = utmSource;
			affiliateOfferLinkToUpdate.Utm_Term__c = utmTerm;

			try {
				SFDCAccessController.UpsertWithoutSharing (
					affiliateOfferLinkToUpdate,
					'RestAffiliateController.cls [setAffiliateOfferLink]',
					new List<Schema.DescribeFieldResult>{
						Affiliate_Offer_Link__c.Name.getDescribe(), Affiliate_Offer_Link__c.Sub1__c.getDescribe(),
						Affiliate_Offer_Link__c.Sub2__c.getDescribe(), Affiliate_Offer_Link__c.Sub3__c.getDescribe(),
						Affiliate_Offer_Link__c.Sub4__c.getDescribe(), Affiliate_Offer_Link__c.Sub5__c.getDescribe(),
						Affiliate_Offer_Link__c.Utm_Campaign__c.getDescribe(), Affiliate_Offer_Link__c.Utm_Content__c.getDescribe(),
						Affiliate_Offer_Link__c.Utm_Medium__c.getDescribe(), Affiliate_Offer_Link__c.Utm_Source__c.getDescribe(),
						Affiliate_Offer_Link__c.Utm_Term__c.getDescribe()
					}
				);
			} catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }

			return '{"affiliateOfferLinkId":"' + String.valueOf(affiliateOfferLinkToUpdate.Id) + '","message":"success"}';

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String deleteAffiliateOfferLink(Map<String, String> generalData) {
		try {

			Id affiliateOfferLinkId = generalData.containsKey('affiliateOfferLinkId') ? Id.valueOf(generalData.get('affiliateOfferLinkId')) : null;

			if (String.isBlank(affiliateOfferLinkId)) { return '{"error":"Affiliate Offer Link Id was not found","message":"error"}'; }
			List<Affiliate_Offer_Link__c> verifyAffiliateOfferLinkList = [SELECT Id FROM Affiliate_Offer_Link__c WHERE Id = :affiliateOfferLinkId LIMIT 1];
			if (verifyAffiliateOfferLinkList.isEmpty()) { return '{"error":"Wrong Affiliate Offer Link Id","message":"error"}'; }

			try {
				SFDCAccessController.DeleteWithoutSharing (
					verifyAffiliateOfferLinkList[0],
					'RestAffiliateController.cls [deleteAffiliateOfferLink]'
				);
			} catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }

			return '{"affiliateOfferLinkId":"' + String.valueOf(affiliateOfferLinkId) + '","message":"success"}';

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String deletePixel(Map<String, String> generalData) {
		try {

			Id pixelId = generalData.containsKey('pixelId') ? Id.valueOf(generalData.get('pixelId')) : null;

			if (String.isBlank(pixelId)) { return '{"error":"Pixel Id was not found","message":"error"}'; }
			List<Pixels__c> verifyPixelList = [SELECT Id FROM Pixels__c WHERE Id = :pixelId LIMIT 1];
			if (verifyPixelList.isEmpty()) { return '{"error":"Wrong Pixel Id","message":"error"}'; }

			try {
				SFDCAccessController.DeleteWithoutSharing (
					verifyPixelList[0],
					'RestAffiliateController.cls [deletePixel]'
				);
			} catch (SFDCAccessControlException e) { return  '{"error":"' + e.ExceptionMessage + '","message":"error"}'; }

			return '{"pixelId":"' + String.valueOf(pixelId) + '","message":"success"}';

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String getPixels(Map<String, String> generalData) {
		try {

			Id accountId = generalData.containsKey('accountId') ? Id.valueOf(generalData.get('accountId')) : null;
			Id offerId = generalData.containsKey('offerId') ? Id.valueOf(generalData.get('offerId')) : null;
			if (String.isBlank(accountId)) { return '{"error":"Account Id was not found","message":"error"}'; }

			List<Pixels__c> pixelsList = new List<Pixels__c>();
			if (offerId == null) {
				pixelsList = [SELECT Id, Name, CreatedDate, Pixel_Text__c, Account__r.Affiliate_Approval__c FROM Pixels__c WHERE Account__c = :accountId ORDER BY Name];
			} else {
				List<Affiliate_Offer_Pixels__c> affiliateOfferPixels = [SELECT Id, Pixels__c FROM Affiliate_Offer_Pixels__c WHERE Affiliate_Offer__r.Account__c =:accountId AND Affiliate_Offer__r.Offer__c =:offerId];
				Set<Id> pixelsIds = new Set<Id>();
				for (Affiliate_Offer_Pixels__c itemPixel : affiliateOfferPixels) {
					pixelsIds.add(itemPixel.Pixels__c);
				}
				pixelsList = [SELECT Id, Name, CreatedDate, Pixel_Text__c, Account__r.Affiliate_Approval__c  FROM Pixels__c WHERE Account__c = :accountId AND Id IN: pixelsIds ORDER BY Name];
			}

			if (pixelsList.isEmpty()) { return '{"error":"Pixels was not found","message":"error"}'; }

			List<Map<String, Object>> result = new List<Map<String, Object>>();
			for (Pixels__c pixel : pixelsList) {
				result.add(new Map<String, Object> {
					'createdDate' => (pixel.CreatedDate).format('MMM dd yyyy HH:mm:ss'),
					'pixelText' => pixel.Pixel_Text__c,
					'pixelName' => pixel.Name,
					'pixelId' => pixel.Id
					});
			}

			return JSON.serialize(new Map<String, Object>{
				'pixels' => result,
				'affiliateApproval' => pixelsList[0].Account__r.Affiliate_Approval__c,
				'message' => 'success'
			});

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}


	public static String getPixel(Map<String, String> generalData) {
		try {

			Id pixelId = generalData.containsKey('pixelId') ? Id.valueOf(generalData.get('pixelId')) : null;
			if (String.isBlank(pixelId)) { return '{"error":"Pixel Id was not found","message":"error"}'; }

			List<Pixels__c> pixelsList = [SELECT Id, Name, CreatedDate, Account__c, Pixel_Text__c FROM Pixels__c WHERE Id = :pixelId LIMIT 1];
			if (pixelsList.isEmpty()) { return '{"error":"Pixel was not found","message":"error"}'; }

			return JSON.serialize(new Map<String, Object>{
				'createdDate' => (pixelsList[0].CreatedDate).format('MMM dd yyyy HH:mm:ss'),
				'pixelText' => pixelsList[0].Pixel_Text__c,
				'pixelName' => pixelsList[0].Name,
				'pixelId' => pixelsList[0].Id,
				'message' => 'success'
			});

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}


	public static String getPayouts(Map<String, String> generalData) {
		try {

			Id accountId = generalData.containsKey('accountId') ? Id.valueOf(generalData.get('accountId')) : null;
			if (String.isBlank(accountId)) { return '{"error":"Account Id was not found","message":"error"}'; }

			List<Payouts__c> payoutsList = [SELECT Id, Name, CreatedDate, Amount_Transferred__c, Payout_Date__c, Status__c FROM Payouts__c WHERE Account__c = :accountId ORDER BY CreatedDate DESC];
			if (payoutsList.isEmpty()) { return '{"error":"Payouts was not found","message":"error"}'; }

			List<Map<String, Object>> result = new List<Map<String, Object>>();
			for (Payouts__c payout : payoutsList) {

				result.add(new Map<String, Object> {
					'amountTransferred' => payout.Amount_Transferred__c,
					'payoutId' => payout.Id,
					'payoutName' => payout.Name,
					'createdDate' => (payout.CreatedDate).format('MMM dd yyyy HH:mm:ss'),
					'payoutDate' => payout.Payout_Date__c != null ? payout.Payout_Date__c.format('MMM dd yyyy HH:mm:ss') : null,
					'status' => payout.Status__c
					});
			}
			return JSON.serialize(new Map<String, Object>{
				'message' => 'success',
				'payouts' => result
			});

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}


	public static String getPayout(Map<String, String> generalData) {
		try {

			Id payoutId = generalData.containsKey('payoutId') ? Id.valueOf(generalData.get('payoutId')) : null;
			if (String.isBlank(payoutId)) { return '{"error":"Payout Id was not found","message":"error"}'; }

			List<Payouts__c> payoutsList = [SELECT Id, Name, CreatedDate, Amount_Transferred__c, Payout_Date__c, Status__c FROM Payouts__c WHERE Id = :payoutId];
			if (payoutsList.isEmpty()) { return '{"error":"Payouts was not found","message":"error"}'; }

			Payouts__c payout = payoutsList[0];

			List<Commissions_Earned__c> commissionsEarned = [SELECT Id, Name, CreatedDate, Commission_Earned__c, Offer__c FROM Commissions_Earned__c WHERE Payouts__c =:payout.Id ORDER BY CreatedDate DESC];
			List<Map<String, Object>> result = new List<Map<String, Object>>();
			for (Commissions_Earned__c commission : commissionsEarned) {
				result.add(new Map<String, Object> {
					'commissionEarnedId' => commission.Id,
					'commissionEarnedName' => commission.Name,
					'commissionEarned' => commission.Commission_Earned__c,
					'createdDate' => (commission.CreatedDate).format('MMM dd yyyy HH:mm:ss'),
					'offerId' => commission.Offer__c
					});
			}

			return JSON.serialize(new Map<String, Object>{
				'message' => 'success',
				'amountTransferred' => payout.Amount_Transferred__c,
				'payoutId' => payout.Id,
				'payoutName' => payout.Name,
				'createdDate' => (payout.CreatedDate).format('MMM dd yyyy HH:mm:ss'),
				'payoutDate' => payout.Payout_Date__c != null ? payout.Payout_Date__c.format('MMM dd yyyy HH:mm:ss') : null,
				'status' => payout.Status__c,
				'commissionsEarned' => result
			});

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String getAffiliateOfferLink(Map<String, String> generalData) {
		try {

			Id affiliateOfferLinkId = generalData.containsKey('affiliateOfferLinkId') ? Id.valueOf(generalData.get('affiliateOfferLinkId')) : null;
			if (String.isBlank(affiliateOfferLinkId)) { return '{"error":"AffiliateOfferLink Id was not found","message":"error"}'; }

			List<Affiliate_Offer_Link__c> affiliateOfferLinks = [SELECT Id, CreatedDate, Name, Affiliate_Offer__c, Sub1__c, Sub2__c, Sub3__c, Sub4__c, Sub5__c,
																Utm_Campaign__c, Utm_Content__c, Utm_Medium__c, Utm_Source__c, Utm_Term__c,
																Affiliate_Offer__r.Account__c, Affiliate_Offer__r.Offer__c, Affiliate_Offer__r.Base_URL__c
																FROM Affiliate_Offer_Link__c WHERE Id = :affiliateOfferLinkId];
			if (affiliateOfferLinks.isEmpty()) { return '{"error":"AffiliateOfferLink was not found","message":"error"}'; }

			Affiliate_Offer_Link__c affiliateOfferLink = affiliateOfferLinks[0];

			return JSON.serialize(new Map<String, Object>{
				'createdDate' => (affiliateOfferLink.CreatedDate).format('MMM dd yyyy HH:mm:ss'),

				'affiliateAccountId' => affiliateOfferLink.Affiliate_Offer__r.Account__c,
				'offerId' => affiliateOfferLink.Affiliate_Offer__r.Offer__c,
				'affiliateOfferURL' => affiliateOfferLink.Affiliate_Offer__r.Base_URL__c,

				'affiliateOfferLinkName' => affiliateOfferLink.Name,
				'affiliateOfferLinkId' => affiliateOfferLink.Id,
				'affiliateOfferId' => affiliateOfferLink.Affiliate_Offer__c,
				'utmTerm' => affiliateOfferLink.Utm_Term__c,
				'utmSource' => affiliateOfferLink.Utm_Source__c,
				'utmMedium' => affiliateOfferLink.Utm_Medium__c,
				'utmContent' => affiliateOfferLink.Utm_Content__c,
				'utmCampaign' => affiliateOfferLink.Utm_Campaign__c,
				'sub5' => affiliateOfferLink.Sub5__c,
				'sub4' => affiliateOfferLink.Sub4__c,
				'sub3' => affiliateOfferLink.Sub3__c,
				'sub2' => affiliateOfferLink.Sub2__c,
				'sub1' => affiliateOfferLink.Sub1__c,
				'message' => 'success'
			});

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}

	public static String getCommissionsEarned(Map<String, String> generalData) {
		try {

			Id accountId = generalData.containsKey('accountId') ? Id.valueOf(generalData.get('accountId')) : null;
			if (String.isBlank(accountId)) { return '{"error":"Account Id was not found","message":"error"}'; }

			List<Commissions_Earned__c> commissionsEarned = [SELECT Id, Name, CreatedDate, Commission_Earned__c, Offer__c, Payout_Date__c, Status__c, Type__c
															FROM Commissions_Earned__c WHERE Affiliate_Offer__r.Account__c =:accountId ORDER BY CreatedDate DESC];
			if (commissionsEarned.isEmpty()) { return '{"error":"Commissions Earned was not found","message":"error"}'; }


			List<Map<String, Object>> result = new List<Map<String, Object>>();
			for (Commissions_Earned__c commission : commissionsEarned) {
				result.add(new Map<String, Object> {
					'commissionEarnedId' => commission.Id,
					'commissionEarnedName' => commission.Name,
					'commissionEarned' => commission.Commission_Earned__c,
					'status' => commission.Status__c,
					'type' => commission.Type__c,
					'payoutDate' => commission.Payout_Date__c != null ? commission.Payout_Date__c.format('MMM dd yyyy HH:mm:ss') : null,
					'createdDate' => (commission.CreatedDate).format('MMM dd yyyy HH:mm:ss'),
					'offerId' => commission.Offer__c
					});
			}

			return JSON.serialize(new Map<String, Object>{
				'message' => 'success',
				'commissionsEarned' => result
			});

		} catch (Exception e) { return '{"error":"' + e.getMessage() + '","message":"error"}'; }
	}


}