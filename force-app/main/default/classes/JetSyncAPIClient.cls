global with sharing class JetSyncAPIClient implements Schedulable, Database.Batchable<sObject> {

	/**
	 * Global Jet connector manager
	 * This is entry point for Jet
	 *
	 * It is scheduled or executed on conf page
	 */

	public void execute(SchedulableContext sc) {
		if (JetApiProcessingHelper.isReadyToStart()) {
			JetSyncAPIClient b = new JetSyncAPIClient();
			Database.executebatch(b);
		}
	}

	public Iterable<sObject> start(Database.BatchableContext BC) {
		return new List<sObject>();
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {}

	public void finish(Database.BatchableContext BC) {

		if (JetApiProcessingHelper.isReadyToStart()) {

			Log__c log = new Log__c();
			log.Event_Type__c = 'Jet.com';
			log.Event_Status__c = 'Success';
			log.Event_Description__c = 'Jet Sync is ready to start.';

			if (Log__c.Event_Type__c.getDescribe().isCreateable() &&
				Log__c.Event_Description__c.getDescribe().isCreateable() &&
				Log__c.Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}

			/* in case smth went wrong, and we are going to start connector, clean prev settings */
			JetApiProcessingHelper.cleanConnectionSettings();

			System.enqueueJob(new JetApiConnectionManager());
		}
		else {

			Log__c log = new Log__c();
			log.Event_Type__c = 'Jet.com';
			log.Event_Status__c = 'Warning';
			log.Event_Description__c = 'Jet Sync is not ready to start.\nJet active connection missing OR Sync already in progress.';

			if (Log__c.Event_Type__c.getDescribe().isCreateable() &&
				Log__c.Event_Description__c.getDescribe().isCreateable() &&
				Log__c.Event_Status__c.getDescribe().isCreateable()) {
				insert log;
			}
		}
	}
}