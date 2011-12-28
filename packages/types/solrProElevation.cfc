<cfcomponent output="false" extends="farcry.core.packages.types.types" displayname="Elevation" hint="Manages elevation data for Solr Pro Plugin" bFriendly="false" bObjectBroker="false">
	
	<cfproperty ftSeq="110" ftFieldset="Elevation" ftLabel="Search String" bLabel="true" name="searchString" type="nstring" ftType="string" required="true" ftValidation="required" ftHint="The search string to elevate." />
	<cfproperty ftSeq="120" ftFieldset="Elevation" ftLabel="Documents" name="aDocuments" type="array" ftType="array" ftJoinMethod="getContentTypes" ftAllowCreate="false" ftAllowEdit="false" ftHint="The documents to elevate for this search string" />
	
	<cffunction name="getContentTypes" access="public" output="false" returntype="string">
		<cfset var oType = application.fapi.getcontenttype("solrProContentType") />
		<cfset var q = oType.getAllContentTypes() />
		<cfreturn valueList(q.contentType) />
	</cffunction>
	
	<cffunction name="getAllElevationRecords" access="public" output="false" returntype="query">
		<cfset var q = "" />
		<cfquery name="q" datasource="#application.dsn#">
			select objectid from solrProElevation;
		</cfquery>
		<cfreturn q />
	</cffunction>
	
	<cffunction name="ftValidateSearchString" access="public" output="true" returntype="struct" hint="This will return a struct with bSuccess and stError">
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
			select objectid from solrProElevation where searchString = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.stFieldPost.value)#" /> and objectid <> <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.objectid#" />; 
		</cfquery>
		
		<cfif qDupeCheck.recordCount gt 0>
			<cfset stResult = oField.failed(value=arguments.stFieldPost.value, message="The search term #trim(arguments.stFieldPost.value)# has already been used.  Solr does not allow duplicate search terms.") />
		</cfif>

		<cfreturn stResult />
		
	</cffunction>	
	
	<cffunction name="generateElevateXml" access="public" output="false" returntype="void">
		
		<!--- regenerate XML file in its entirety since we cannot match a <query /> block to an elevation record in the database --->
		
		<cfset var instanceDir = application.fapi.getConfig(key = "solrserver", name = "instanceDir") />
		<cfset var dataDir = instanceDir & "/data" />
		<cfset var xmlFilePath = dataDir & "/elevate.xml" />
		
		<!--- load elevation data --->
		<cfset var qElevation = getAllElevationRecords() />
		
		<cfset var xml = "" />
		<cfsavecontent variable="xml">
		<cfoutput>
		<?xml version="1.0" encoding="UTF-8" ?>
		<!-- If this file is found in the config directory, it will only be
		     loaded once at startup.  If it is found in Solr's data
		     directory, it will be re-loaded every commit.
		-->
		<elevate>
		</cfoutput>
		
		<cfset var st = "" />
		<cfset var docId = "" />
		
		<!--- loop over each and output XML --->
		<cfloop query="qElevation">
			
			<cfset st = getData(qElevation.objectid[qElevation.currentRow]) />
			
			<cfoutput>
			<query text="#xmlFormat(st.searchString)#"></cfoutput>
			
				<cfloop array="#st.aDocuments#" index="docId">
					<cfoutput>
					<doc id="#docId#" /></cfoutput>
				</cfloop>
				
			<cfoutput>
			</query></cfoutput>
			
		</cfloop>
		
		<cfoutput>
		</elevate>
		</cfoutput>
		
		</cfsavecontent>
		
		<!--- save xml file --->
		<cffile action="write" file="#xmlFilePath#" output="#trim(xml)#" addnewline="false" />
		
		<!--- call solr commit so Solr will pick up the changes to elevate.xml --->
		<cfset application.fapi.getContentType("solrProContentType").commit() />
		
	</cffunction>
	
	<cffunction name="onDelete" returntype="void" access="public" output="false" hint="Is called after the object has been removed from the database">
		<cfargument name="typename" type="string" required="true" hint="The type of the object" />
		<cfargument name="stObject" type="struct" required="true" hint="The object" />
		
		<cfset generateElevateXml() />
		
	</cffunction>
	
	<cffunction name="AfterSave" access="public" output="false" returntype="struct" hint="Called from setData and createData and run after the object has been saved.">
		<cfargument name="stProperties" required="yes" type="struct" hint="A structure containing the contents of the properties that were saved to the object.">
		
		<cfset generateElevateXml() />
		
		<cfreturn super.afterSave(argumentCollection = arguments) />
		
	</cffunction>
	
</cfcomponent>