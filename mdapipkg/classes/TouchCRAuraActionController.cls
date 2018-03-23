public class TouchCRAuraActionController {

	//VOID
	@AuraEnabled
	public static Decimal getAmountVoid(String transactionId) {
		Set<String> availableTypes = new Set<String>{'Charge', 'Authorization'};
		List<Order_Transaction__c> orderTransaction = [
			SELECT Id, Amount__c, Response_Status__c
			FROM Order_Transaction__c
			WHERE Type__c IN: availableTypes
			AND Response_Status__c = 'Approved'
			AND Id =: transactionId
			LIMIT 1
		];
		return orderTransaction.isEmpty() ? 0 : orderTransaction[0].Amount__c;
	}

	@AuraEnabled
	public static String voidNow(String recordId, Decimal amount) {
		Map<String,Object> result = PaymentProcessor.doPayment(
			new Map<String,Object>{
				'Method' => 'Void',
				'Amount' => amount,
				'Transaction' => recordId
			}
		);

		if (result.containsKey('Status')) {
			if (result.get('Status') == 'Approved') {
				String transactionId = (String)result.get('Transaction');
				List<Order_Transaction__c> orderTransaction = [
					SELECT Id, Order__c
					FROM Order_Transaction__c
					WHERE Id =: transactionId
					LIMIT 1
				];
				result.put('parentId',orderTransaction[0].Order__c);
				update new Order__c(Id = orderTransaction[0].Order__c, Status__c = 'Voided');
			}
		}
		return JSON.serialize(result);
	}


	//CHARGE
	@AuraEnabled
	public static String getCardsAndGeneralInfo(String recordId) {
		try {
			Id orderId = Id.valueOf(recordId);

			List<Account> account = [
				SELECT Id, 
				(
					SELECT Id, Profile_Id__c, Option_Id__c, 
					Named_Agent__c, Last_4__c
					FROM Payment_Options__r
					WHERE Status__c = 'Active'
				), 
				(
					SELECT Id, Amount_To_Charge__c, Named_Agent__c
					FROM Orders__r
					WHERE Id =: orderId
				) 
				FROM Account 
				WHERE Id IN 
				(
					SELECT Account__c 
					FROM Order__c 
					WHERE Id =: orderId
				)
			];

			if (account.isEmpty()) { return '{"status":"error","error":"Account was not found"}'; }
			
			List<Map<String, Object>> allPaymentOptions = new List<Map<String, Object>>();
			for (Payment_Option__c pO : account[0].Payment_Options__r) {
				//get Payment Options for a definite Named Agent
				if (pO.Named_Agent__c == account[0].Orders__r[0].Named_Agent__c) {
					allPaymentOptions.add(new Map<String, Object>{
						'isCheck' => false,
						'paymentOptionId' => pO.Id,
						'profileId' => pO.Profile_Id__c,
						'optionId' => pO.Option_Id__c,
						'namedAgent' => pO.Named_Agent__c,
						'last4' => pO.Last_4__c
					});
				}
			}

			return JSON.serialize(new Map<String, Object>{
				'status' => 'success',
				'paymentOptions' => allPaymentOptions,
				'amount' => account[0].Orders__r[0].Amount_To_Charge__c
			});
		} catch (Exception e) { return '{"status":"error","error":"' + e.getMessage() + '"}'; }
	}

	@AuraEnabled
	public static String chargeOrderNow(String chargeData) {
		try {
			Map<String, String> allChargeData = (Map<String, String>)JSON.deserialize(chargeData, Map<String, String>.class);
			
			Map<String,Object> creditCard = new Map<String,Object>();

			if (Boolean.valueOf(allChargeData.get('newCard'))) {
				String cardExpirationMonth = allChargeData.containsKey('month') ? String.valueOf(allChargeData.get('month')) : '';
				String cardExpirationYear = allChargeData.containsKey('year') ? String.valueOf(allChargeData.get('year')) : '';
				String ccv = allChargeData.containsKey('ccv') ? String.valueOf(allChargeData.get('ccv')) : '';
				String cardNumber = allChargeData.containsKey('cardNumber') ? String.valueOf(allChargeData.get('cardNumber')) : '';
	
				if (String.isBlank(cardExpirationMonth) || String.isBlank(cardExpirationYear) || String.isBlank(ccv) || String.isBlank(cardNumber)) {
					return '{"status":"error","error":"Data is not valid"}';
				}
				
				creditCard.put('CardNumber', cardNumber);
				creditCard.put('CardCCV', ccv);
				creditCard.put('CardExpirationMonth', cardExpirationMonth);
				creditCard.put('CardExpirationYear', cardExpirationYear);   
			} else {
				Id chosenPaymentOptionId = allChargeData.containsKey('chosenPaymentOptionId') ? Id.valueOf(allChargeData.get('chosenPaymentOptionId')) : '';
				
				List<Payment_Option__c> paymentOption = [
					SELECT Id, Profile_Id__c, Option_Id__c
					FROM Payment_Option__c
					WHERE Id =: chosenPaymentOptionId
					AND Status__c = 'Active'
				];

				if (paymentOption.isEmpty()) { return '{"status":"error","error":"Payment Option was not found"}'; }

				creditCard.put('CardId', paymentOption[0].Option_Id__c);   
				creditCard.put('Profile', paymentOption[0].Profile_Id__c); 
			}

			String amount = allChargeData.containsKey('amount') ? String.valueOf(allChargeData.get('amount')) : '';
			if (String.isBlank(amount)) { return '{"status":"error","error":"The Amount must not be less than 1 Dollar"}'; }
			String orderId = allChargeData.containsKey('orderId') ? String.valueOf(allChargeData.get('orderId')) : '';
			if (String.isBlank(orderId)) { return '{"status":"error","error":"Order Id was not found"}'; }
			Map<String,Object> result = PaymentProcessor.doPayment(
				new Map<String,Object>{
					'Method' => 'Charge',
					'OrderId' => orderId,
					'Amount' => Decimal.valueOf(amount),
					'CreditCard' => creditCard
				}
			);
			//default value
			String transactionId = '';
			
			if (result.containsKey('Transaction')) { transactionId = String.valueOf(result.get('Transaction')); }
			if (!result.containsKey('Status')) { return '{"status":"error","error":"Error Transaction Service Unavailable", "transaction":"' + transactionId + '"}'; }
			if ((String)result.get('Status') == 'Error') { return '{"status":"error","error":"' + result.get('Message') + '","transaction":"' + transactionId + '"}'; }
			if ((String)result.get('Status') == 'Approved') { return '{"status":"success","transaction":"' + transactionId + '"}'; }
			return '{"status":"error","error":"Error Transaction Service Unavailable","transaction":""}'; 
		} catch (Exception e) { return '{"status":"error","error":"' + e.getMessage() + '","transaction":""}'; }
	}

	//REFUND
	@AuraEnabled
	public static Decimal getAmountRefund(String transactionId) {
		Set<String> availableTypes = new Set<String>{'Charge', 'Authorization'};
		List<Order_Transaction__c> orderTransaction = [
			SELECT Id, Amount__c, Response_Status__c
			FROM Order_Transaction__c
			WHERE Type__c IN: availableTypes
			AND Response_Status__c = 'Approved'
			AND Id =: transactionId
			LIMIT 1
		];

		return orderTransaction.isEmpty() ? 0 : orderTransaction[0].Amount__c;
	}

	@AuraEnabled
	public static String refund(String recordId, Decimal amount) {
		Order_Transaction__c orderTransaction = [
			SELECT Id, Order__c
			FROM Order_Transaction__c
			WHERE Id =: recordId
			LIMIT 1
		];

		Map<String,Object> result = PaymentProcessor.doPayment(
			new Map<String,Object>{
				'Method' => 'Refund',
				'Amount' => amount,
				'Transaction' => recordId
			}
		);

		if (result.containsKey('Status')) {
			if (result.get('Status') == 'Approved') {
				result.put('parentId', orderTransaction.Order__c);
			}
		}
		return JSON.serialize(result);
	}


	//AUTHORIZE
	@AuraEnabled
	public static Decimal getAmountAuthorize(String orderId) {
		List<Order__c> order = [
			SELECT Id, Amount_To_Charge__c
			FROM Order__c
			WHERE Id =: orderId
			LIMIT 1
		];
		return order.isEmpty() ? 0 : order[0].Amount_To_Charge__c;
	}

	@AuraEnabled
	public static String authorizeOrderNow(String authorizeData) {
		try {
			Map<String, String> allAuthorizeData = (Map<String, String>)JSON.deserialize(authorizeData, Map<String, String>.class);

			if (allAuthorizeData.containsKey('cardExpirationMonth') && allAuthorizeData.containsKey('cardExpirationYear')
				&& allAuthorizeData.containsKey('ccv') && allAuthorizeData.containsKey('cardNumber')
				&& allAuthorizeData.containsKey('recordId') && allAuthorizeData.containsKey('amount')) {

				String cardExpirationMonth = allAuthorizeData.get('cardExpirationMonth');
				String cardExpirationYear = allAuthorizeData.get('cardExpirationYear');
				String ccv = allAuthorizeData.get('ccv');
				String cardNumber = allAuthorizeData.get('cardNumber');
				String recordId = allAuthorizeData.get('recordId');
				String amount = allAuthorizeData.get('amount');

				Map<String,Object> creditCard = new Map<String,Object>{
					'CardNumber' => cardNumber,
					'CardCCV' => ccv,
					'CardExpirationMonth' => cardExpirationMonth,
					'CardExpirationYear' => cardExpirationYear
				};

				Map<String,Object> result = PaymentProcessor.doPayment(
					new Map<String,Object>{
						'Method' => 'Authorization',
						'OrderId' => recordId,
						'Amount' => Decimal.valueOf(amount),
						'CreditCard' => creditCard
					}
				);

				//default value
				String transactionId = '';
				
				if (result.containsKey('Transaction')) { transactionId = String.valueOf(result.get('Transaction')); }
				if (!result.containsKey('Status')) { return '{"status":"error","error":"Error Transaction Service Unavailable", "transaction":"' + transactionId + '"}'; }
				if ((String)result.get('Status') == 'Error') { return '{"status":"error","error":"' + result.get('Message') + '","transaction":"' + transactionId + '"}'; }
				if ((String)result.get('Status') == 'Approved') { return '{"status":"success","transaction":"' + transactionId + '"}'; }
			}
			return '{"status":"error","error":"Data is not valid","transaction":""}'; 
		} catch (Exception e) { return '{"status":"error","error":"' + e.getMessage() + '","transaction":""}'; }    
	}



}