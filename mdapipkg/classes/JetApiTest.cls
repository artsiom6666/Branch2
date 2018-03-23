@IsTest
private class JetApiTest {

	static final String goodResponse = '{"acknowledgement_status":"accepted","alt_order_id":"787771772894","buyer":{"name":"Marge Simpson","phone_number":"212-212-4184"},"customer_reference_order_id":"705826727967","fulfillment_node":"b7d52ea7a11c4c9d9ba5c3d9589b5f70","has_shipments":false,"hash_email":"593377372222@customer.jet.com","jet_request_directed_cancel":false,"merchant_order_id":"92c8837ea2024a33bfd6ed65f2fe64cd","order_acknowledge_date":"2017-04-20T05:39:16Z","order_detail":{"request_shipping_method":"FedEx Ground","request_shipping_carrier":"FedEx","request_service_level":"Expedited","request_ship_by":"2017-04-21T05:39:15.1323097Z","request_delivery_by":"2017-04-22T05:39:15.1323097Z"},"order_items":[{"order_item_id":"2e3907ad994d48978c4eacf309f412b3","merchant_sku":"test_product","request_order_quantity":2,"request_order_cancel_qty":0,"item_tax_code":"","item_price":{"item_tax":null,"item_shipping_cost":2.28,"item_shipping_tax":null,"base_price":38},"product_title":"Cedcommerce Test Product","url":"http://www.jet.com/api/merchant_skus/test_product","order_item_acknowledgement_status":"fulfillable"}],"order_placed_date":"2017-04-20T05:38:15.1323097Z","order_totals":{"item_price":{"item_tax":null,"item_shipping_cost":2.28,"item_shipping_tax":null,"base_price":38}},"order_transmission_date":"2017-04-20T05:39:15.1323097Z","reference_order_id":"327731367779","shipments":[{"alt_shipment_id":"149266675696","carrier":"FedEx","carrier_pick_up_date":"2017-04-22T05:39:15.0000000-07:00","expected_delivery_date":"2017-04-22T05:39:15.0000000-07:00","response_shipment_date":"2017-04-22T05:39:15.0000000-07:00","response_shipment_method":"","ship_from_zip_code":"12345","shipment_id":"39260b41939140b5b0ef80f6e05e3eae","shipment_items":[{"merchant_sku":"test_product","response_shipment_sku_quantity":1,"response_shipment_cancel_qty":0,"RMA_number":"abcdef","days_to_return":30,"return_location":{"address1":"6909 South State Street","address2":"Suite C","city":"Midvale","state":"UT","zip_code":"84047"}}],"shipment_message_date":"2017-04-20T05:39:17Z","shipment_tracking_number":"14926667565454"}],"shipping_to":{"recipient":{"name":"Lisa Simpson","phone_number":"212-212-7726"},"address":{"address1":"45 Elm street","address2":"","city":"Burtons","state":"MS","zip_code":"38829"}},"status":"complete"}';
	static final String badResponse = '{"alt_order_id":"060344283352","buyer":{"name":"Snowball","phone_number":"212-212-9684"},"customer_reference_order_id":"091819792311","exception_state":"exception - too many units shipped","fulfillment_node":"b7d52ea7a11c4c9d9ba5c3d9589b5f70","has_shipments":false,"hash_email":"468386143480@customer.jet.com","jet_request_directed_cancel":true,"merchant_order_id":"87a01daa85ba42a1ba6956ca89cc33b8","order_detail":{"request_shipping_method":"FedEx Ground","request_shipping_carrier":"UPS","request_service_level":"Scheduled (freight)","request_ship_by":"2017-04-21T05:39:13.4048839Z","request_delivery_by":"2017-04-22T05:39:13.4048839Z"},"order_items":[{"order_item_id":"86d327db396d4f0ea902ba594d9649a9","merchant_sku":"test_product","request_order_quantity":0,"request_order_cancel_qty":2,"item_tax_code":"","item_price":{"item_tax":null,"item_shipping_cost":0.76,"item_shipping_tax":null,"base_price":38},"product_title":"Cedcommerce Test Product","url":"http://www.jet.com/api/merchant_skus/test_product"}],"order_placed_date":"2017-04-20T05:38:13.4048839Z","order_totals":{},"order_transmission_date":"2017-04-20T05:39:13.4048839Z","reference_order_id":"693005457708","shipments":[{"alt_shipment_id":"149266675496","carrier":"UPS","carrier_pick_up_date":"2017-04-22T05:39:13.0000000-07:00","expected_delivery_date":"2017-04-22T05:39:13.0000000-07:00","response_shipment_date":"2017-04-22T05:39:13.0000000-07:00","response_shipment_method":"","ship_from_zip_code":"84047","shipment_id":"48494308461d4cbb9322140f09dd9a82","shipment_items":[{"merchant_sku":"test_product","response_shipment_sku_quantity":0,"response_shipment_cancel_qty":1,"RMA_number":"abcedef","days_to_return":30,"return_location":{"address1":"6909 South State Street","address2":"Suite C","city":"Midvale","state":"UT","zip_code":"84047"}}],"shipment_message_date":"2017-04-20T05:39:14Z"}],"shipping_to":{"recipient":{"name":"Bart Simpson","phone_number":"212-212-7999"},"address":{"address1":"38 Elm street","address2":"","city":"Old Cairo","state":"MS","zip_code":"38829"}},"status":"complete"}';

