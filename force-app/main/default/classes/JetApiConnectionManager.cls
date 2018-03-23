public with sharing class JetApiConnectionManager implements Queueable {

	/**
	 * This is start point for each Jet connection
	 * @return execute first batch
	 */

	public void execute(QueueableContext context) {
		String prevConnectionId = JetApiProcessingHelper.getPrevConnectionId();

		// get already processed conections
		Set<String> processedConnections = JetApiProcessingHelper.getProcessedConnectionsIds();

		Set<String> allActiveConnections = JetApiProcessingHelper.getActiveConnectionsIds();

		if (prevConnectionId != null) {
			// not first iteration
			JetApiProcessingHelper.saveSettingsForConnection(prevConnectionId);
			processedConnections.add(prevConnectionId);

			Log__c log3 = new Log__c();
			log3.Event_Type__c = 'Jet.com';
			log3.Event_Status__c = 'In Progress';
			log3.Event_Description__c = 'Saved settings for: '
				+ TouchCRHelper.getSettings('Jet.brand').get('Jet.brand') + '\n'
				+ 'prevConnectionId: ' + prevConnectionId + '\n'
				+ 'processedConnections: ' + processedConnections + '\n'
				+ 'allActiveConnections: ' + allActiveConnections;
			if (Log__c.Event_Type__c.getDescribe().isCreateable() &&
				Log__c.Event_Description__c.getDescribe().isCreateable() &&
				Log__c.Event_Status__c.getDescribe().isCreateable()) {
				insert log3;
			}
		}
		// unprocessed connection left?
		allActiveConnections.removeAll(processedConnections);

		if (allActiveConnections.isEmpty()) {
			Log__c log2 = new Log__c();
			log2.Event_Type__c = 'Jet.com';
			log2.Event_Status__c = 'Finished';
			log2.Event_Description__c = 'Done\n' +
				+'prevConnectionId: ' + prevConnectionId + '\n'
				+ 'processedConnections: ' + processedConnections + '\n'
				+ 'allActiveConnections: ' + allActiveConnections;
			if (Log__c.Event_Type__c.getDescribe().isCreateable() &&
				Log__c.Event_Description__c.getDescribe().isCreateable() &&
				Log__c.Event_Status__c.getDescribe().isCreateable()) {
				insert log2;
			}

			JetApiProcessingHelper.cleanConnectionSettings();
			return;
		}

		// smth left for processing
		String connectionToProcess = new List<String>(allActiveConnections).get(0);

		JetApiProcessingHelper.setPrevConnectionId(connectionToProcess);
		JetApiProcessingHelper.setPorcessedConnectionsIds(processedConnections);
		//
		if (JetApiProcessingHelper.loadSettingsForConnection(connectionToProcess)) {
			Log__c log1 = new Log__c();
			log1.Event_Type__c = 'Jet.com';
			log1.Event_Status__c = 'In Progress';
			log1.Event_Description__c = 'Loaded settings for: '
				+ TouchCRHelper.getSettings('Jet.brand').get('Jet.brand') + '\n'
				+ 'prevConnectionId: ' + prevConnectionId + '\n'
				+ 'processedConnections: ' + processedConnections + '\n'
				+ 'allActiveConnections: ' + allActiveConnections + '\n'
				+ 'connectionToProcess: ' + connectionToProcess;
			if (Log__c.Event_Type__c.getDescribe().isCreateable() &&
				Log__c.Event_Description__c.getDescribe().isCreateable() &&
				Log__c.Event_Status__c.getDescribe().isCreateable()) {
				insert log1;
			}
			Database.executeBatch(new JetApiBatch(), 1);
		}
	}

}