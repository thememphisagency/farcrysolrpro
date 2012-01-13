<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Search Result --->
<!--- @@author: Sean Coyne (www.n42designs.com), Jeff Coughlin (jeff@jeffcoughlin.com) --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<!--- load the solr content type configuration information --->
<cfparam name="stParam.oContentType" default="#application.fapi.getContentType('solrProContentType')#" />
<cfset stContentType = stParam.oContentType.getByContentType(contentType = stobj.typename) />

<cfparam name="stParam.highlighting" default="#structNew()#" />

<cfset oCustomFunctions = application.stPlugins.farcrysolrpro.oCustomFunctions />

<!--- TODO: Get default CSS file provided by plugin --->

<!--- Trim all stObj fields --->
<cfloop collection="#request.stObj#" item="i">
	<cfset request.stObj[i] = trim(request.stObj[i]) />
</cfloop>

<!--- Get result title --->
<cfif structKeyExists(stObj, stContentType.resultTitleField) and len(stObj[stContentType.resultTitleField])>
	<cfset variables.resultTitle = oCustomFunctions.xmlSafeText(stObj[stContentType.resultTitleField]) />
<cfelse>
	<cfset variables.resultTitle = oCustomFunctions.xmlSafeText(stObj.label) />
</cfif>

<!--- Get result teaser --->
<cfif len(trim(stContentType.resultSummaryField)) and structKeyExists(stObj, stContentType.resultSummaryField) and stObj[stContentType.resultSummaryField] neq "">
	<cfset variables.teaser = oCustomFunctions.tagStripped(stObj[stContentType.resultSummaryField]) />		
	<!--- abbreviate teaser --->
	<cfset teaser = oCustomFunctions.abbreviate(teaser, 450) />
<cfelse>
	<!--- use Solr generated summary --->
	<cfset variables.teaser = "" />
	<cfif structKeyExists(stParam.highlighting, "highlight") and isArray(stParam.highlighting["highlight"])>
		<cfloop array="#stParam.highlighting['highlight']#" index="hl">
			
			<!--- remove leading non-alphanumeric --->
			<cfset hl = trim(reReplaceNoCase(hl,"^[^a-z0-9]","")) />
			
			<!--- concatenate the highlighted text strings --->
			<cfset variables.teaser = variables.teaser & "..." & hl />
			
		</cfloop>
		<cfset variables.teaser = trim(variables.teaser) & "..." />
	</cfif>
</cfif>

<!--- Get result image teaser --->
<cfif structKeyExists(stObj, stContentType.resultImageField) and len(stObj[stContentType.resultImageField])>
	<!--- if the teaser image value is a UUID, then check if it points to a dmImage object.  if it does, use the ThumbnailImage as the teaser image --->
	<cfif isValid("uuid",stObj[stContentType.resultImageField])>
		<cfif application.fapi.findType(stObj[stContentType.resultImageField]) eq "dmImage">
			<cfset stImage = application.fapi.getContentObject(objectid = stObj[stContentType.resultImageField], typename = "dmImage") />
			<cfset variables.teaserImage = stImage["ThumbnailImage"] />
		</cfif>
	<cfelse>
		<cfset variables.teaserImage = stObj[stContentType.resultImageField] />
	</cfif>
<cfelse>
	<cfset variables.teaserImage = "" />
</cfif>

<!--- Highlight search string where found --->
<!---<cfset oSearchService = createobject("component", "farcry.plugins.farcrysolr.packages.custom.solrService").init() />
<cfset variables.teaser = oSearchService.highlightSummary(searchCriteria="#stParam.searchCriteria#", summary="#teaser#") />--->

<!--- Get result date --->
<cfif structKeyExists(stObj, "publishDate")>
	<cfset variables.resultDate = stObj.publishDate />
<cfelse>
	<cfset variables.resultDate = stObj.dateTimeLastUpdated />
</cfif>

<!--- Get result link --->
<skin:buildlink objectid="#stObj.objectID#" r_url="itemUri" />

<!--- Get Abbreviated Link --->
<cfsavecontent variable="abbrLink">
  <cfoutput>http://#cgi.server_name##itemUri#</cfoutput>
</cfsavecontent>
<cfif len(abbrLink) gt 83>
  <cfsavecontent variable="abbrLink">
    <cfoutput>http://#listFirst(cgi.server_name,'.')#<cfif listLen(cgi.server_name,'.') gte 2>.#listGetAt(cgi.server_name,2,'.')#</cfif>...#right(abbrLink, 60)#</cfoutput>
  </cfsavecontent>
</cfif>

    <cfoutput>
      <div class="searchResult">
        <div class="searchResultTitle">
          <h2><a href="#itemUri#" title="#variables.resultTitle#">#variables.resultTitle#</a></h2>
        </div></cfoutput>
        <cfif variables.teaserImage neq "" and fileExists(expandPath(variables.teaserImage))>
          <cfoutput><a href="#itemUri#" title="#variables.resultTitle#"><img src="#variables.teaserImage#" alt="#variables.resultTitle#" class="searchResultTeaserImage" /></a></cfoutput>
        </cfif>
        <cfoutput>
        <div class="searchResultContent">
          <p>#variables.teaser#<cfif right(variables.teaser,3) EQ "..."> <a href="#itemUri#" title="#variables.resultTitle#">more</a></cfif></p>
        </div>
        <div class="searchResultMeta">
          <div class="searchResultLocation"><skin:buildLink objectid="#stObj.objectId#" linkText="#abbrLink#" /></div>
          <div class="searchResultFileType">#application.stCoapi[stobj.typename].displayName#</div>
          <div class="searchResultDate divider">#dateFormat(variables.resultDate, "mmm d, yyyy")#<!--- #timeFormat(variables.resultDate, "h:mm tt")# ---></div>
        </div>
      </div>
    </cfoutput>



<cfsetting enablecfoutputonly="false" />