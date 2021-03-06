<cfsetting enablecfoutputonly="true" />
<cfoutput>
strong {
	font-weight: bold;
}
em {
	font-style: italic;
}
h1 {
	margin: 1.2em 0 0;
}
p {
	margin: .5em 0;
}
code,
.code,
var {
	color: ##555;
	font: 1.1em monospace;
	background-color: ##eee;
	padding: 0.3em 0.5em;
}
ul, ol {
	margin: .5em 0 .5em 1em;
}
ul ul,
ol ol {
	margin-left: 0;
}
ul li {
	margin-left: 1em;
	list-style: disc outside none;
}
ol li {
	margin-left: 1em;
	list-style: decimal outside none;
}
ul li li {
	list-style: square outside none;
}
ul.features li {
	font-weight: bold;
}
ul.features li li {
	font-weight: normal;
}
li.nolistyle {
	margin-left: 0;
	list-style: none;
}
table.solrprotable {
	margin: .85em 0;
	border-collapse: collapse;
	font-size: 1em;
	width: 100%;
}
table.solrprotable caption {
	font: bold 145% arial;
	padding: 5px 10px;
	text-align: left;
}
table.solrprotable td,
table.solrprotable th {
	border: 1px solid ##eee;
	padding: .6em 10px;
	text-align: left;
	vertical-align: top;
}
table.solrprotable tr:nth-child(even) {
	background: none repeat scroll 0 0 ##F1F1F1;
}

/***********************************************************/
/**                    Version Updater                    **/
/***********************************************************/
div.version {
	margin-bottom: 20px;
}
div.version h2 {
	font-size: 135%;
}
div.version h3 {
	font-size: 116%;
}
div.version div.versiondesc {
  margin-bottom: 12px;
}

/***********************************************************/
/**                styles specifically for                **/
/**          webskin/solrProContentType/edit.cfm          **/
/***********************************************************/
.combobox a {
	text-decoration: none;
	vertical-align: middle;
	padding-right: 0.4em;
}
.combobox a:hover {
	background: transparent;
}
.combobox input {
	width: 4em;
}
/* Uniform override */
.uniForm .inlineLabels .multiField {
	width: 60%;
}
.fieldTypeDropdown {
	vertical-align: middle;
}
.fieldType {
	padding: 0.25em 0 0.25em 0.5em;
}
.fieldType span {
	margin-left: 0.25em;
	margin-right: 0.25em;
}
.fieldType div.fieldTypeAttributesLeft {
	min-width: 35em;
}
.fieldType div.fieldTypeAttributesLeft span {
	vertical-align: middle;
}
.fieldType div.fieldTypeAttributesRight {
	float: right;
}
.fieldType div.fieldTypeAttributesRight div {
	display: inline;
	padding-left: 0.5em;
	vertical-align: middle;
}
.fieldType div.fieldTypeAttributesRight div input {
	vertical-align: middle;
}
.fieldType div.buttonset label:not(.ui-state-active) span {
	color: ##888 !important;
}
.fieldType div.buttonset label span {
	font-size: 0.8em;
	padding: 0.1em 0.4em;
}
table.fcproperties {
	margin: .85em 0;
	border-collapse: collapse;
	font-size: 1em;
}
table.fcproperties caption {
	font: bold 145% arial;
	padding: 5px 10px;
	text-align: left;
}
table.fcproperties td,
table.fcproperties th {
	border: 1px solid ##eee;
	padding: .6em 10px;
	text-align: left;
	vertical-align: top;
}
table.fcproperties tr:nth-child(even),
table.fcproperties tr.alt  {
	background: none repeat scroll 0 0 ##F1F1F1;
}
##indexedProperties {
	max-width: 900px;
	min-width: 500px;
}
##tblCustomProperties {
	width: 100%;
}
##tblCustomProperties tbody tr td:nth-child(1) {
	padding-top: .8em;
}
##tblCustomProperties thead tr th:nth-child(4) {
	width: 55%;
	white-space: nowrap;
}
ol.ui-autocomplete li,
ul.ui-autocomplete li {
	list-style: none;
}
div.rule {
	float: left;
	width: 269px;
	margin: 5px 5px 5px 0;
}
div.rule div.indexRuleDescription {
	 margin-left: 1.3em;
}
div.rule label span {
	 font-style: italic;
}
div.rule input {
	float: left;
	margin-top: 0.2em;
}
##lSummaryFields {
	margin: 10px 0;
	min-height: 100%;
	height: auto;
}
##lSummaryFields label {
	float: left;
	width: 185px;
	margin: 2px 0;
}
##lSummaryFields label input {
	margin-right: 5px;
}
##helpInfo {
	padding: 0.4em;
	position: relative;
	margin: 1em 0;
}
##helpInfo h3 {
	margin: 0 0 1em 0;
	padding: 0.4em;
	text-align: center;
}
##helpInfo h4 {
	font-size: 125%;
}
##helpInfo h5 {
	font-size: 110%;
}
##helpInfo h6 {
	font-size: 95%;
}
##helpInfo div {
	margin: 0 1em;
}
##helpInfo div##helpInfoBody {
  display: none; /* default value overridden by jQuery show/hide */
  margin-top: 10px;
}
##helpInfo div.showInfo {
		margin-top: 10px;
}
##helpInfo a.showHelpInfoTrue,
##helpInfo a.showHelpInfoTrue:hover {
		background: transparent url(#application.fapi.getConfig(key = 'solrserver',name = 'pluginWebRoot',default='/farcrysolrpro')#/css/images/glyph-down.gif) no-repeat scroll right top;
		padding-right: 13px;
}
##helpInfo a.showHelpInfoFalse,
##helpInfo a.showHelpInfoFalse:hover {
		background: transparent url(#application.fapi.getConfig(key = 'solrserver',name = 'pluginWebRoot',default='/farcrysolrpro')#/css/images/glyph-up.gif) no-repeat scroll right top;
		padding-right: 13px;
}
##helpInfo p {
	margin: 0.5em 0;
}
##helpInfo ul {
	margin-left: 1em;
}
##helpInfo ul ul {
	margin-left: 0;
}
##helpInfo li {
	margin-left: 1em;
	list-style: disc outside none;
}
##helpInfo li.nolistyle {
	margin-left: 0;
	list-style: none;
}
</cfoutput>
<cfsetting enablecfoutputonly="false" />