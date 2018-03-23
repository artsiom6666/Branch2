public with sharing class JetApiProcessingHelper {

	public static final String FEATURENAME = 'Jet';

	public static final Set<String> BATCHES = new Set<String>{
		'JetApiConnectionManager', 'JetApiBatch'
	};

	public static final Set<String> REQUIRED_SETTINGS = new Set<String>{
		'Jet.salesfunnel',
		'Jet.' + JetApi.AUTH_USER,
		'Jet.' + JetApi.AUTH_PASS
	};

	public static Boolean isReadyToStart() {
		return (!JetApiProcessingHelper.isSyncInProgress() && JetApiProcessingHelper.hasActiveConnections());
	}

	public static Boolean hasActiveConnections() {
		return !getActiveConnectionsIds().isEmpty();
	}

	public static Boolean isSyncInProgress() {
		return ![
			SELECT Id, Status, ApexClass.Name
			FROM AsyncApexJob
			WHERE ApexClass.Name IN :BATCHES
			AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
		].isEmpty();
	}


	//SAVE 'N LOAD
	public static Boolean loadSettingsForConnection(String connectionId) {
		// get persisted settings from connection
		TouchCRConnection__c persistedConnection = getConnectionById(connectionId);

		if (persistedConnection == null) {
			return false;
		}

		// collect persisted settings
		Map<String, String> connectionSettingsMap = new Map<String, String>();
		for (TouchCRConnectionSetting__c connSet : persistedConnection.TouchCRConnectionSettings__r) {
			connectionSettingsMap.put(connSet.Name, connSet.Value__c);
		}

		// prepare settings to load
		Map<String, String> setting = new Map<String, String>();
		// add settings from top level coonection
		setting.put('Jet.brand', persistedConnection.Brand__c);
		setting.put('Jet.connectionname', persistedConnection.Name);
		// add required settings from related connection settings
		for (String aSetting : REQUIRED_SETTINGS) {
			//check if all required settings are available
			if (connectionSettingsMap.containsKey(aSetting)) {
				setting.put(aSetting, connectionSettingsMap.get(aSetting));
			}
			else {
				return false;
			}
		}

		TouchCRHelper.setSettings(setting);

		return true;
	}

	public static Boolean saveSettingsForConnection(String connectionId) {
		// get persisted settings from connection
		TouchCRConnection__c persistedConnection = getConnectionById(connectionId);
		// get settings
		Map<String, String> currentSettings = TouchCRHelper.getSettings('Jet.');

		if (persistedConnection == null) {
			return false;
		}

		List<TouchCRConnectionSetting__c> settingsToUpdate = new List<TouchCRConnectionSetting__c>();

		// hold ids for connsettings for update
		Map<String, TouchCRConnectionSetting__c> connectionSettingsMap = new Map<String, TouchCRConnectionSetting__c>();
		for (TouchCRConnectionSetting__c connSet : persistedConnection.TouchCRConnectionSettings__r) {
			connectionSettingsMap.put(connSet.Name, connSet);
		}

		//check if all required settings are available
		for (String aSetting : REQUIRED_SETTINGS) {
			if (connectionSettingsMap.containsKey(aSetting)) {
				TouchCRConnectionSetting__c updatedSetting = connectionSettingsMap.get(aSetting);
				updatedSetting.Value__c = currentSettings.get(aSetting);
				settingsToUpdate.add(updatedSetting);
			}
			else {
				return false;
			}
		}
		Boolean isSettingsUpdateable = (
			TouchCRConnection__c.getSObjectType().getDescribe().isUpdateable() && // master object
				TouchCRConnectionSetting__c.getSObjectType().getDescribe().isUpdateable() && // detail object
				TouchCRConnectionSetting__c.Value__c.getDescribe().isUpdateable() && // detail object field
				TouchCRConnectionSetting__c.Name.getDescribe().isUpdateable() // detail object field
		);

		if (isSettingsUpdateable) {
			Database.update(settingsToUpdate, true);
			return true;
		}
		else {
			throw new PrivilegesException('Privileges Exception');
		}

		return false;
	}


	// GETTERS
	public static TouchCRConnection__c getConnectionById(String connectionId) {
		TouchCRConnection__c persistedConnection = [
			SELECT Name, Feature__c, Brand__c, (SELECT Id, Name, Value__c FROM TouchCRConnectionSettings__r)
			FROM TouchCRConnection__c
			WHERE Id = :connectionId
		];
		return (persistedConnection == null || persistedConnection.TouchCRConnectionSettings__r.isEmpty()) ? null : persistedConnection;
	}

	public static Set<String> getActiveConnectionsIds() {
		return new Map<String, TouchCRConnection__c>([
			SELECT Id
			FROM TouchCRConnection__c
			WHERE Feature__c = :FEATURENAME
			AND isActive__c = true
			ORDER BY Order__c ASC NULLS LAST, Brand__c ASC
		]).keySet();
	}

	public static String getPrevConnectionId() {
		return TouchCRHelper.getSettings('Jet.PrevConnectionId').get('Jet.PrevConnectionId');
	}

	public static Set<String> getProcessedConnectionsIds() {
		String result = TouchCRHelper.getSettings('Jet.ProcessedConnectionsIds').get('Jet.ProcessedConnectionsIds');
		return (result != null) ? new Set<String>(result.split(';')) : new Set<String>();
	}

	// SETTERS
	public static void cleanConnectionSettings() {
		TouchCRHelper.setSettings(
			new Map<String, String>{
				'Jet.PrevConnectionId' => null,
				'Jet.ProcessedConnectionsIds' => null
			}
		);
	}

	public static void setPrevConnectionId(String prevConnectionId) {
		TouchCRHelper.setSettings(
			new Map<String, String>{
				'Jet.PrevConnectionId' => prevConnectionId
			}
		);
	}

	public static void setPorcessedConnectionsIds(Set<String> processedConnections) {
		TouchCRHelper.setSettings(
			new Map<String, String>{
				'Jet.ProcessedConnectionsIds' => String.join(new List<String>(processedConnections), ';')
			}
		);
	}


	public with sharing class PrivilegesException extends Exception {
	}

}