	// HELPERS
	static testMethod void test_createNewCustomer() {
		// for invoking instance methods
		JetApiBatch b = new JetApiBatch();
		// 2 word name
		OrderDto data = (OrderDto) JSON.deserialize(goodResponse, OrderDto.class);
		Account testObj = b.getJetCustomer(data);
		System.assertEquals('Simpson', testObj.LastName);
		System.assertEquals('Marge', testObj.FirstName);

		// 1 word name
		OrderDto data2 = (OrderDto) JSON.deserialize(badResponse, OrderDto.class);
		Account testObj2 = b.getJetCustomer(data2);
		System.assertEquals('Snowball', testObj2.LastName);
		System.assertEquals(null, testObj2.FirstName);

		// 3 word name
		String badResponse2 = '{"acknowledgement_status":"accepted","alt_order_id":"787771772894","buyer":{"name":"DJ Marge Simpson Jr.","phone_number":"212-212-4184"},"customer_reference_order_id":"705826727967","fulfillment_node":"b7d52ea7a11c4c9d9ba5c3d9589b5f70","has_shipments":false,"hash_email":"593377372222@customer.jet.com","jet_request_directed_cancel":false,"merchant_order_id":"92c8837ea2024a33bfd6ed65f2fe64cd","order_acknowledge_date":"2017-04-20T05:39:16Z","order_detail":{"request_shipping_method":"FedEx Ground","request_shipping_carrier":"FedEx","request_service_level":"Expedited","request_ship_by":"2017-04-21T05:39:15.1323097Z","request_delivery_by":"2017-04-22T05:39:15.1323097Z"},"order_items":[{"order_item_id":"2e3907ad994d48978c4eacf309f412b3","merchant_sku":"test_product","request_order_quantity":1,"request_order_cancel_qty":0,"item_tax_code":"","item_price":{"item_tax":null,"item_shipping_cost":2.28,"item_shipping_tax":null,"base_price":38},"product_title":"Cedcommerce Test Product","url":"http://www.jet.com/api/merchant_skus/test_product","order_item_acknowledgement_status":"fulfillable"}],"order_placed_date":"2017-04-20T05:38:15.1323097Z","order_totals":{"item_price":{"item_tax":null,"item_shipping_cost":2.28,"item_shipping_tax":null,"base_price":38}},"order_transmission_date":"2017-04-20T05:39:15.1323097Z","reference_order_id":"327731367779","shipments":[{"alt_shipment_id":"149266675696","carrier":"FedEx","carrier_pick_up_date":"2017-04-22T05:39:15.0000000-07:00","expected_delivery_date":"2017-04-22T05:39:15.0000000-07:00","response_shipment_date":"2017-04-22T05:39:15.0000000-07:00","response_shipment_method":"","ship_from_zip_code":"12345","shipment_id":"39260b41939140b5b0ef80f6e05e3eae","shipment_items":[{"merchant_sku":"test_product","response_shipment_sku_quantity":1,"response_shipment_cancel_qty":0,"RMA_number":"abcdef","days_to_return":30,"return_location":{"address1":"6909 South State Street","address2":"Suite C","city":"Midvale","state":"UT","zip_code":"84047"}}],"shipment_message_date":"2017-04-20T05:39:17Z","shipment_tracking_number":"14926667565454"}],"shipping_to":{"recipient":{"name":"Lisa Simpson","phone_number":"212-212-7726"},"address":{"address1":"45 Elm street","address2":"","city":"Burtons","state":"MS","zip_code":"38829"}},"status":"complete"}';
		OrderDto data3 = (OrderDto) JSON.deserialize(badResponse2, OrderDto.class);
		Account testObj3 = b.getJetCustomer(data3);
		System.assertEquals('DJ Marge Simpson Jr.', testObj3.LastName);
		System.assertEquals(null, testObj3.FirstName);
	}

