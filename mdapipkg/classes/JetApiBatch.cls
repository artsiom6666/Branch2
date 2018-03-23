public with sharing class JetApiBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

	private JetApi apiConnector;

	public static final String ORDER_URL_SEPARATOR = '/orders/withoutShipmentDetail/';
	public String connectionName;
	public String brandName;
	public String salesfunnel;

	public Iterable<String> start(Database.BatchableContext BC) {
		apiConnector = new JetApi();

		Map<String, String> currentJetSettings = TouchCRHelper.getSettings('Jet.');

		this.connectionName = currentJetSettings.get('Jet.connectionname');
		this.brandName = currentJetSettings.get('Jet.brand');
		this.salesfunnel = currentJetSettings.get('Jet.salesfunnel');

		apiConnector.setAuthCredentials(new Map<String, String>{
			JetApi.AUTH_USER => currentJetSettings.get('Jet.' + JetApi.AUTH_USER),
			JetApi.AUTH_PASS => currentJetSettings.get('Jet.' + JetApi.AUTH_PASS)
		});

		List<String> ordersUrls = apiConnector.getAllOrders();

		// check if there are new orders and return only new ones
		return getJetOrderUrls(ordersUrls);
	}

	public void execute(Database.BatchableContext BC, List<String> theData) {
		// FIXME
		if (theData.size() < 1) {
			return;
		}
		String orderUrl = theData[0];
		// callout, mocked
		OrderDto jetOrder = apiConnector.getOrderDetail(orderUrl);

		// CUSTOMER
		Account aCustomer = getJetCustomer(jetOrder);

		// PRODUCT
		// only add new products with pbe
		List<SObject> products = getJetProducts(jetOrder);

		// ORDER
		// at this point we should only have new orders, existing ones checked in start by getNewOrderUrls()
		SObject aOrder = getJetOrder(jetOrder);

		// ORDER ITEMS
		List<SObject> oItems = getJetOrderItems(jetOrder);

		// ORDER TRANSACTION
		SObject aTransaction = getJetTransaction(jetOrder);

		// DML
		List<SObject> objList = new List<SObject>();
		upsert aCustomer JetAccountId__c;
		objList.addAll(products);
		objList.add(aOrder);
		objList.add(aTransaction);
		objList.addAll(oItems);
		insert objList;

	}

	public void finish(Database.BatchableContext BC) {

		insert apiConnector.getLogs();
		System.enqueueJob(new JetApiConnectionManager());
	}

	// input List of order urls returned by jet api
	// output new order urls
	public static List<String> getJetOrderUrls(List<String> allOrdersStrings) {
		List<String> result = new List<String>();
		// Map order url to extertnal id, {87a01daa85ba42a1ba6956ca89cc33b8} => {/orders/withoutShipmentDetail/87a01daa85ba42a1ba6956ca89cc33b8}
		Map<String, String> orderUrl2OrderIdMap = new Map<String, String>();
		for (String orderUrl : allOrdersStrings) {
			orderUrl2OrderIdMap.put(orderUrl.substringAfter(ORDER_URL_SEPARATOR), orderUrl);
		}
		// assume jet order external id is unique across all jet
		List<Order__c> orders = [
			SELECT Id, Connected_Id__c
			FROM Order__c
			WHERE Connected_Id__c IN :orderUrl2OrderIdMap.keySet()
		];

		// same sizes GT 0 means we already have all orders in SF, skip
		if (orderUrl2OrderIdMap.size() > 0 && orderUrl2OrderIdMap.size() != orders.size()) {
			Set<String> exisitingOrdersIds = new Set<String>();
			// collect exisitng order exteral ids
			for (Order__c aOrder : orders) {
				exisitingOrdersIds.add(aOrder.Connected_Id__c);
			}
			// comapare and search for non existing orders, collect new ids
			for (String orderId : orderUrl2OrderIdMap.keySet()) {
				if (!exisitingOrdersIds.contains(orderId)) {
					result.add(orderUrl2OrderIdMap.get(orderId));
				}
			}
		}
		return result;
	}

	/**
	Return an instance of account with filled external id, it doesn't care if it is new or exisitng account for upsert
	There is no much info from Jet about customer, as en email, so we can't rely on email to find exisitng accounts
	 */
	public Account getJetCustomer(OrderDto jetOrder) {
		Account result = new Account();
		// add record Type
		RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Customer_Account' AND IsPersonType = true];
		result.RecordTypeId = customerRecordType.Id;
		// assume hash_email is always present in a response
		result.JetAccountId__c = jetOrder.hash_email;
		// in case we didnt find any valid flnames
		result.LastName = jetOrder.hash_email;

		if (jetOrder.buyer != null) {
			if (jetOrder.buyer.name != null) {
				Boolean isFirstLastNamePattern = Pattern.matches('\\w+ \\w+', jetOrder.buyer.name);
				if (isFirstLastNamePattern) {
					result.LastName = jetOrder.buyer.name.substringAfter(' ');
					result.FirstName = jetOrder.buyer.name.substringBefore(' ');
				}
				else {
					result.LastName = jetOrder.buyer.name;
				}
			}
			if (jetOrder.buyer.phone_number != null) {
				result.Phone = jetOrder.buyer.phone_number;
			}
		}
		// connection specific
		result.sales_funnel_name__c = connectionName;
		result.Brand_Assortment__c = brandName;

		return result;
	}
	// only new products
	public List<SObject> getJetProducts(OrderDto jetOrder) {
		// skip exisitng products at all
		List<SObject> result = new List<SObject>();
		Map<String, SObject> jetIdProduct = new Map<String, SObject>();
		Map<String, SObject> jetIdPbe = new Map<String, SObject>();

		if (jetOrder.order_items != null) {
			// create ALL Products, after we'll check if some of them exists
			for (OrderDto.OrderItem jetOrderItem : jetOrder.order_items) {
				Product2 aProduct = new Product2(
					Name = jetOrderItem.product_title,
					Connected_Id__c = jetOrderItem.merchant_sku,
					Connection_Name__c = connectionName,
					Family = brandName,
					IsActive = true
				);
				Product2 aProductRef = new Product2(
					Connected_Id__c = jetOrderItem.merchant_sku
				);
				PricebookEntry pbe = new PricebookEntry(
					Product2 = aProductRef,
					Pricebook2Id = getStdPriceBookId(),
					UnitPrice = getOrderItemSubtotal(jetOrderItem),
					IsActive = true
				);

				jetIdProduct.put(jetOrderItem.merchant_sku, aProduct);
				jetIdPbe.put(jetOrderItem.merchant_sku, pbe);
			}
			List<Product2> exisitingProducts = [SELECT Id, Connected_Id__c FROM Product2 WHERE Connected_Id__c IN :jetIdProduct.keySet()];
			for (Product2 aProduct : exisitingProducts) {
				jetIdProduct.remove(aProduct.Connected_Id__c);
				jetIdPbe.remove(aProduct.Connected_Id__c);
			}
			// map will hold only new products
			if (!jetIdProduct.isEmpty()) {
				result.add(jetIdProduct.values());
				result.add(jetIdPbe.values());
			}
		}
		return result;
	}

	// order amounts calculated from otems, in case exceptional orders which do not have order_totals
	// orders with not empty exception_state considered as refunded, but should be stored in sf to prevent fetching them every time
	public SObject getJetOrder(OrderDto jetOrder) {
		Account accRef = new Account(JetAccountId__c = jetOrder.hash_email);

		Order__c result = new Order__c();
		result.Account__r = accRef;
		result.Date__c = jetOrder.order_placed_date;
		result.Connected_Id__c = jetOrder.merchant_order_id;
		result.Connection_Name__c = connectionName;
		result.Brand__c = brandName;
		result.Sales_Funnel_Name__c = salesfunnel;


		result.Subtotal__c = getOrderSubtotal(jetOrder);
		result.Tax__c = getOrderTax(jetOrder);
		result.Shipping__c = getOrderShipping(jetOrder);
		result.OrderNumber__c = jetOrder.reference_order_id;

		result.Order_Information__c = jetOrder.exception_state;

		result.Shipping_Name__c = jetOrder.shipping_to.recipient.name;
		result.Shipping_Address__c = jetOrder.shipping_to.address.address1;
		result.Shipping_City__c = jetOrder.shipping_to.address.city;
		result.Shipping_State__c = jetOrder.shipping_to.address.state;
		result.Shipping_Zip_Postal__c = jetOrder.shipping_to.address.zip_code;

		if (jetOrder.exception_state == null) {
			result.Status__c = 'Completed';
			result.Payment_Received__c = 'Full';
		}
		else {
			result.Status__c = 'Canceled';
		}
		return result;
	}

	public List<SObject> getJetOrderItems(OrderDto jetOrder) {
		// Order ref
		Order__c orderRef = new Order__c(Connected_Id__c = jetOrder.merchant_order_id);

		List<OrderItem__c> result = new List<OrderItem__c>();
		if (jetOrder.order_items != null) {
			for (OrderDto.OrderItem jetOrderItem : jetOrder.order_items) {

				Product2 prodRef = new Product2(Connected_Id__c = jetOrderItem.merchant_sku);

				OrderItem__c aOrderItem = new OrderItem__c();
				aOrderItem.Order__r = orderRef;
				aOrderItem.Product__r = prodRef;
				aOrderItem.Quantity__c = getOrderItemQuantity(jetOrderItem);
				aOrderItem.Product_Price__c = getOrderItemSubtotal(jetOrderItem);
				result.add(aOrderItem);
			}
		}
		return result;
	}

	public SObject getJetTransaction(OrderDto jetOrder) {
		// Order ref
		Order__c orderRef = new Order__c(Connected_Id__c = jetOrder.merchant_order_id);

		Order_Transaction__c result = new Order_Transaction__c();
		result.Order__r = orderRef;
		result.Payment_Date__c = jetOrder.order_transmission_date;
		result.Response_Status__c = 'Approved';

		result.Amount__c = getOrderAmountToCharge(jetOrder);

		if (jetOrder.exception_state == null) {
			result.Type__c = 'Charge';
		}
		else {
			result.Type__c = 'Refund';
		}
		return result;
	}

	// HELPERS
	public static Double getOrderSubtotal(OrderDto jetOrder) {
		Double result = 0;
		for (OrderDto.OrderItem jetOrderItem : jetOrder.order_items) {
			result += getOrderItemSubtotal(jetOrderItem);
		}
		return result;
	}

	public static Double getOrderItemSubtotal(OrderDto.OrderItem jetOrderItem) {
		Double result = 0;
		result += ((jetOrderItem.item_price.base_price != null) ? jetOrderItem.item_price.base_price : 0) * getOrderItemQuantity(jetOrderItem);
		return result;
	}

	public static Double getOrderItemQuantity(OrderDto.OrderItem jetOrderItem) {
		Double result = 0;
		if (jetOrderItem.request_order_quantity != null && jetOrderItem.request_order_quantity > 0) {
			result = jetOrderItem.request_order_quantity;
		}
		else if (jetOrderItem.request_order_cancel_qty != null && jetOrderItem.request_order_cancel_qty > 0) {
			result = jetOrderItem.request_order_cancel_qty;
		}
		return result;
	}

	public static Double getOrderTax(OrderDto jetOrder) {
		Double result = 0;
		for (OrderDto.OrderItem jetOrderItem : jetOrder.order_items) {
			result += getOrderItemTax(jetOrderItem);
		}
		return result;
	}

	public static Double getOrderItemTax(OrderDto.OrderItem jetOrderItem) {
		Double result = 0;
		result += (jetOrderItem.item_price.item_tax != null) ? jetOrderItem.item_price.base_price : 0;
		return result;
	}

	public static Double getOrderShipping(OrderDto jetOrder) {
		Double result = 0;
		for (OrderDto.OrderItem jetOrderItem : jetOrder.order_items) {
			result += getOrderItemShipping(jetOrderItem);
		}
		return result;
	}

	public static Double getOrderItemShipping(OrderDto.OrderItem jetOrderItem) {
		Double result = 0;
		result += (jetOrderItem.item_price.item_shipping_cost != null) ? jetOrderItem.item_price.item_shipping_cost : 0;
		result += (jetOrderItem.item_price.item_shipping_tax != null) ? jetOrderItem.item_price.item_shipping_tax : 0;
		return result;
	}

	public static Double getOrderAmountToCharge(OrderDto jetOrder) {
		return getOrderSubtotal(jetOrder) + getOrderTax(jetOrder) + getOrderShipping(jetOrder);
	}

	public static Id getStdPriceBookId() {
		if (Test.isRunningTest()) {
			return Test.getStandardPricebookId();
		}
		else {
			return [SELECT Id from Pricebook2 WHERE isStandard = true LIMIT 1].Id;
		}
	}

}