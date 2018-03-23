public with sharing class JetApi {

	// CONNECTION
	public static String REQUEST_GET = 'GET';
	public static String REQUEST_POST = 'POST';

	public static String ENDPOINT = 'callout:JetApi';
	public static String ENDPOINT_PROXY = 'callout:SecureProxy';

	public static String ENDPOINT_AUTH = '/token';
	public static String ENDPOINT_SKUS = '/merchant-skus/';
	public static String ENDPOINT_ORDERS = '/orders/complete';

	public static String CONTENT_KEY = 'Content-Type';
	public static String CONTENT_TYPE = 'application/json';

	public static String AUTH_KEY = 'Authorization';
	public static String AUTH_TYPE = 'Bearer ';

	public static String AUTH_USER = 'user';
	public static String AUTH_PASS = 'pass';

	public static String LOG_TYPE = 'Jet.com';
	public static String LOG_S_STATUS = 'Success';
	public static String LOG_E_STATUS = 'Error';

	// CONSTRUCTOR
	public JetApi(String endpoint) {
		this.apiUrl = endpoint;
	}

	public JetApi() {
		this(ENDPOINT);
	}

	// privates
	private String apiUrl;

	private Boolean isFirstAuthAttempt = true;
	private String authToken;

	private List<Log__c> apiLogs = new List<Log__c>();

	private Integer rawResponseCode;
	private String rawResponse;

	public static Map<String, String> payloadDataAuth = new Map<String, String>{
		AUTH_USER => '',
		AUTH_PASS => ''
	};

	// Callout
	private HTTPResponse doCallout(HttpRequest request) {
		HTTPResponse response;

		Http http = new Http();
		try {
			response = http.send(request);
		}
		catch (Exception e) {
			response = new HTTPResponse();
			response.setStatusCode(999);
			response.setBody(e.getMessage() + '\n' + e.getStackTraceString());
		}
		apiLogs.add(createLog(request, response));
		return response;
	}

	// Auth callout wrapper, set token if not set
	private HTTPResponse doAuthCallout(HttpRequest request) {
		String token = getToken();
		if (token == null) {
			return new HttpResponse();
		}
		// set default headers for all requests
		request.setHeader(CONTENT_KEY, CONTENT_TYPE);
		request.setHeader(AUTH_KEY, AUTH_TYPE + token);
		return doCallout(request);
	}

	private static Log__c createLog(String e) {
		Log__c result = new Log__c();
		result.Event_Type__c = LOG_TYPE;
		result.Event_Status__c = LOG_E_STATUS;
		result.Type__c = 'Parser';
		result.Event_Description__c = e;
		return result;
	}

	private static Log__c createLog(HttpRequest request, HttpResponse response) {
		Log__c result = new Log__c();
		result.Event_Type__c = LOG_TYPE;
		Integer reqStatusCode = response.getStatusCode();
		if (reqStatusCode >= 200 && reqStatusCode < 300) {
			result.Event_Status__c = LOG_S_STATUS;
		}
		else {
			result.Event_Status__c = LOG_E_STATUS;
		}
		result.Event_Description__c = response.getBody();
		result.Event_Endpoint__c = request.getEndpoint().abbreviate(32786);
		return result;
	}

	// REQUESTS
	// All requests rely on valid token, first request is trying to receive token, if it is succesfull all other
	// requests will use it, it it is not, no additional requests are being made

	/**
	Set it as testvisible to be able to mock different responses in one go.
	 */
	@TestVisible
	private String getToken() {
		// is first attempt to get token do real callout
		if (isFirstAuthAttempt) {
			HttpRequest request = new HttpRequest();
			request.setEndpoint(apiUrl + ENDPOINT_AUTH);
			request.setMethod(REQUEST_POST);
			request.setHeader(CONTENT_KEY, CONTENT_TYPE);
			request.setBody(JSON.serialize(payloadDataAuth));

			HTTPResponse response = doCallout(request);

			rawResponseCode = response.getStatusCode();
			rawResponse = response.getBody();
			// switch auth flag here
			this.isFirstAuthAttempt = false;
			this.authToken = parseToken(rawResponse);
			return this.authToken;
		}
		else {
			// all other attempts return stored value
			return this.authToken;
		}
	}

	public List<String> getAllOrders() {
		HttpRequest request = new HttpRequest();
		request.setEndpoint(apiUrl + ENDPOINT_ORDERS);
		request.setMethod(REQUEST_GET);

		HTTPResponse response = doAuthCallout(request);

		rawResponseCode = response.getStatusCode();
		rawResponse = response.getBody();
		return parseAllOrderUrls(rawResponse);
	}

	public OrderDto getOrderDetail(String orderUrl) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint(apiUrl + orderUrl);
		request.setMethod(REQUEST_GET);

		HTTPResponse response = doAuthCallout(request);

		rawResponseCode = response.getStatusCode();
		rawResponse = response.getBody();
		return parseOrderDetail(rawResponse);
	}

	// getting logs, flushes logs list
	public List<Log__c> getLogs() {
		List<Log__c> logsToReturn = this.apiLogs.clone();
		this.apiLogs = new List<Log__c>();
		return logsToReturn;
	}

	// PRIVATE HELPER METHODS
	private String parseToken(String rawResponse) {
		String result;
		try {
			ResponseAuth pResponse = (ResponseAuth) JSON.deserialize(rawResponse, ResponseAuth.class);
			result = pResponse.id_token;
		}
		catch (Exception e) {
			this.apiLogs.add(createLog(e.getStackTraceString()));
		}
		return result;
	}

	@TestVisible
	private List<String> parseAllOrderUrls(String rawResponse) {
		List<String> result = new List<String>();
		try {
			ResponseOrderUrls pResponse = (ResponseOrderUrls) JSON.deserialize(rawResponse, ResponseOrderUrls.class);

			if (pResponse.order_urls != null) {
				for (String orderUrl : pResponse.order_urls) {
					result.add(orderUrl);
				}
			}
		}
		catch (Exception e) {
			this.apiLogs.add(createLog(e.getStackTraceString()));
		}
		return result;
	}

	private OrderDto parseOrderDetail(String rawResponse) {
		OrderDto result;
		try {
			result = (OrderDto) JSON.deserialize(rawResponse, OrderDto.class);
		}
		catch (Exception e) {
			this.apiLogs.add(createLog(e.getStackTraceString()));
		}
		return result;
	}

	// PUBLIC SETTERS
	public JetApi setAuthCredentials(Map<String, String> authCreds) {
		payloadDataAuth.put(AUTH_USER, authCreds.get(AUTH_USER));
		payloadDataAuth.put(AUTH_PASS, authCreds.get(AUTH_PASS));
		return this;
	}

	// JET API DTO
	public class ResponseAuth {
		public Datetime expires_on { get; set; }
		public String id_token { get; set; }
		public String token_type { get; set; }
	}

	public class ResponseOrderUrls {
		public List<String> order_urls { get; set; }
	}

}