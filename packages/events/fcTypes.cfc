component {
	
	variables.solrProEventHandler = createObject("component","farcry.plugins.farcrysolrpro.packages.custom.eventHandler");

	public void function saved(required string typename, required any oType, required struct stProperties, required string user, required string auditNote, required boolean bSessionOnly, required boolean bAfterSave) {
		if (arguments.bAfterSave) {
			variables.solrProEventHandler.afterSave(stProperties = arguments.stProperties);
		}
	}

	public void function deleted(required string typename, required any oType, required struct stObject, required string user, required string auditNote) {
		variables.solrProEventHandler.onDelete(typename = arguments.typename, stObject = arguments.stObject);
	}

}