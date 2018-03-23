@isTest
private class RestNewOrderProcessControllerV2Test {

	static testMethod void setGuestTest() {

		Map<String, String> orderFormData = new Map<String, String>{
			'fname' => 'Mouse',
			'lname' => 'Micke',
			'phone' => '12123232',
			'billingStreet' => 'TStreet',
			'billingCity' => 'TCity',
			'billingState' => 'Alaska',
			'billingPostalCode' => '1234',
			'billingCountry' => 'United States',
			'shippingStreet' => 'TStreet',
			'shippingCity' => 'TCity',
			'shippingState' => 'Alaska',
			'shippingPostalCode' => '1234',
			'shippingCountry' => 'United States'
		};


		RestHelper.DataForOrderItems dataForOrderItems = new RestHelper.DataForOrderItems();

		Test.startTest();
		String result;
		result = RestNewOrderProcessControllerV2.setOrder(orderFormData, dataForOrderItems);
		System.assertEquals(true, result.contains('Email can not be empty'));

		orderFormData.put('email', 'testemail@gmail.com');
		result = RestNewOrderProcessControllerV2.setOrder(orderFormData, dataForOrderItems);

		System.assertEquals(false, result.contains('Email can not be empty'));
		System.assertEquals(true, result.contains('error'));
		System.assertEquals(1, [SELECT Count() FROM Account]);

		orderFormData.put('email', 'testlead@gmail.com');
		Lead leadToAccount = new Lead (Lastname = 'LastName', Email = 'testlead@gmail.com');
		insert leadToAccount;

		result = RestNewOrderProcessControllerV2.setOrder(orderFormData, dataForOrderItems);
		System.assertEquals(true, result.contains('error'));
		System.assertEquals(2, [SELECT Count() FROM Account]);
	}

	static testMethod void getCustomerHistoryOneTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account ac = new Account(
			RecordTypeId = customerRecordType.Id,
			FirstName = 'XXX', LastName = 'YYY', Phone = '9876543210', 
			PersonEmail = 'xxx008@ymail.com'
		);
		insert ac;

		Case cs = new Case(
			AccountId = ac.Id, Status = 'New', Origin = 'Phone',
			Type = 'Payment', Reason = 'Unpaid Order'
		);
		insert cs;

		Test.startTest();
			String result = RestNewOrderProcessControllerV2.getCustomerHistory(String.valueOf(ac.Id));
			System.assertEquals('true', result);
		Test.stopTest();
	}

	static testMethod void getCustomerHistoryTwoTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account ac = new Account(
			RecordTypeId = customerRecordType.Id,
			FirstName = 'XXX', LastName = 'YYY', Phone = '9876543210', 
			PersonEmail = 'xxx009@ymail.com', Orders_Failed__c = 10
		);
		insert ac;

		Case cs = new Case(
			AccountId = ac.Id, Status = 'New', Origin = 'Phone',
			Type = 'Payment',Reason = 'Unpaid Order'
		);
		insert cs;

		Test.startTest();
			String result = RestNewOrderProcessControllerV2.getCustomerHistory(String.valueOf(ac.Id));
			System.assertEquals('fraud', result);
		Test.stopTest();
	}

	static testMethod void getCustomerHistoryThreeTest() {
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		Account ac = new Account(
			RecordTypeId = customerRecordType.Id,
			FirstName = 'XXX', LastName = 'YYY', Phone = '9876543210',
			PersonEmail = 'xxx005@ymail.com', Blacklist__c = 'true'
		);
		insert ac;

		Test.startTest();
			String result = RestNewOrderProcessControllerV2.getCustomerHistory(String.valueOf(ac.Id));
			System.assertEquals('no order allowed', result);
		Test.stopTest();
	
	}

}