	static testMethod void test_getJetCustomer() {
		// for invoking instance methods
		JetApiBatch b = new JetApiBatch();
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];

		Account existAccount = new Account(RecordTypeId = customerRecordType.Id, LastName = 'test', JetAccountId__c = '593377372222@customer.jet.com');
		insert existAccount;
		OrderDto data = (OrderDto) JSON.deserialize(goodResponse, OrderDto.class);
		// validate and get Id of exisitng customer
		Account testAccount = b.getJetCustomer(data);
		System.assertEquals(existAccount.JetAccountId__c, testAccount.JetAccountId__c);

		OrderDto data2 = (OrderDto) JSON.deserialize(badResponse, OrderDto.class);
		// new customer no Id
		Account testAccount2 = b.getJetCustomer(data2);
		System.assertEquals(null, testAccount2.Id);
	}

	static testMethod void test_getJetOrderUrls() {
		Order__c existingOrder = new Order__c(
			Connected_Id__c = '92c8837ea2024a33bfd6ed65f2fe64cd'
		);
		insert existingOrder;

		String goodResponse = '{"order_urls":["/orders/withoutShipmentDetail/92c8837ea2024a33bfd6ed65f2fe64cd","/orders/withoutShipmentDetail/87a01daa85ba42a1ba6956ca89cc33b8"]}';
		// FIXME mock it
		JetApi api = new JetApi();
		List<String> orderUrls = api.parseAllOrderUrls(goodResponse);
		// got 2 urls
		System.assertEquals(2, orderUrls.size());
		JetApiBatch.getJetOrderUrls(orderUrls);
		// one order exist -> only one new order urls returned
		System.assertEquals(1, JetApiBatch.getJetOrderUrls(orderUrls).size());
	}

	static testMethod void test_getJetProducts() {
		// for invoking instance methods
		JetApiBatch b = new JetApiBatch();

		OrderDto data = (OrderDto) JSON.deserialize(goodResponse, OrderDto.class);
		List<SObject> testObj = b.getJetProducts(data);
		// product and pbe
		System.assertEquals(2, testObj.size());

		insert testObj;
		// new product added
		List<Product2> testProduct = [SELECT Id, Connected_Id__c, (SELECT Id, UnitPrice FROM PricebookEntries) FROM Product2];
		System.assertEquals(1, testProduct.size());
		System.assertEquals(1, testProduct[0].PricebookEntries.size());

		// if exisitng product has been recieved
		OrderDto data2 = (OrderDto) JSON.deserialize(goodResponse, OrderDto.class);
		system.debug(data2);
		List<SObject> testObj2 = b.getJetProducts(data2);
		// no new product and pbe
		System.assertEquals(0, testObj2.size());

		insert testObj2;
		// assert only one product exisit
		List<Product2> testProduct2 = [SELECT Id, Connected_Id__c, (SELECT Id, UnitPrice FROM PricebookEntries) FROM Product2];
		System.assertEquals(1, testProduct2.size());
		System.assertEquals(1, testProduct2[0].PricebookEntries.size());
	}

	static testMethod void test_amounts_good() {
		OrderDto data = (OrderDto) JSON.deserialize(goodResponse, OrderDto.class);
		//request_order_quantity = 2, item_price = 38
		System.assertEquals(76.0, JetApiBatch.getOrderSubtotal(data));
		System.assertEquals(0, JetApiBatch.getOrderTax(data));
		System.assertEquals(2.28, JetApiBatch.getOrderShipping(data));

		//request_order_cancel_qty = 2, item_price = 38
		OrderDto data2 = (OrderDto) JSON.deserialize(badResponse, OrderDto.class);
		System.assertEquals(76.0, JetApiBatch.getOrderSubtotal(data2));
		System.assertEquals(0, JetApiBatch.getOrderTax(data2));
		System.assertEquals(0.76, JetApiBatch.getOrderShipping(data2));
	}

	static testMethod void test_getJetOrder() {
		// for invoking instance methods
		JetApiBatch b = new JetApiBatch();

		OrderDto data = (OrderDto) JSON.deserialize(goodResponse, OrderDto.class);

		Order__c testObj = (Order__c) b.getJetOrder(data);
		System.assertEquals(76.0, testObj.Subtotal__c);
		System.assertEquals(0, testObj.Tax__c);
		System.assertEquals(2.28, testObj.Shipping__c);
		System.assertEquals('Completed', testObj.Status__c);
		System.assertEquals('Full', testObj.Payment_Received__c);
		System.assertEquals('92c8837ea2024a33bfd6ed65f2fe64cd', testObj.Connected_Id__c);


		data = (OrderDto) JSON.deserialize(badResponse, OrderDto.class);
		testObj = (Order__c) b.getJetOrder(data);
		System.debug(testObj);
		System.assertEquals(76.0, testObj.Subtotal__c);
		System.assertEquals(0, testObj.Tax__c);
		System.assertEquals(0.76, testObj.Shipping__c);
		System.assertEquals('Canceled', testObj.Status__c);
		System.assertEquals('87a01daa85ba42a1ba6956ca89cc33b8', testObj.Connected_Id__c);
		System.assertEquals('exception - too many units shipped', testObj.Order_Information__c);
	}


	// API
	static testMethod void test_api_goodresponses() {

		String validTokenResponse = '{"id_token":"secretToken","token_type":"Bearer","expires_on":"2017-11-23T21:01:13Z"}';
		Test.setMock(HttpCalloutMock.class, new TouchCRConfigurationMock(validTokenResponse));

		JetApi apiConnector = new JetApi();
		Map<String, String> payloadDataAuthTemp = new Map<String, String>{
			'user' => 'username',
			'pass' => 'password'
		};
		apiConnector.setAuthCredentials(payloadDataAuthTemp);
		String authToken = apiConnector.getToken();
		System.assertEquals('secretToken', authToken);

		// at this step token valid token stored in connector, all next calls will use it
		String validOrdersResponse = '{"order_urls":["/orders/withoutShipmentDetail/92c8837ea2024a33bfd6ed65f2fe64cd","/orders/withoutShipmentDetail/87a01daa85ba42a1ba6956ca89cc33b8"]}';
		Test.setMock(HttpCalloutMock.class, new TouchCRConfigurationMock(validOrdersResponse));

		List<String> allOrdersUrls = apiConnector.getAllOrders();

		// check do we have some orders in a system
		List<String> allNewOrdersUrls = JetApiBatch.getJetOrderUrls(allOrdersUrls);
		System.assertEquals(2, allNewOrdersUrls.size());

		// GOOD RESPONSE
		Test.setMock(HttpCalloutMock.class, new TouchCRConfigurationMock(goodResponse));

		OrderDto orderDetail = apiConnector.getOrderDetail(allNewOrdersUrls[0]);
		System.assertEquals('593377372222@customer.jet.com', orderDetail.hash_email);

		List<Log__c> logs = apiConnector.getLogs();
		// logs: 1 token, get all orders, get order detail callouts
		System.assertEquals(3, logs.size());


		// get 2nd order detail, no token callout should occur
		Test.setMock(HttpCalloutMock.class, new TouchCRConfigurationMock(badResponse));

		orderDetail = apiConnector.getOrderDetail(allNewOrdersUrls[1]);
		System.assertEquals('468386143480@customer.jet.com', orderDetail.hash_email);

		logs = apiConnector.getLogs();
		System.assertEquals(1, logs.size());

	}

	static testMethod void test_api_badresponses() {

		String invalidTokenResponse = '';
		Test.setMock(HttpCalloutMock.class, new TouchCRConfigurationMock(invalidTokenResponse));

		JetApi apiConnector = new JetApi();
		Map<String, String> payloadDataAuthTemp = new Map<String, String>{
			'user' => null,
			'pass' => null
		};
		apiConnector.setAuthCredentials(payloadDataAuthTemp);
		String authToken = apiConnector.getToken();
		// null token means something went wrong or wrong creds
		System.assertEquals(null, authToken);

		List<Log__c> logs = apiConnector.getLogs();
		// 2logs, 1st token request, 2nd error parsing token from response
		System.assertEquals(2, logs.size());
		System.assertEquals('Success', logs[0].Event_Status__c);
		System.assertEquals('Error', logs[1].Event_Status__c);

		// having null token will fail other callouts from being called
		String invalidOrdersResponse = '{"Message":"Authorization has been denied for this request."}';
		Test.setMock(HttpCalloutMock.class, new TouchCRConfigurationMock(invalidOrdersResponse));

		List<String> allOrdersUrls = apiConnector.getAllOrders();

		// without token new error logs appear
		logs = apiConnector.getLogs();
		System.assertEquals(1, logs.size());
		System.assertEquals('Error', logs[0].Event_Status__c);

		// check do we have some orders in a system
		List<String> allNewOrdersUrls = JetApiBatch.getJetOrderUrls(allOrdersUrls);
		// having empty list of all orders means no new orders or smth is broken and the other things will not happen
		System.assertEquals(0, allNewOrdersUrls.size());

		logs = apiConnector.getLogs();
		System.assertEquals(0, logs.size());

		// set exceptional response
		Test.setMock(HttpCalloutMock.class, new TouchCRConfigurationMock('404'));

		OrderDto orderDetail = apiConnector.getOrderDetail('123');
		System.assertEquals(null, orderDetail);
	}

	// BATCH
	static testMethod void test_batch() {
		// token, orderurls and order detail mocked
		String allInOneResponse = '{"order_urls":["/orders/withoutShipmentDetail/92c8837ea2024a33bfd6ed65f2fe64cd","/orders/withoutShipmentDetail/87a01daa85ba42a1ba6956ca89cc33b8"],"id_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IldscUZYb2E1WkxSQ0hldmxwa1BHOVdHS0JrMCJ9.eyJpc19zYW5kYm94X3VpZCI6InRydWUiLCJtZXJjaGFudF9pZCI6IjFmYjNkNzhhZDZjYTQwNTlhNWJmYzhkMGFiYWEwOTQ4IiwicGFydG5lcl90eXBlIjoiTWVyY2hhbnQiLCJzY29wZSI6Imlyb25tYW4tYXBpIiwiaXNzIjoiamV0LmNvbSIsImV4cCI6MTUxMTU0ODc4NSwibmJmIjoxNTExNTEyNzg1fQ.rPbXN67poLO9QoZQ0a2mo9bSD2IIwjP9RxqF93JOudnVQ2gk11UC1cG9nZWXB7FyvLCsU_PW6Y-ZZhLCCn4QHSiNatyIeSaZl21WELB2jc88i19L7ncSY40Wd1yFYqGMODyv3wW9Bj2ctgrFDX1sGHocB8-Ad9-ARhfRWM8Z-EeniFDWwbySWt3jmG8wStMpzVvIgy4LmVBafy6dAlq-QQcWkBw5KvCA2viJOWInC5WgMK7xj2ABcUfXcUwdt1mZKEkd49VleVujgdZF2vIEGeHKr7plVbjg7i2CMZvseXtFw89odCcVUqh5tRymyb4UzLvwtFDevewyUOS6KVDCqV_eK5b3gfokKOrJ8NWxEzQ67CEbztEGBZIepCn3scmJmVUEJ9xllE6dF-FXEZ83X1fvIKNRQKbrFs6ieUqpnJS_ld-SRWaDUAujo2YofNDh20D0RcpzPUCfIFY0r9Ge1ut9FTle1-FdoPs-5WwH6xREwMf9T8dohHq-4gCdaR8OmIm_zU9vHT1d7G8Usa3kUkkh-PM__LpGyxGj3se1T9L84PFVCZTk6nlvsqHmyUt8iikppU9fXXX75Yf3X9iMcBuNX-JhWCreaihH6DPgTH86nFv41moOcU0V8P12EqDCevl4qB91-iEqkfJ7r4bt7JFtrAEGYqD1uPfA6l7vQes","token_type":"Bearer","expires_on":"2017-11-24T18:39:45Z","acknowledgement_status":"accepted","alt_order_id":"787771772894","buyer":{"name":"Marge Simpson","phone_number":"212-212-4184"},"customer_reference_order_id":"705826727967","fulfillment_node":"b7d52ea7a11c4c9d9ba5c3d9589b5f70","has_shipments":false,"hash_email":"593377372222@customer.jet.com","jet_request_directed_cancel":false,"merchant_order_id":"92c8837ea2024a33bfd6ed65f2fe64cd","order_acknowledge_date":"2017-04-20T05:39:16Z","order_detail":{"request_shipping_method":"FedEx Ground","request_shipping_carrier":"FedEx","request_service_level":"Expedited","request_ship_by":"2017-04-21T05:39:15.1323097Z","request_delivery_by":"2017-04-22T05:39:15.1323097Z"},"order_items":[{"order_item_id":"2e3907ad994d48978c4eacf309f412b3","merchant_sku":"test_product","request_order_quantity":1,"request_order_cancel_qty":0,"item_tax_code":"","item_price":{"item_tax":null,"item_shipping_cost":2.28,"item_shipping_tax":null,"base_price":38},"product_title":"Cedcommerce Test Product","url":"http://www.jet.com/api/merchant_skus/test_product","order_item_acknowledgement_status":"fulfillable"}],"order_placed_date":"2017-04-20T05:38:15.1323097Z","order_totals":{"item_price":{"item_tax":null,"item_shipping_cost":2.28,"item_shipping_tax":null,"base_price":38}},"order_transmission_date":"2017-04-20T05:39:15.1323097Z","reference_order_id":"327731367779","shipments":[{"alt_shipment_id":"149266675696","carrier":"FedEx","carrier_pick_up_date":"2017-04-22T05:39:15.0000000-07:00","expected_delivery_date":"2017-04-22T05:39:15.0000000-07:00","response_shipment_date":"2017-04-22T05:39:15.0000000-07:00","response_shipment_method":"","ship_from_zip_code":"12345","shipment_id":"39260b41939140b5b0ef80f6e05e3eae","shipment_items":[{"merchant_sku":"test_product","response_shipment_sku_quantity":1,"response_shipment_cancel_qty":0,"RMA_number":"abcdef","days_to_return":30,"return_location":{"address1":"6909 South State Street","address2":"Suite C","city":"Midvale","state":"UT","zip_code":"84047"}}],"shipment_message_date":"2017-04-20T05:39:17Z","shipment_tracking_number":"14926667565454"}],"shipping_to":{"recipient":{"name":"Lisa Simpson","phone_number":"212-212-7726"},"address":{"address1":"45 Elm street","address2":"","city":"Burtons","state":"MS","zip_code":"38829"}},"status":"complete"}';
		Test.setMock(HttpCalloutMock.class, new TouchCRConfigurationMock(allInOneResponse));

		JetApiBatch testBatch = new JetApiBatch();

		Test.startTest();
		Database.executeBatch(testBatch);
		Test.stopTest();

		// 1 accounts, 1 orders, 1 transactions, 4 logs
		List<Account> accs = [SELECT Id FROM Account];
		System.assertEquals(1, accs.size());

		List<Order__c> orders = [SELECT Id FROM Order__c];
		System.assertEquals(1, orders.size());

		List<Order_Transaction__c> transactions = [SELECT Id FROM Order_Transaction__c];
		System.assertEquals(1, transactions.size());

		List<OrderItem__c> oitems = [SELECT Id FROM OrderItem__c];
		System.assertEquals(1, oitems.size());

		List<Log__c> logs = [SELECT Id FROM Log__c];
		System.assertEquals(4, logs.size());

	}

	static testMethod void test_sync_readyandnot() {
		// not ready, active connection missing
		System.assertEquals(false, JetApiProcessingHelper.isReadyToStart());

		TouchCRConnection__c testConnection = new TouchCRConnection__c(
			Name = 'test',
			Brand__c = 'testBrand',
			Feature__c = 'Jet',
			isActive__c = true
		);
		insert testConnection;

		List<TouchCRConnectionSetting__c> testSettings = new List<TouchCRConnectionSetting__c>();

		for (String aSetting : JetApiProcessingHelper.REQUIRED_SETTINGS) {
			TouchCRConnectionSetting__c testSetting = new TouchCRConnectionSetting__c(
				Name = aSetting,
				Value__c = 'test',
				TouchCRConnection__c = testConnection.Id
			);
			testSettings.add(testSetting);
		}
		insert testSettings;

		// ready
		System.assertEquals(true, JetApiProcessingHelper.isReadyToStart());

		Test.startTest();
		JetSyncAPIClient sc = new JetSyncAPIClient();
		String sch = Datetime.now().addMinutes(1).format('s m H d M ? yyyy');
		System.schedule('JetSyncAPIClient', sch, sc);
		// already inprogress
		Database.executeBatch(new JetSyncAPIClient());
		Test.stopTest();

		List<CronTrigger> crn = [
			SELECT Id
			FROM CronTrigger
			WHERE CronJobDetail.Name = 'JetSyncAPIClient'
		];

		List<AsyncApexJob> aaj = [
			SELECT Id
			FROM AsyncApexJob
			WHERE ApexClass.Name IN ('JetSyncAPIClient')
			AND JobType = 'BatchApex'
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
		];

		System.assertEquals(1, crn.size());
		System.assertEquals(1, aaj.size());

	}

}