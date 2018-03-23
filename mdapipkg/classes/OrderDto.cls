public with sharing class OrderDto {

	public String merchant_order_id { get; set; }
	public String reference_order_id { get; set; }
	public String hash_email { get; set; }
	public String status { get; set; }
	public String exception_state { get; set; }

	public Datetime order_placed_date { get; set; }
	public Datetime order_transmission_date { get; set; }


	public Customer buyer { get; set; }
	public List<OrderItem> order_items { get; set; }
	public OrderTotals order_totals { get; set; }
	public OrderShippingTo shipping_to { get; set; }

	public class Customer {
		public String name { get; set; }
		public String phone_number { get; set; }
	}

	public class OrderItem {
		public String order_item_id { get; set; }
		public String merchant_sku { get; set; }
		public String product_title { get; set; }

		public Integer request_order_quantity { get; set; }
		public Integer request_order_cancel_qty { get; set; }

		public ItemPrice item_price { get; set; }
	}

	public class OrderTotals {
		public ItemPrice item_price { get; set; }
	}

	public class OrderShippingTo {
		public Customer recipient { get; set; }
		public SAddress address { get; set; }
	}

	public class SAddress {
		public String address1 { get; set; }
		public String city { get; set; }
		public String state { get; set; }
		public String zip_code { get; set; }
	}

	public class ItemPrice {
		public Double base_price { get; set; }
		public Double item_tax { get; set; }
		public Double item_shipping_cost { get; set; }
		public Double item_shipping_tax { get; set; }
	}

}