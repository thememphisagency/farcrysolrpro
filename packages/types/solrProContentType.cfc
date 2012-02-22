<cfcomponent output="false" extends="farcry.core.packages.types.types" displayname="Solr Pro Content Type" hint="Manages content type index information" bFriendly="false" bObjectBroker="true">
	
	<cfproperty ftSeq="110" ftFieldset="Solr Content Type" ftLabel="Title" name="title" bLabel="true" ftType="string" type="nstring" required="true" ftValidation="required" ftHint="The name of this content type.  This will appear on the search form and will allow users to search a specific content type." />
	<cfproperty ftSeq="120" ftFieldset="Solr Content Type" ftLabel="Content Type" name="contentType" ftType="list" type="nstring" ftListData="getContentTypes" ftRenderType="dropdown" required="true" ftValidation="required" ftHint="The content type being indexed." />
	
	<cfproperty ftSeq="130" ftFieldset="Solr Content Type" ftLabel="Result Title" name="resultTitleField" ftType="list" type="nstring" required="true" default="label" ftDefault="label" ftValidation="required" ftHint="The field that will be used for the search result title." />
	<cfproperty ftSeq="140" ftFieldset="Solr Content Type" ftLabel="Result Summary" name="resultSummaryField" ftType="list" type="nstring" required="false" default="" ftDefault="" ftHint="The field that will be used for the search result summary." />
	<cfproperty ftSeq="142" ftFieldset="Solr Content Type" ftLabel="Summary Fields" name="lSummaryFields" ftType="list" ftAllowMultiple="true" type="longchar" required="false" default="" ftHint="The fields to use to build the summary" />
	<cfproperty ftSeq="150" ftFieldset="Solr Content Type" ftLabel="Result Image" name="resultImageField" ftType="list" type="nstring" required="false" default="" ftDefault="" ftHint="The field that will be used for the search result teaser image." />
	
	<cfproperty ftSeq="150" ftFieldset="Solr Content Type" ftLabel="Enable Site Search?" name="bEnableSearch" ftType="boolean" type="boolean" required="true" default="1" ftDefault="1" ftHint="Should this content type be included in the global, site-wide search?" />
	<cfproperty ftSeq="160" ftFieldset="Solr Content Type" ftLabel="Built to Date" name="builtToDate" ftType="datetime" type="date" required="false" ftHint="For system use.  Updated by the system.  Used as a reference date of the last indexed item.  Used for batching when indexing items.  Default is blank (no date)." />
	<cfproperty ftSeq="165" ftFieldset="Solr Content Type" ftLabel="Default Document Boost" name="defaultDocBoost" ftType="list" ftListData="getBoostOptions" ftListDataTypename="solrProDocumentBoost" type="numeric" required="true" ftHint="The default document boost for all documents of this content type.  Use this to boost (or lower) all documents of a specific type." />
	
	<cfproperty ftSeq="170" ftFieldset="Solr Content Type" ftLabel="Indexed Properties" name="aIndexedProperties" ftType="array" type="array" ftJoin="solrProIndexedProperty" ftHint="The properties for this content type that will be indexed." />
	
	<cfproperty ftSeq="180" ftFieldset="Solr Content Type" ftLabel="Index Rule Data?" name="bIndexRuleData" ftType="boolean" type="boolean" default="0" ftDefault="0" ftHint="You can choose to disable this feature and still preserve your settings below." />
	<cfproperty ftSeq="185" ftFieldset="Solr Content Type" ftLabel="Indexed Rules" name="lIndexedRules" ftType="longchar" type="longchar" default="" hint="Using longchar in case there are many rules in the list and FarCry 6.0.x does not support precision." />
	
	<cfproperty ftSeq="190" ftFieldset="Solr Content Type" ftLabel="Core Property Boost Values" name="lCorePropertyBoost" ftType="longchar" type="longchar" default="" hint="A list of boost values in field:boostvalue format.  Ex: label:5,datetimecreated:10 would indicate a boost value of 5 for label and 10 for datetimecreated." />
	
	<cfproperty ftSeq="210" ftFieldset="Solr Content Type" ftLabel="Index on Save?" name="bIndexOnSave" ftType="boolean" type="boolean" default="1" ftDefault="1" ftHint="Should this content type be indexed whenever a record is saved? If not, the content type will only be indexed by a separate scheduled task." />
	
	<cffunction name="AfterSave" access="public" output="false" returntype="struct" hint="Called from setData and createData and run after the object has been saved.">
		<cfargument name="stProperties" required="yes" type="struct" hint="A structure containing the contents of the properties that were saved to the object.">
		
		<cfparam name="application.stPlugins.farcrysolrpro.corePropertyBoosts" type="struct" default="#structNew()#" />
		<cfset structDelete(application.stPlugins.farcrysolrpro.corePropertyBoosts,stProperties.objectid) />
		
		<!--- cache the field list for this type (both phonetic and non-phonetic) --->
		<cfset setFieldListCacheForType(stProperties.contentType,true) />
		<cfset setFieldListCacheForType(stProperties.contentType,false) />
		
		<cfreturn super.aftersave(argumentCollection = arguments) />
		
	</cffunction>
	
	<cffunction name="onDelete" returntype="void" access="public" output="false" hint="Is called after the object has been removed from the database">
		<cfargument name="typename" type="string" required="true" hint="The type of the object" />
		<cfargument name="stObject" type="struct" required="true" hint="The object" />
		
		<cfif structKeyExists(arguments.stObject, "contentType") and len(trim(arguments.stObject.contentType))>
			
			<!--- on delete, remove all indexed records for this typename from solr --->	
			<cfset deleteByTypename(typename = arguments.stObject.contentType, sitename = application.applicationName, bCommit = true) />
			
			<!--- delete any indexed properties for this content type --->
			<cfset var oProperty = application.fapi.getContentType("solrProIndexedProperty") />
			<cfset var id = "" />
			<cfloop array="#stObject.aIndexedProperties#" index="id">
				<cftry>
					<cfset oProperty.delete(id) />
					<cfcatch>
						<!--- do nothing --->
					</cfcatch>
				</cftry>
			</cfloop>
			
		</cfif>
		
		<cfset super.onDelete(argumentCollection = arguments) />
		
	</cffunction>
	
	<cffunction name="ftValidateContentType" access="public" output="true" returntype="struct" hint="This will return a struct with bSuccess and stError">
		<cfargument name="objectid" required="true" type="string" hint="The objectid of the object that this field is part of.">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stFieldPost" required="true" type="struct" hint="The fields that are relevent to this field type.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		
		<cfset var stResult = structNew()>		
		<cfset var oField = createObject("component", "farcry.core.packages.formtools.field") />
		<cfset var qDupeCheck = "" />		
		
		<!--- assume it passes --->
		<cfset stResult = oField.passed(value=arguments.stFieldPost.Value) />
			
		<cfif NOT len(stFieldPost.Value)>
			<cfset stResult = oField.failed(value=arguments.stFieldPost.value, message="This is a required field.") />
		</cfif>
		
		<!--- check for duplicates --->
		<cfquery name="qDupeCheck" datasource="#application.dsn#">
			select objectid from solrProContentType where contentType = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.stFieldPost.value)#" /> and objectid <> <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.objectid#" />; 
		</cfquery>
		
		<cfif qDupeCheck.recordCount gt 0>
			<cfset stResult = oField.failed(value=arguments.stFieldPost.value, message="There is already a configuration created for this content type.") />
		</cfif>

		<cfreturn stResult />
		
	</cffunction>
	
	<cffunction name="indexRecords" returntype="struct" access="public" output="false" hint="Indexes records for all or selected content types.">
		<cfargument name="bOptimize" type="boolean" required="false" default="true" />
		<cfargument name="batchSize" type="numeric" required="false" default="#application.fapi.getConfig(key = 'solrserver', name = 'batchSize', default = 1000)#" />
		<cfargument name="lContentTypeIds" type="string" required="false" default="" hint="A list of SolrProContentType ObjectIDs.  If empty string, all preconfigured content types will be indexed." />
		
		<!--- Start timer --->
		<cfset var tickBegin = GetTickCount() />
		
		<!--- instantiate the content types we will need --->
		<cfset var oIndexedProperty = application.fapi.getContentType("solrProIndexedProperty") />
		<cfset var oDocumentBoost = application.fapi.getContentType("solrProDocumentBoost") />
		
		<!--- get all the content types that are being indexed --->
		<cfset var qContentTypes = getAllContentTypes(bIncludeNonSearchable = true) />

		<!--- delete any records that have a typename value that is not in the list of indexed typenames --->
		<cfset var lValidTypenames = valueList(qContentTypes.contentType) />
		<cfset var deleteQueryString = "q={!lucene q.op=AND}" />
		<cfset var t = "" />
		<cfloop list="#lValidTypenames#" index="t">
			<cfset deleteQueryString = deleteQueryString & " -typename:" & t />
		</cfloop>
		<cfset deleteByQuery(q = deleteQueryString) />
		<cfset commit() />
		
		<!--- only index the specified content types --->
		<cfif listLen(arguments.lContentTypeIds)>
			<cfquery name="qContentTypes" dbtype="query">
				select objectid, contentType from qContentTypes where objectid in (<cfqueryparam list="true" cfsqltype="cf_sql_varchar" value="#arguments.lContentTypeIds#" /> )
			</cfquery>
		</cfif>

		<cfset var aStats = [] />
		<cfloop query="qContentTypes">
			
			<cfset var typeTickBegin = getTickCount() />
			
			<!--- load this content type's index settings --->
			<cfset var stContentType = getData(objectid = qContentTypes.objectid[qContentTypes.currentRow]) />
			
			<!--- get the records to index --->
			<cfset var stResult = getRecordsToIndex(typename = stContentType.contentType, batchSize = arguments.batchSize, builtToDate = stContentType.builtToDate) />
			<cfset var qContentToIndex = stResult.qContentToIndex />
			<cfset var lItemsInDb = stResult.lItemsInDb />
			
			<!--- load all records for this type from solr for comparison later --->
			<cfset var existingRecords = search(q = "typename:" & stContentType.contentType, rows = 999999) />
			<cfset var lExistingRecords = "" />
			<cfset var r = "" />
			<cfloop array="#existingRecords.results#" index="r">
				<cfif isArray(r.objectid)>
					<cfset lExistingRecords = listAppend(lExistingRecords, r.objectid[1]) />
				<cfelse>	
					<cfset lExistingRecords = listAppend(lExistingRecords, r.objectid) />
				</cfif>
			</cfloop>
			
			<cfloop query="qContentToIndex">
				
				<!--- add each record to the index --->
				<cfset addRecordToIndex(
					objectid = qContentToIndex.objectid[qContentToIndex.currentRow],
					typename = stContentType.contentType,
					stContentType = stContentType,
					oIndexedProperty = oIndexedProperty,
					oDocumentBoost = oDocumentBoost,
					bCommit = false
				) />
				
			</cfloop>
			
			<!--- delete any records in the index that are no longer in the database. (use a solr "delete by query" to delete all items for this content type that are not in the qContentToIndex results) --->
			<cfset var lItemsToDelete = listCompare(lExistingRecords, lItemsInDB) />
			<cfif listLen(lItemsToDelete)>
				<cfset deleteByTypename(typename = stContentType.contentType, sitename = application.applicationName, lObjectIds = lItemsToDelete, bCommit = false) />
			</cfif>
			
			<!--- update metadata for this content type --->
			<cfif qContentToIndex.recordCount gt 0>
				<cfset stContentType.builtToDate = qContentToIndex.datetimelastupdated[qContentToIndex.recordCount] />
				<cfset setData(stProperties = stContentType) />
			</cfif>
			
			<cfset var typeTickEnd = getTickCount() />
			
			<!--- If there were no errors, update stats --->	
			<cfset var stStats = {} />
			<cfset stStats["typeName"] = qContentTypes.contentType[qContentTypes.currentRow] />
			<cfset stStats["processtime"] = typeTickEnd - typeTickBegin />
			<cfset stStats["indexRecordCount"] =  qContentToIndex.recordCount />
			<cfset stStats["totalRecordCount"] = listLen(lExistingRecords) + qContentToIndex.recordCount - listLen(lItemsToDelete) />
			<cfset stStats["builtToDate"] = stContentType.builtToDate />
			<cfset arrayAppend(aStats, stStats) />
			
		</cfloop>
		
		<!--- commit --->
		<cfset commit() />
		
		<!--- optionally, optimize --->
		<cfif arguments.bOptimize>
			<cfset optimize() />
		</cfif>
		
		<cfset var processTime = GetTickCount() - tickBegin />
		
		<cfreturn {
			aStats = aStats,
			processTime = processTime
		} />
		
	</cffunction>
	
	<cffunction name="setFieldListCacheForType" returntype="void" access="public" output="false">
		<cfargument name="typename" type="string" required="true" />
		<cfargument name="bIncludePhonetic" type="boolean" required="false" default="true" />
		<cfset cacheRemove("farcrysolrpro-fieldlist-" & arguments.typename & "-" & arguments.bIncludePhonetic) />
		<cfset cachePut("farcrysolrpro-fieldlist-" & arguments.typename & "-" & arguments.bIncludePhonetic,getFieldListForType(arguments.typename,arguments.bIncludePhonetic)) />
	</cffunction>
	
	<cffunction name="getFieldListCacheForType" returntype="string" access="public" output="false">
		<cfargument name="typename" type="string" required="true" />
		<cfargument name="bIncludePhonetic" type="boolean" required="false" default="true" />
		<cfset var cachedValue = cacheGet("farcrysolrpro-fieldlist-" & arguments.typename & "-" & arguments.bIncludePhonetic) />
		<cfif not isNull(cachedValue)>
			<cfreturn cachedValue />
		<cfelse>
			<cfset setFieldListCacheForType(arguments.typename,arguments.bIncludePhonetic) />
			<cfreturn getFieldListCacheForType(arguments.typename,arguments.bIncludePhonetic) />
		</cfif>
	</cffunction>
	
	<cffunction name="getFieldListForTypes" returntype="string" access="public" output="false" hint="Returns a list of fields (space delimited) for a all specified indexed content types.  Used for the qf (query fields) Solr parameter">
		<cfargument name="lContentTypes" type="string" default="" />
		<cfargument name="bIncludePhonetic" type="boolean" required="false" default="true" />
		<cfset var q = getAllContentTypes(lContentTypes) />
		<cfset var qf = "" />
		
		<!--- for each indexed content type, get the field list --->
		<cfloop query="q">
			<cfset qf = qf & " " & getFieldListCacheForType(q.contentType,arguments.bIncludePhonetic) />
		</cfloop> 
		
		<!--- dedupe list --->
		<cfset var st = {} />
		<cfset var i = "" />
		<cfloop list="#qf#" index="i" delimiters=" ">
			<cfset st[i] = "" />
		</cfloop>
		<cfset qf = structKeyList(st," ") />
		
		<cfreturn trim(qf) />
		
	</cffunction>
	
	<cffunction name="getFieldListForType" returntype="string" access="public" output="false" hint="Returns a list of fields (space delimited) for a given content type.  Used for the qf (query fields) Solr parameter">
		<cfargument name="typename" required="true" />
		<cfargument name="bIncludePhonetic" type="boolean" required="false" default="true" />
		<cfargument name="qf" type="array" required="false" default="#['fcsp_rulecontent','fcsp_rulecontent_phonetic','objectid']#" hint="The starting list for the query fields" />
		<cfset var st = getByContentType(arguments.typename) />
		<cfset var oIndexedProperty = application.fapi.getContentType("solrProIndexedProperty") />
		<cfset var prop = "" />
		<cfset var propId = "" />
		<cfset var ft = "" />
		<cfset var fieldType = [] />
		
		<cfloop array="#st.aIndexedProperties#" index="propId">
			<cfset prop = oIndexedProperty.getData(propId) />
			<cfloop list="#prop.lFieldTypes#" index="ft">
				<!--- for each field type for this farcry field, build the solr dynamic field name --->
				<cfset fieldType = listToArray(ft,":") />
				<cfif fieldType[2] eq 0>
					<cfset fieldType[2] = "notstored" />
				<cfelse>
					<cfset fieldType[2] = "stored" />
				</cfif>
				<cfif arguments.bIncludePhonetic or (fieldType[1] neq 'phonetic' and arguments.bIncludePhonetic eq false)>
					<cfset arrayAppend(arguments.qf, lcase(prop.fieldName) & "_" & fieldType[1] & "_" & fieldType[2]) />
				</cfif>
			</cfloop>
		</cfloop>
		<cfreturn arrayToList(arguments.qf, " ") />
	</cffunction>
	
	<cffunction name="getCorePropertyBoosts" returntype="struct" access="public" output="false" hint="Returns a struct of core property boost values for a given content type">
		<cfargument name="stContentType" required="true" type="struct" />
		<cfparam name="application.stPlugins.farcrysolrpro.corePropertyBoosts" default="#structNew()#" />
		<cfif structKeyExists(application.stPlugins.farcrysolrpro.corePropertyBoosts,arguments.stContentType.objectid)>
			<cfreturn application.stPlugins.farcrysolrpro.corePropertyBoosts[stContentType.objectid] />
		</cfif>
		<cfset var aCorePropBoosts = listToArray(stContentType.lCorePropertyBoost) />
		<cfset var stPropBoosts = {} />
		<cfset var i = "" />
		<cfloop array="#aCorePropBoosts#" index="i">
			<cfset stPropBoosts[listFirst(i,":")] = listLast(i,":") /> 
		</cfloop>
		<cfset application.stPlugins.farcrysolrpro.corePropertyBoosts[stContentType.objectid] = stPropBoosts />
		<cfreturn stPropBoosts />
	</cffunction>
	
	<cffunction name="getRecordCountForType" returntype="numeric" access="public" output="false">
		<cfargument name="typename" required="true" type="string" />
		<cfreturn arrayLen(search(q = "typename:" & arguments.typename & " AND fcsp_sitename:" & application.applicationName, params = { "fl" = "objectid" }, rows = 9999999).results) />
	</cffunction>
	
	<cffunction name="addRecordToIndex" returntype="void" access="public" output="false">
		<cfargument name="objectid" required="true" type="uuid" hint="The objectID of the record to be indexed." />
		<cfargument name="typename" required="false" type="string" default="#application.fapi.findType(arguments.objectid)#" hint="The FarCry typename of the record being indexed.  If not provided, it will be loaded from the FarCry database.  This should be provided for performance reasons." />
		<cfargument name="stContentType" required="false" type="struct" default="#structNew()#" hint="The SolrProContentType object that defines how to index this record.  If not provided, it will be loaded based on the type of the record being indexed." />
		<cfargument name="oIndexedProperty" required="false" type="any" default="#application.fapi.getContentType('solrProIndexedProperty')#" hint="An instance of the solrProIndexedProperty content type CFC.  If not provided, an instance will be created.  If you are looping and calling this method multiple times, it will be much more performant if you create an instance of this CFC once and provide it here." />
		<cfargument name="oDocumentBoost" required="false" type="any" default="#application.fapi.getContentType('solrProDocumentBoost')#" hint="An instance of the solrProDocumentBoost content type CFC.  If not provided, an instance will be created.  If you are looping and calling this method multiple times, it will be much more performant if you create an instance of this CFC once and provide it here." />
		<cfargument name="bCommit" required="false" type="boolean" default="true" hint="Should Solr's commit method be called after adding this record?  Do not specify true here if adding multiple records. Commit after all records have been added." />
		
		<!--- if the content type record was not provided, look it up --->
		<cfif not structCount(arguments.stContentType)>
			<cfset arguments.stContentType = getByContentType(arguments.typename) />
			<!--- if we got an empty struct back then an invalid content type was specified (the type isn't set up for indexing) --->
			<cfif not structCount(arguments.stContentType)>
				<cfthrow type="InvalidContentType" message="You have attempted to index a record that is of a content type (#arguments.typename#) that is not being indexed by the FarCry Solr Pro plugin.  Please setup that content type in the administration area." />
			</cfif>
		</cfif>
		
		<!--- note: these results are cached so it is safe to loop and call this method --->
		<cfset var stPropBoosts = getCorePropertyBoosts(stContentType = arguments.stContentType) />
		<cfset var lFarCryProps = getPropertiesByType(typename = arguments.typename) />
		<cfset var aCoreFields = getSolrFields(lOmitFields = "fcsp_rulecontent") />
		
		<!--- load the record from the database --->
		<cfset var stRecord = application.fapi.getContentObject(typename = arguments.typename, objectid = arguments.objectid) />
		
		<!--- each record in Solr should track the application name --->
		<cfset stRecord["fcsp_sitename"] = application.applicationName />
		
		<!--- create a solr object for this record --->
		<cfset var doc = [] />
		<cfset var field = "" />
		<cfloop collection="#stRecord#" item="field">
			
			<!--- only add field if its a core property or an indexed field --->
			<cfif hasIndexedProperty(arguments.stContentType.objectid, field) or arrayFindNoCase(aCoreFields, field)>
				
				<cfif arrayFindNoCase(aCoreFields, field)>
					
					<!--- core property --->
				
					<!--- if this is a legit FC property then set the farcryField, otherwise leave it blank --->
					<cfif listFindNoCase(lFarCryProps, field)>
						
						<cfset arrayAppend(doc, {
							name = lcase(field),
							value = stRecord[field],
							farcryField = field
						}) />
						
					<cfelse>
						
						<cfset arrayAppend(doc, {
							name = lcase(field),
							value = stRecord[field],
							farcryField = ""
						}) />
						
					</cfif>
					
				<cfelse>
					
					<!--- custom property --->
					
					<!--- load the indexing metadata for this property --->
					<cfset var stSolrPropData = arguments.oIndexedProperty.getByContentTypeAndFieldname(contentTypeId = arguments.stContentType.objectid, fieldName = field) />
					<cfset var aFieldTypes = listToArray(stSolrPropData.lFieldTypes,",") />
					<cfset var ft = "" />
					<cfloop array="#aFieldTypes#" index="ft">
						
						<cfset var typeSetup = {
							fieldType = listGetAt(ft,1,":"),
							bStored = listGetAt(ft,2,":"),
							boostValue = listGetAt(ft,3,":")
						} />
						
						<cfset arrayAppend(doc, {
							name = lcase(field) & "_" & typeSetup.fieldType & "_" & ((typeSetup.bStored eq 1) ? "stored" : "notstored"),
							value = stRecord[field],
							boost = typeSetup.boostValue,
							farcryField = field
						}) />
						
					</cfloop>
					
				</cfif>
					
			</cfif>
			
		</cfloop>
		
		<!--- grab any related rule records and index those as well (if we are indexing rules for this content type) --->
		<cfif listLen(arguments.stContentType.lIndexedRules)>
			<cfset var ruleContent = getRuleContent(objectid = arguments.objectid, lRuleTypes = arguments.stContentType.lIndexedRules) />
			<cfset arrayAppend(doc, {
			 	name = "fcsp_rulecontent", 
			 	value = ruleContent,
			 	farcryField = ""
			}) />
			<cfset arrayAppend(doc, {
			 	name = "fcsp_rulecontent_phonetic", 
			 	value = ruleContent,
			 	farcryField = "" 
			}) />
		</cfif>
		
		<!--- if we are building a summary field, grab that data as well --->
		<cfset var lSummaryFields = arguments.stContentType.lSummaryFields />
		<cfset var f = "" />
		<cfloop list="#lSummaryFields#" index="f">
			<cfif structKeyExists(stRecord, f)>
				<cfset arrayAppend(doc, {
					name = "fcsp_highlight",
					value = application.stPlugins.farcrysolrpro.oCustomFunctions.tagStripper(stRecord[f]),
					farcryField = ""
				}) />
			</cfif>
		</cfloop>
		
		<!--- note whether or not this record should be included in the site-wide search --->
		<cfset arrayAppend(doc, {
			name = "fcsp_benablesearch",
			value = javacast("boolean",stContentType.bEnableSearch),
			farcryField = ""
		}) />
		
		<!--- add core boost values to document --->
		<cfset var i = "" />
		<cfloop array="#doc#" index="i">
			<cfif structKeyExists(stPropBoosts, i.name) and not structKeyExists(i,"boost")>
				<cfset i.boost = stPropBoosts[i.name] />
			<cfelse>
				<cfset i.boost = application.fapi.getConfig(key = 'solrserver', name = 'defaultBoost', default = 5) />
			</cfif>
		</cfloop>
		
		<!--- check if this record has a document level boost --->
		<cfset var docBoost = arguments.oDocumentBoost.getBoostValueForDocument(documentId = stRecord.objectid) />
		
		<!--- if there was no boost for the specific document, grab the default specified for the content type --->
		<cfif not isNumeric(docBoost)>
			<cfset docBoost = arguments.stContentType.defaultDocBoost />
		</cfif>
		
		<!--- add it to solr --->
		<cfset var args = { doc = doc, typename = stRecord.typename } />
		<cfif isNumeric(docBoost)>
			<cfset args.docBoost = docBoost />
		</cfif>
		<cfset add(argumentCollection = args) />
		
		<!--- optionally, commit --->
		<cfif arguments.bCommit>
			<cfset commit() />
		</cfif>
		
	</cffunction>
	
	<cffunction name="getRecordsToIndex" returntype="struct" access="public" output="false" hint="Get the records to index for a given content type">
		<cfargument name="typename" required="true" type="string" />
		<cfargument name="batchSize" required="true" type="numeric" />
		<cfargument name="builtToDate" required="false" type="any" />
		
		<cfset var oType = application.fapi.getContentType(arguments.typename) />
		<cfset var stResult = {} />
		
		<cfif structKeyExists(oType,"getTablename")>
			<cfset var tablename = oType.getTablename() />
		<cfelse>
			<cfset var tablename = oType.getTypename() />
		</cfif>
					
		<cfif structKeyExists(oType, "contentToIndex")>
			<!--- run the contentToIndex method for this content type --->
			<cfset stResult.qContentToIndex = oType.contentToIndex() />
		<cfelse>
			<!--- no contentToIndex method, just grab all the records --->
			<cfquery name="stResult.qContentToIndex" datasource="#application.dsn#">
			SELECT objectID, datetimelastupdated
			FROM #tablename#
			<cfif structkeyexists(application.stcoapi[tablename].stprops, "status")>
			where status = 'approved'
			</cfif>
			</cfquery>
		</cfif>
		
		<cfset stResult.lItemsInDb = valueList(stResult.qContentToIndex.objectid) />
		
		<cfquery name="stResult.qContentToIndex" dbtype="query" maxrows="#batchSize#">
			select objectid, datetimelastupdated from stResult.qContentToIndex 
			<cfif structKeyExists(arguments,"builtToDate") and isDate(arguments.builtToDate)>
			where datetimelastupdated > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.builtToDate#" />
			</cfif>
			order by datetimelastupdated
		</cfquery>
		
		<cfreturn stResult />
		
	</cffunction>
	
	<cffunction name="deleteByTypename" returntype="void" access="public" output="false">
		<cfargument name="typename" required="true" type="string" />
		<cfargument name="sitename" required="false" type="string" default="#application.applicationName#" />
		<cfargument name="lObjectIds" required="false" type="string" default="" hint="optional list of objectIds to delete from the solr index" />
		<cfargument name="bCommit" required="false" type="boolean" default="true" />
		<cfset var deleteQuery = "typename:" & arguments.typename />
		<cfif len(trim(arguments.sitename))>
			<cfset deleteQuery = deleteQuery & " AND fcsp_sitename:" & arguments.sitename />
		</cfif>
		<cfset var i = "" />
		<cfif listLen(arguments.lObjectIds)>
			<cfset deleteQuery = deleteQuery & " AND (" />
			<cfloop list="#arguments.lObjectIds#" index="i">
				<cfset deleteQuery = deleteQuery & " objectid:#i#" />
			</cfloop>
			<cfset deleteQuery = deleteQuery & " )" />
		</cfif>
		<cfset deleteByQuery(q = deleteQuery) />
		<cfif arguments.bCommit>
			<cfset commit() />
		</cfif>
	</cffunction>
	
	<cffunction name="deleteBySitename" returntype="void" access="public" output="false">
		<cfargument name="sitename" required="false" type="string" default="#application.applicationName#" />
		<cfargument name="bCommit" required="false" type="boolean" default="true" />
		<cfset var deleteQuery = "fcsp_sitename:" & arguments.sitename />
		<cfset deleteByQuery(q = deleteQuery) />
		<cfif arguments.bCommit>
			<cfset commit() />
		</cfif>
	</cffunction>
	
	<cffunction name="getByContentType" access="public" output="false" returntype="struct">
		<cfargument name="contentType" type="string" required="true" />
		<cfset var q = "" />
		<cfquery name="q" datasource="#application.dsn#" cachedwithin="#createTimeSpan(0,0,0,60)#">
			select objectid from solrProContentType where contenttype = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.contentType#" /> 
		</cfquery>
		<cfif q.recordCount>
			<cfreturn getData(q.objectid[1]) />
		<cfelse>
			<cfreturn {} />
		</cfif>
	</cffunction>
	
	<cffunction name="getRuleContent" access="public" output="false" returntype="array">
		<cfargument name="objectid" required="true" type="uuid" hint="The objectid of the object to get rule content for" />
		<cfargument name="lRuleTypes" required="true" type="string" hint="A list of rule typenames to check" />
		
		<cfset var a = [] />
		<cfset var qRulesToIndex = "" />
		
		<cfquery name="qRulesToIndex" datasource="#application.dsn#">
			select 
				cxr.data, 
				cxr.typename 
			from 
				container c 
				join container_aRules cxr on c.objectID = cxr.parentid
			where 
				cxr.typename in (<cfqueryparam list="true" cfsqltype="cf_sql_varchar" value="#arguments.lRuleTypes#" />) 
				and c.label like <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.objectid#%" />
		</cfquery>
		
		<cfloop query="qRulesToIndex">
		
			<cfset var qData = "" />
			
			<cfset var rule = getRules(ruleTypename = qRulesToIndex.typename[qRulesToIndex.currentRow]) />
			
			<cfif arrayLen(rule)>
				
				<cfquery name="qData" datasource="#application.dsn#">
					select #rule[1].indexableFields# from #qRulesToIndex.typename[qRulesToIndex.currentRow]# where objectID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qRulesToIndex.data[qRulesToIndex.currentRow]#" />
				</cfquery>
				
				<cfloop query="qData">
					<cfset var col = "" />
					<cfloop list="#qData.columnList#" index="col">
						<cfset arrayAppend(a, qData[col][qData.currentRow]) />
					</cfloop>
				</cfloop>
				
			</cfif>
		
		</cfloop>
		
		<cfreturn a />

	</cffunction>
	
	<cffunction name="hasIndexedProperty" access="public" hint="Checks if a content type is indexing a single property" output="false" returntype="boolean">
		<cfargument name="objectid" type="uuid" required="true" hint="The objectid of the content type" />
		<cfargument name="fieldName" type="string" required="true" />
		<cfset var q = "" />
		<cfquery name="q" datasource="#application.dsn#">
			select p.objectid 
			from solrProIndexedProperty p 
			join solrProContentType_aIndexedProperties cxp on p.objectid = cxp.data 
			where p.fieldName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.fieldName#" />
			and cxp.parentid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.objectid#" />
		</cfquery>
		<cfreturn q.recordCount />
	</cffunction>
	
	<cffunction name="getRules" access="public" hint="Get list of all indexable rules (rules with at least one string field)" output="false" returntype="array">
		
		<cfargument name="ruleTypename" required="false" type="string" />
		
		<cfset var aRules = [] />
		<cfset var q = queryNew("typename,displayname,indexableFields,lowerdisplayname") />
		<cfset var rule = "" />
		<cfset var lIndexedTypes = "nstring,string,longchar,richtext,country,state,hidden,category" />
		
		<cfloop collection="#application.rules#" item="rule">
			<cfif (not structKeyExists(arguments,"ruleTypename")) or (structKeyExists(arguments,"ruleTypename") and arguments.ruleTypename eq rule)>
				<cfif rule neq "container">
					
					<!--- build a list of indexable fields --->
					<cfset var props = application.fapi.getContentTypeMetadata(typename = rule, md = "stProps", default = "") />
					<cfset var prop = "" />
					<cfset var lIndexableFields = "" />
					
					<cfloop collection="#props#" item="prop">
						<cfif (listFindNoCase(lIndexedTypes, props[prop].metadata.type) or listFindNoCase(lIndexedTypes, props[prop].metadata.ftType))>
							<cfset lIndexableFields = listAppend(lIndexableFields, prop) />
						</cfif>
					</cfloop>
				
					<cfset queryAddRow(q) />
					<cfset querySetCell(q, "typename", rule) />
					<cfset querySetCell(q, "displayname", application.stcoapi[rule].displayname & " (" & rule & ")") />
					<cfset querySetCell(q, "indexableFields", lIndexableFields) />
					<cfset querySetCell(q, "lowerdisplayname", lcase(application.stcoapi[rule].displayname)) />
					
				</cfif>
			</cfif>
		</cfloop>
		
		<cfquery dbtype="query" name="q">
		SELECT typename,displayname,indexableFields FROM q ORDER BY lowerdisplayname
		</cfquery>
		
		<cfloop query="q">
			<cfset arrayAppend(aRules, {
				typename = q.typename[q.currentRow],
				displayname = q.displayName[q.currentRow],
				indexableFields = q.indexableFields[q.currentRow]
			}) />
		</cfloop>
		
		<cfreturn aRules />
		
	</cffunction> 
	
	<cffunction name="getContentTypes" access="public" hint="Get list of all searchable content types." output="false" returntype="string">
		<cfset var listdata = "" />
		<cfset var qListData = queryNew("typename,displayname,lowerdisplayname") />
		<cfset var type = "" />
		<cfloop collection="#application.types#" item="type">
			<cfset queryAddRow(qListData) />
			<cfset querySetCell(qListData, "typename", type) />
			<cfset querySetCell(qListData, "displayname", "#application.stcoapi[type].displayname# (#type#)") />
			<cfset querySetCell(qListData, "lowerdisplayname", "#lcase(application.stcoapi[type].displayname)#") />
		</cfloop>
		
		<cfquery dbtype="query" name="qListData">
		SELECT typename,displayname FROM qListData ORDER BY lowerdisplayname
		</cfquery>
		
		<cfloop query="qListData">
			<cfset listdata = listAppend(listdata, "#qlistdata.typename[qlistdata.currentrow]#:#qlistdata.displayname[qlistdata.currentrow]#") />
		</cfloop>
		
		<cfreturn listData />
	</cffunction>
		
	<cffunction name="getPropertiesByType" access="public" output="false" returntype="string">
		<cfargument name="typename" required="true" type="string" />
		
		<cfif structKeyExists(application.stPlugins["farcrysolrpro"],"typeProperties-" & arguments.typename)>
			<cfreturn application.stPlugins["farcrysolrpro"]["typeProperties-" & arguments.typename] />
		</cfif>
		
		<cfset var properties = application.fapi.getContentTypeMetadata(typename = arguments.typename, md = "stProps", default = "") />
		
		<cfif isStruct(properties)>
			<cfset application.stPlugins["farcrysolrpro"]["typeProperties-" & arguments.typename] = listSort(structKeyList(properties),"textnocase") />
			<cfreturn application.stPlugins["farcrysolrpro"]["typeProperties-" & arguments.typename]  />
		</cfif>
		
	</cffunction>
	
	<cffunction name="getFTTypeForProperty" access="public" output="false" returntype="string">
		<cfargument name="typename" required="true" type="string" />
		<cfargument name="propertyName" required="true" type="string" />
		<cfset var properties = application.fapi.getContentTypeMetadata(typename = arguments.typename, md = "stProps", default = "") />
		<cfreturn properties[arguments.propertyName].metadata.ftType />
	</cffunction>
	
	<cffunction name="getFarCryDataTypeForProperty" access="public" output="false" returntype="string">
		<cfargument name="typename" required="true" type="string" />
		<cfargument name="propertyName" required="true" type="string" />
		<cfset var properties = application.fapi.getContentTypeMetadata(typename = arguments.typename, md = "stProps", default = "") />
		<cfreturn properties[arguments.propertyName].metadata.type />
	</cffunction>
	
	<cffunction name="getTextPropertiesByType" access="public" output="false" returntype="string">
		<cfargument name="typename" required="true" type="string" />
		
		<cfset var l = "" />
		<cfset var properties = application.fapi.getContentTypeMetadata(typename = arguments.typename, md = "stProps", default = "") />
		<cfset var prop = "" />
		
		<cfif isStruct(properties)>
			<cfloop collection="#properties#" item="prop">
				<cfif listFindNoCase("nstring,string,longchar",properties[prop].metadata.type)>
					<cfset l = listAppend(l, prop) />
				</cfif>
			</cfloop>
		</cfif>
		
		<cfreturn listSort(l,"textnocase") />
		
	</cffunction>
	
	<cffunction name="getSolrFieldTypes" access="public" output="false" returntype="array" hint="Parses the field types from the schema.xml file">
		
		<cfargument name="fcDataType" type="string" required="false" default="" hint="A FarCry data type to use to filter" />
		
		<cfset var a = [] />
		<cfset var schemaXmlFile = application.fapi.getConfig(key = "solrserver", name = "instanceDir") & "/conf/schema.xml" />
		<cfset var fieldTypes = xmlSearch(schemaXmlFile, "//schema/fields/dynamicField | //schema/fields/dynamicfield") />
		<cfset var fieldType = "" />
		
		<cfloop array="#fieldTypes#" index="fieldType">
			<cfparam name="fieldType.xmlAttributes.fcDataTypes" default="" />
			<cfif len(trim(fcDataType)) eq 0 or (listFindNoCase(fieldType.xmlAttributes['fcDataTypes'], arguments.fcDataType))>
				<cfif structKeyExists(fieldType.xmlAttributes,"fcId") and not arrayFindNoCase(a, fieldType.xmlAttributes["fcId"] & ":" & fieldType.xmlAttributes["fcDisplayName"] & ":" & fieldType.xmlAttributes["fcDataTypes"])>
					<cfset arrayAppend(a, fieldType.xmlAttributes["fcId"] & ":" & fieldType.xmlAttributes["fcDisplayName"] & ":" & fieldType.xmlAttributes["fcDataTypes"]) />
				</cfif>
			</cfif>	
		</cfloop>
		
		<cfreturn a />
		
	</cffunction>
	
	<cffunction name="getSolrFields" access="public" output="false" returntype="array" hint="Gets the fields defined in the schema.xml file">
		<cfargument name="lOmitFields" type="string" required="false" default="" hint="A list of fields to omit" />
		
		<cfif structKeyExists(application.stPlugins["farcrysolrpro"],"schemaFields-#arguments.lOmitFields#")>
			<cfreturn application.stPlugins["farcrysolrpro"]["schemaFields-" & arguments.lOmitFields] />
		</cfif>
		
		<cfset var a = [] />
		<cfset var schemaXmlFile = application.fapi.getConfig(key = "solrserver", name = "instanceDir") & "/conf/schema.xml" />
		<cfset var fields = xmlSearch(schemaXmlFile, "//schema/fields/field") />
		<cfset var field = "" />
		
		<cfloop array="#fields#" index="field">
			<cfif not listFindNoCase(arguments.lOmitFields, field.xmlAttributes["name"])>
				<cfset arrayAppend(a, field.xmlAttributes["name"]) />
			</cfif>
		</cfloop>
		
		<cfset application.stPlugins["farcrysolrpro"]["schemaFields-" & arguments.lOmitFields] = a />
		
		<cfreturn a />
		
	</cffunction>
	
	<cffunction name="getSchemaFieldMetadata" access="public" output="false" returntype="array" hint="Returns field metadata from the schema.xml file">
		<cfargument name="lFieldNames" type="string" required="false" default="" hint="List of fields to return metadata.  If not specified, all fields will be returned." />
		<cfargument name="lOmitFields" type="string" required="false" default="fcsp_random" />
		<cfargument name="bIncludeIgnored" type="boolean" required="false" default="false" /> 
		<cfset var a = [] />
		<cfset var schemaXmlFile = application.fapi.getConfig(key = "solrserver", name = "instanceDir") & "/conf/schema.xml" />
		<cfset var fields = xmlSearch(schemaXmlFile, "//schema/fields/field") />
		<cfset var field = "" />
		<cfloop array="#fields#" index="field">
			<cfif (listLen(arguments.lFieldNames) eq 0 or listFindNoCase(arguments.lFieldNames, field.xmlAttributes["name"])) and not listFindNoCase(arguments.lOmitFields, field.xmlAttributes["name"])>
				<cfif field.xmlAttributes.type neq "ignored" or arguments.bIncludeIgnored eq true>
					<cfset arrayAppend(a, field.xmlAttributes) />
				</cfif>
			</cfif>
		</cfloop>
		<cfreturn a />
	</cffunction>
	
	<cffunction name="getSchemaDynamicFieldMetadata" access="public" output="false" returntype="array" hint="Returns dynamic field metadata from the schema.xml file">
		<cfargument name="bIncludeIgnored" type="boolean" required="false" default="false" /> 
		<cfset var a = [] />
		<cfset var schemaXmlFile = application.fapi.getConfig(key = "solrserver", name = "instanceDir") & "/conf/schema.xml" />
		<cfset var fields = xmlSearch(schemaXmlFile, "//schema/fields/dynamicField | //schema/fields/dynamicfield") />
		<cfset var field = "" />
		<cfloop array="#fields#" index="field">
			<cfif field.xmlAttributes.type neq "ignored" or arguments.bIncludeIgnored eq true>
				<cfset arrayAppend(a, field.xmlAttributes) />
			</cfif>
		</cfloop>
		<cfreturn a />
	</cffunction>
	
	<cffunction name="getSolrFieldTypeForProperty" access="public" output="false" returntype="string" hint="Returns the field type specified for a given field as declared in the schema.xml file.">
		<cfargument name="fieldName" type="string" required="true" />
		
		<cfset var schemaXmlFile = application.fapi.getConfig(key = "solrserver", name = "instanceDir") & "/conf/schema.xml" />
		<cfset var field = xmlSearch(schemaXmlFile, "//schema/fields/field[@name='#lcase(arguments.fieldName)#']") />
		
		<cfif arrayLen(field)>
			<cfreturn field[1].xmlAttributes["type"] />
		<cfelse>
			<cfreturn "" />
		</cfif>
		
	</cffunction>
	
	<cffunction name="getAllContentTypes" access="public" output="false" returntype="query">
		<cfargument name="lObjectIds" type="string" required="false" default="" />
		<cfargument name="bIncludeNonSearchable" type="boolean" required="false" default="false" />
		<cfset var q = "" />
		<cfquery name="q" datasource="#application.dsn#">
			select objectid, contentType, title, bEnableSearch from solrProContentType
			where 1=1
			<cfif listLen(arguments.lObjectIds)>
			and objectid in (<cfqueryparam list="true" cfsqltype="cf_sql_varchar" value="#arguments.lObjectIds#" />)
			</cfif>
			<cfif bIncludeNonSearchable eq false>
			and bEnableSearch = 1
			</cfif>;
		</cfquery>
		<cfreturn q />
	</cffunction>
	
	<cffunction name="buildQueryString" access="public" output="false" returntype="string">
		<cfargument name="searchString" required="true" type="string" />
		<cfargument name="operator" required="false" type="string" default="ANY" hint="ANY,ALL,PHRASE" />
		<cfargument name="lContentTypes" required="false" type="string" default="" />
		<cfargument name="bCleanString" required="false" type="boolean" default="true" />
		<cfargument name="bFilterBySite" required="false" type="boolean" default="true" />
		
		<cfif arguments.bCleanString>
			<!--- escape lucene special chars (+ - && || ! ( ) { } [ ] ^ " ~ * ? : \) --->
			<cfset var q = trim(reReplaceNoCase(arguments.searchString,'([\+\-!(){}\[\]\^"~*?:\\]|&&|\|\|)',"\\\1","ALL")) />
			
			<cfif reFind("[[:space:]]",q) gt 0>
					
				<!--- remove operators from string (AND, OR, NOT) --->
				<cfset q = trim(reReplaceNoCase(q,"^AND |^OR |^NOT | AND | OR | NOT | AND$| OR$| NOT$"," ","ALL")) />
				
				<!--- build the main search phrase --->
				<cfif arguments.operator eq "all">
					<cfset q = "(" & reReplace(q,"[[:space:]]{1,}"," AND ","ALL") & ")" />
				<cfelseif arguments.operator eq "any">
					<cfset q = "(" & reReplace(q,"[[:space:]]{1,}"," OR ","ALL") & ")" />
				<cfelseif arguments.operator eq "phrase">
					<cfset q = '("' & q & '")' />
				</cfif>
				
			</cfif>
		<cfelse>
			<cfset q = '(' & q & ')' />
		</cfif>
		
		<!--- add a typename filter --->
		<cfif listLen(arguments.lContentTypes)>
			<cfset q = q & " AND (" />
			
			<cfset var counter = 0 />
			<cfloop list="#arguments.lContentTypes#" index="type">
				<cfset counter++ />
				
				<cfif counter gt 1>
					<cfset q = q & " OR " />
				</cfif>
				
				<cfset q = q & "typename:" & type />
				
			</cfloop>
		
			<cfset q = q & ")" />
		</cfif>
		
		<cfif arguments.bFilterBySite>
			<cfset q = "(" & q & ") AND (fcsp_sitename:" & application.applicationName & ")" />
		</cfif>
		
		<cfset q = "(" & q & ") AND fcsp_benablesearch:true" />
		
		<cfreturn q />
		
	</cffunction>
	
	<!--- cfsolrlib abstractions --->
	
	<cffunction name="resetIndex" access="public" output="false" returntype="void">
		<cfset application.stplugins["farcrysolrpro"].cfsolrlib.resetIndex() />
	</cffunction>
	
	<cffunction name="commit" access="public" output="false" returntype="void">
		<cfset application.stplugins["farcrysolrpro"].cfsolrlib.commit() />
	</cffunction>
	
	<cffunction name="optimize" access="public" output="false" returntype="void">
		<cfset application.stplugins["farcrysolrpro"].cfsolrlib.optimize() />
	</cffunction>
	
	<cffunction name="add" access="public" output="false" returntype="void">
		<cfargument name="doc" type="array" required="true" hint="An array of field objects, with name, value, and an optional boost attribute. {name:""Some Name"",value:""Some Value""[,boost:5]}" />
		<cfargument name="typename" type="string" required="true" />
		<cfargument name="docBoost" type="numeric" required="false" hint="Value of boost for this document." />
		
		<cfset var prop = "" />
		<cfset var httpresult = "" />
		<cfset var ftType = "" />
		<cfset var filePath = "" />
		<cfset var xml = "" />
		<cfset var solrUrl = "http://" & application.fapi.getConfig(key = 'solrserver', name = 'host') & ":" & application.fapi.getConfig(key = 'solrserver', name = 'port') & application.fapi.getConfig(key = 'solrserver', name = 'path') & "/update/extract" />
		<cfset var aFileContents = [] />
		
		<cfloop array="#doc#" index="prop">
			
			<!--- determine if this property is a "file" or "image" field, if so, send to Tika for extraction --->
			<cfif len(prop.farcryField)>
				
				<cfset ftType = getFTTypeForProperty(arguments.typename,prop.farcryField) />
				
				<cfif listFindNoCase("image,file", ftType)>
					
					<cfif ftType eq "image">
						<cfset filePath = application.fapi.getImageWebroot() & prop.value />
					<cfelse>
						<cfset filePath = application.fapi.getFileWebroot() & prop.value />
					</cfif>
					
					<cfset filePath = expandPath(filePath) />
					
					<cfif fileExists(filePath)>

						<!--- TODO: test performance with LOTS of Open XML format documents --->
						
						<cfscript>
							
							// grab a handle on javaloader
							var javaloader = application.stPlugins["farcrysolrpro"].javaloader;
							
							if (listFindNoCase(".docx,.xlsx,.pptx",right(filePath,5))) {
								// swap out the class loader so that dom4j does not throw an error
								var _thread = createObject("java", "java.lang.Thread");
					       		var currentClassloader = _thread.currentThread().getContextClassLoader();
								_thread.currentThread().setContextClassLoader(javaloader.getURLClassLoader());
							}
							
							// grab an instance of tika and parse the file
							var tika = application.stPlugins["farcrysolrpro"].javaloader.create("org.apache.tika.Tika").init();
							
							// save the results to an array for later
							arrayAppend(aFileContents, {
								name = lcase(prop.farcryField & "_contents" & right(prop.name,len(prop.name)-len(prop.farcryField))),
								value = tika.parseToString(createObject("java","java.io.File").init(filePath)),
								boost = prop.boost
							});
							
							if (listFindNoCase(".docx,.xlsx,.pptx",right(filePath,5))) {
								// set the classloader back	
								_thread.currentThread().setContextClassLoader(currentClassloader);
							}
						</cfscript>

					</cfif>
					
				</cfif>
				
			</cfif>
			
			<!--- remove farcryField key from all structs in the doc array --->
			<cfset structDelete(prop,"farcryField") />
			
		</cfloop>
		
		<!--- append any file content values to the document --->
		<cfif arrayLen(aFileContents)>
			<cfset doc.addAll(aFileContents) />
		</cfif>
		
		<cfset application.stPlugins["farcrysolrpro"].cfsolrlib.add(argumentCollection = arguments) />
		
	</cffunction>
	
	<cffunction name="search" access="public" output="false" returntype="any">
		<cfargument name="q" type="string" required="true" hint="Your query string" />
		<cfargument name="start" type="numeric" required="false" default="0" hint="Offset for results, starting with 0" />
		<cfargument name="rows" type="numeric" required="false" default="20" hint="Number of rows you want returned" />
		<cfargument name="params" type="struct" required="false" default="#structNew()#" hint="A struct of data to add as params. The struct key will be used as the param name, and the value as the param's value. If you need to pass in multiple values, make the value an array of values." />
		<cfreturn application.stPlugins["farcrysolrpro"].cfsolrlib.search(argumentCollection = arguments) />
	</cffunction>
	
	<cffunction name="deleteByID" access="public" output="false" hint="Delete a document from the index by ID">
		<cfargument name="id" type="string" required="true" hint="ID of object to delete.">
		<cfargument name="bCommit" type="boolean" required="false" default="false" />
		<cfset application.stPlugins["farcrysolrpro"].cfsolrlib.deleteById(id = arguments.id, idFieldName = "objectid") />
		<cfif arguments.bCommit>
			<cfset commit() />
		</cfif>
	</cffunction>
	
	<cffunction name="deleteByQuery" access="public" output="false" returntype="void">
		<cfargument name="q" type="string" required="true" />
		<cfset application.stPlugins["farcrysolrpro"].cfsolrlib.deleteByQuery(q = arguments.q) />
	</cffunction>
	
	<!--- helper --->
	<cffunction name="listCompare" output="false" returnType="string">
	   <cfargument name="list1" type="string" required="true" />
	   <cfargument name="list2" type="string" required="true" />
	   <cfargument name="delim1" type="string" required="false" default="," />
	   <cfargument name="delim2" type="string" required="false" default="," />
	   <cfargument name="delim3" type="string" required="false" default="," />
		<!---
		 Compares one list against another to find the elements in the first list that don't exist in the second list.
		 v2 mod by Scott Coldwell
		 
		 @param List1      Full list of delimited values. (Required)
		 @param List2      Delimited list of values you want to compare to List1. (Required)
		 @param Delim1      Delimiter used for List1.  Default is the comma. (Optional)
		 @param Delim2      Delimiter used for List2.  Default is the comma. (Optional)
		 @param Delim3      Delimiter to use for the list returned by the function.  Default is the comma. (Optional)
		 @return Returns a delimited list of values. 
		 @author Rob Brooks-Bilson (rbils@amkor.com) 
		 @version 2, June 25, 2009 
		--->
	   <cfset var list1Array = ListToArray(arguments.List1,Delim1) />
	   <cfset var list2Array = ListToArray(arguments.List2,Delim2) />
	
	   <!--- Remove the subset List2 from List1 to get the diff --->
	   <cfset list1Array.removeAll(list2Array) />
	
	   <!--- Return in list format --->
	   <cfreturn ArrayToList(list1Array, Delim3) />
	</cffunction>
	
	<cffunction name="isSolrRunning" access="public" returntype="boolean" output="false">
		<cftry>
			
			<cfset var host = application.fapi.getConfig(key = 'solrserver', name = 'host') />
			<cfset var port = application.fapi.getConfig(key = 'solrserver', name = 'port') />
			<cfset var path = application.fapi.getConfig(key = 'solrserver', name = 'path') /> 
			<cfset var uri = "http://" & host & ":" & port & path & "/admin/ping" />
			<cfset var httpResult = {} />
			
			<!--- check that Solr is responding --->
			<cfhttp url="#uri#" method="get" result="httpResult" />
			
			<cfif not isXml(httpResult.FileContent)>
				<cfreturn false />
			<cfelse>
				<cfset var xml = xmlParse(httpResult.fileContent) />
				<cfset var matches = XmlSearch(xml,"//response/str[@name='status']") />
				<cfif arrayLen(matches)>
					<cfreturn matches[1].xmlText eq "OK" />
				<cfelse>
					<cfreturn false />
				</cfif>
			</cfif>
			
			<cfcatch>
				<cfreturn false />
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="reload" access="public" returntype="void" output="false">
		<cfset var host = application.fapi.getConfig(key = 'solrserver', name = 'host') />
		<cfset var port = application.fapi.getConfig(key = 'solrserver', name = 'port') />
		<cfset var collectionName = application.fapi.getConfig(key = 'solrserver', name = 'collectionName') />
		<cfset var uri = "http://" & host & ":" & port & "/solr/admin/cores?action=RELOAD&core=" & collectionName />
		<cfhttp url="#uri#" method="get" />
	</cffunction>
	
</cfcomponent>