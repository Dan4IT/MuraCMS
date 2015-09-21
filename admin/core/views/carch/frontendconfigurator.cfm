﻿<cfsilent>
	<cfset event=request.event>
	<cfset $=rc.$>
	<cfparam name="rc.layoutmanager" default="false">
</cfsilent>
<cfinclude template="js.cfm">
<cfif rc.layoutmanager>
	<cfoutput>
	<div id="configuratorContainer">
		<h1 id="configuratorHeader">Loading...</h1>
		
		<div class="clearfix">
		    <div id="configurator"><div class="load-inline"></div></div>
		   <!---
		    <div style="float: right; width: 30%;"><h2>Preview</h2>
		    	<iframe id="configuratorPreview" style="width:100%;height:700px;" marginheight="0" marginwidth="0" frameborder="0" src=""></iframe>
		    </div>
		    --->
		</div>
		
		<div class="form-actions">	
			<input type="button" class="btn" id="saveConfigDraft" value="#esapiEncode('html_attr',application.rbFactory.getKeyValue(session.rb,"sitemanager.content.save"))#"/>
		</div>
	</div>
	<cfinclude template="dsp_configuratorJS.cfm">
	<script>
		siteManager.configuratorMode='frontEnd';
		siteManager.layoutmanager=true;

		var instanceid='#esapiEncode('javascript',rc.instanceid)#';
		var configOptions={};

		jQuery(document).ready(function(){

			function initConifuratorProxy(){

				function onFrontEndMessage(messageEvent){
					
					var parameters=messageEvent.data;
					
					if (parameters["cmd"] == "setObjectParams") {
						
						configParams=parameters["params"];
						
						configOptions={
							'object':'#esapiEncode('javascript',rc.object)#',
							'objectid':'#esapiEncode('javascript',rc.objectid)#',
							'name':'#esapiEncode('javascript',rc.objectname)#',
							'regionid':'0',
							'context':'#application.configBean.getContext()#',
							'params':JSON.stringify(parameters["params"]),
							'siteid':'#esapiEncode('javascript',rc.siteid)#',
							'contenthistid':'#esapiEncode('javascript',rc.contenthistid)#',
							'contentid':'#esapiEncode('javascript',rc.contentID)#',
							'parentid':'#esapiEncode('javascript',rc.parentID)#',
							'contenttype':'#esapiEncode('javascript',rc.contenttype)#',
							'contentsubtype':'#esapiEncode('javascript',rc.contentsubtype)#'
						}
						
						<cfset configuratorWidth=600>

						<cfif $.siteConfig().hasDisplayObject(rc.object)>
							var configurator=siteManager.getPluginConfigurator('#esapiEncode('javascript',rc.objectid)#');

							if(configurator!=''){
								window[configurator](
									configOptions
								);
							} else {
								$('##configurator').html('');
							}

							jQuery("##configuratorHeader").html('Configure #esapiEncode('javascript',rc.objectname)#');
						<cfelse>
							<cfswitch expression="#rc.object#">
								<cfcase value="form,form_responses,component">
									
									<cfset content=rc.$.getBean('content').loadBy(contentid=rc.objectid)>

									<cfif content.exists()>
										<cfif listFindNoCase('Author,Editor',application.permUtility.getDisplayObjectPerm(content.getSiteID(),"component",content.getContentID()))>
										
										<cflocation url="#content.getEditURL(compactDisplay=true)#&homeid=#esapiEncode('url',rc.contentid)#" addtoken="false">
										<cfelse>
											<cfif rc.object eq 'Form'>
												jQuery("##configuratorHeader").html('Edit Form');
												<cfset configuratorWidth='standard'>
											<cfelseif rc.object eq 'Component'>
												jQuery("##configuratorHeader").html('Edit Component');
												<cfset configuratorWidth='standard'>

											</cfif>
											jQuery("##configurator").html('<p class="alert alert-error">You do not have permission to edit this form.</p>');
										</cfif>
									<cfelse>
										configOptions.title='Select ' + configOptions.name;
										siteManager.initGenericConfigurator(configOptions);
									</cfif>
								</cfcase>
								<cfdefaultcase>
									if(siteManager.objectHasConfigurator(configOptions)){
										siteManager.configuratorMap[configOptions.object].initConfigurator(configOptions);
									} else {
										siteManager.initGenericConfigurator(configOptions);
									}
									
								</cfdefaultcase>
							</cfswitch>
						</cfif>

						//siteManager.loadObjectPreview(configOptions);
					
					}
				}

				frontEndProxy.addEventListener(onFrontEndMessage);
				frontEndProxy.post({cmd:'setWidth',width:'#configuratorWidth#'});
				frontEndProxy.post({cmd:'requestObjectParams',instanceid:'#esapiEncode("javascript",rc.instanceid)#'});
		
			}

			if (top.location != self.location) {
				if(jQuery("##ProxyIFrame").length){
					jQuery("##ProxyIFrame").load(
						function(){
							initConifuratorProxy()
						}
					);	
				} else {
					initConifuratorProxy();
				}
			}

			$('##configurator .load-inline').spin(spinnerArgs2);
			
			jQuery("##saveConfigDraft").bind("click",
			function(){
				
				siteManager.updateAvailableObject();

				var availableObjectSelector=jQuery('##availableObjectSelector');

				if(availableObjectSelector.length){
					$.extend(siteManager.availableObject.params,eval('(' + availableObjectSelector.val() + ')') );
				}
				
				if (siteManager.availableObjectValidate(siteManager.availableObject.params)) {
					jQuery("##configurator").html('<div class="load-inline"></div>');
					$('##configurator .load-inline').spin(spinnerArgs2);
					jQuery(".form-actions").hide();
									
					frontEndProxy.post(
					{
						cmd:'setObjectParams',
						instanceid:instanceid,
						params:siteManager.availableObject.params
					});

				}
			});
				
			
		});
	</script>
	</cfoutput>
<cfelse>
	<cfsilent>
		<cfset rsDisplayObject=application.contentManager.readContentObject(rc.contentHistID,rc.regionID,rc.orderno)>
		<cfset rc.siteid=rsDisplayObject.siteid>

		<cfif rsDisplayObject.object eq "plugin">
			<cfset displayObjectBean=application.serviceFactory.getBean('pluginDisplayObjectBean').setObjectID(rsDisplayObject.objectid).load()>
				<cfset displayObjectBean.load()>
				<cfset hasConfigurator=len(displayObjectBean.getConfiguratorJS())>
		</cfif>

		<cfset rc.contentBean=application.contentManager.getContentVersion(contentHistID=rsDisplayObject.contenthistid,siteID=rsDisplayObject.siteid)>
		<cfset rc.perm=application.permUtility.getNodePerm(application.contentGateway.getCrumblist(rc.contentBean.getContentID(),rc.contentBean.getSiteID()))>
		<cfset rc.homeBean=application.contentManager.getActiveContent(contentID=rc.homeID,siteID=rsDisplayObject.siteid)>
		<cfset hasChangesets=application.settingsManager.getSite(rsDisplayObject.siteID).getHasChangesets()>

		<cfif hasChangesets>
			<cfset currentChangeset=application.changesetManager.read(rc.contentBean.getChangesetID())>
			<cfset pendingChangesets=application.changesetManager.getPendingByContentID(rc.contentBean.getContentID(),rc.siteID)>
		</cfif>

		<cfset assignChangesets=rc.perm eq 'editor' and hasChangesets>
		<cfset $=event.getValue("MuraScope")>
		
		<cfif isDefined('arguments.rc.locknode') and arguments.rc.locknode>
			<cfset stats=arguments.rc.contentBean.getStats()>
			<cfif not len(stats.getLockID()) or stats.getLockID() eq session.mura.userid>
				<cfset stats.setLockID(session.mura.userID).setLockType('node').save()>
			</cfif>
		</cfif>
	</cfsilent>
	<cfoutput>
	<cfif rc.compactDisplay eq "true">
	<script type="text/javascript">
	jQuery(document).ready(function(){
		if (top.location != self.location) {
			if(jQuery("##ProxyIFrame").length){
				jQuery("##ProxyIFrame").load(
					function(){
						frontEndProxy.post({cmd:'setWidth',width:'standard'});
					}
				);	
			} else {
				frontEndProxy.post({cmd:'setWidth',width:'standard'});
			}
		}
	});
	</script>
	</cfif> 

	<div id="configuratorContainer">
		<h1 id="configuratorHeader">Loading...</h1>
		<div id="configuratorNotices" style="display:none;">
		<cfif not rc.contentBean.getIsNew()>
		<cfset draftcheck=application.contentManager.getDraftPromptData(rc.contentBean.getContentID(),rc.contentBean.getSiteID())>
		
		<cfif yesNoFormat(draftcheck.showdialog) and draftcheck.historyid neq rc.contentBean.getContentHistID()>
		<p class="alert">
		#application.rbFactory.getKeyValue(session.rb,'sitemanager.draftprompt.inline')#: <strong><a href="?muraAction=cArch.edit&moduleID=#esapiEncode('url',rc.contentBean.getModuleID())#&siteID=#esapiEncode('url',rc.contentBean.getSiteID())#&topID=#esapiEncode('url',rc.contentBean.getContentID())#&contentID=#esapiEncode('url',rc.contentBean.getContentID())#&return=#esapiEncode('url',rc.return)#&contentHistID=#draftcheck.historyID#&parentID=#esapiEncode('url',rc.contentBean.getParentID())#&startrow=#esapiEncode('url',rc.startrow)#&compactDisplay=true&homeID=#esapiEncode('html',rc.homeBean.getContentID())#">#application.rbFactory.getKeyValue(session.rb,'sitemanager.draftprompt.gotolatest')#</a></strong>
		<p>
		</cfif>
		</cfif>
		
		<cfif hasChangesets and (not currentChangeset.getIsNew() or pendingChangesets.recordcount)>
		<p class="alert">
		<cfif pendingChangesets.recordcount>#application.rbFactory.getKeyValue(session.rb,"sitemanager.content.changesetnodenotify")#: 
		<cfloop query="pendingChangesets"><a href="?muraAction=cArch.edit&moduleID=#esapiEncode('url',rc.contentBean.getModuleID())#&siteID=#esapiEncode('url',rc.contentBean.getSiteID())#&topID=#esapiEncode('url',rc.contentBean.getContentID())#&contentID=#esapiEncode('url',rc.contentBean.getContentID())#&return=#esapiEncode('url',rc.return)#&contentHistID=#pendingChangesets.contentHistID#&parentID=#esapiEncode('url',rc.contentBean.getParentID())#&startrow=#esapiEncode('url',rc.startrow)#&compactDisplay=true&homeID=#esapiEncode('html',rc.homeBean.getContentID())#">"#esapiEncode('html_attr',pendingChangesets.changesetName)#"</a><cfif pendingChangesets.currentrow lt pendingChangesets.recordcount>, </cfif></cfloop><br/></cfif>
		<cfif not currentChangeset.getIsNew()>#application.rbFactory.getKeyValue(session.rb,"sitemanager.content.changesetversionnotify")#: "#esapiEncode('html_attr',currentChangeset.getName())#"</cfif>
		</p>
		</cfif>
		</div>
		<div id="configurator">
			<div class="load-inline"></div>
		</div>	

		<cfif assignChangesets>
			<cfinclude template="form/dsp_changesets.cfm">
		</cfif>

		<div class="form-actions">	
			<input type="button" class="btn" id="saveConfigDraft" value="#esapiEncode('html_attr',application.rbFactory.getKeyValue(session.rb,"sitemanager.content.savedraft"))#"/>
			<input type="button" class="btn" id="previewConfigDraft" value="#esapiEncode('html_attr',application.rbFactory.getKeyValue(session.rb,"sitemanager.content.preview"))#"/>
			<cfif assignChangesets>
				<input type="button" class="btn" onclick="saveToChangeset('#rc.contentBean.getChangesetID()#','#esapiEncode('html',rsDisplayObject.siteid)#','');return false;" value="#application.rbFactory.getKeyValue(session.rb,"sitemanager.content.savetochangeset")#" />	
			</cfif>
			<cfif rc.perm eq 'editor' and not $.siteConfig('EnforceChangesets')>
				<input type="button" class="btn" id="publishConfig" value="#esapiEncode('html_attr',application.rbFactory.getKeyValue(session.rb,"sitemanager.content.publish"))#"/>
			</cfif>
		</div>
	</div>
	<script>
	siteManager.configuratorMode='frontEnd';

	jQuery(document).ready(function(){

		$('##configurator .load-inline').spin(spinnerArgs2);

		if(jQuery("##ProxyIFrame").length){
			jQuery("##ProxyIFrame").load(
				function(){
					frontEndProxy.post({cmd:'setWidth',width:'configurator'});
				}
			);	
		} else {
			frontEndProxy.post({cmd:'setWidth',width:'configurator'});
		}
		
		<cfif $.siteConfig().hasDisplayObject(rsDisplayObject.object)>
			var configurator=siteManager.getPluginConfigurator('#esapiEncode('javascript',rsDisplayObject.objectid)#');
					window[configurator](
						{
							'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
							'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
							'name':'#esapiEncode('javascript',rsDisplayObject.name)#',
							'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
							'context':'#application.configBean.getContext()#',
							'params':'#esapiEncode('javascript',rsDisplayObject.params)#',
							'siteid':'#esapiEncode('javascript',rc.contentBean.getSiteID())#',
							'contenthistid':'#esapiEncode('javascript',rc.contentBean.getContentHistID())#',
							'contentid':'#esapiEncode('javascript',rc.contentBean.getContentID())#',
							'parentid':'#esapiEncode('javascript',rc.contentBean.getParentID())#'
						}
					);
					jQuery("##configuratorHeader").html('#esapiEncode('javascript',rsDisplayObject.name)#');
		<cfelse>
			<cfswitch expression="#rsDisplayObject.object#">
				<cfcase value="feed,feed_no_summary,remoteFeed">	
					siteManager.initFeedConfigurator({
								'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
								'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
								'name':'#esapiEncode('javascript',rsDisplayObject.name)#',
								'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
								'context':'#application.configBean.getContext()#',
								'params':'#esapiEncode('javascript',rsDisplayObject.params)#',
								'siteid':'#esapiEncode('javascript',rsDisplayObject.siteid)#',
								'contenthistid':'#esapiEncode('javascript',rc.contentBean.getContentHistID())#',
								'contentid':'#esapiEncode('javascript',rc.contentBean.getContentID())#',
								'parentid':'#esapiEncode('javascript',rc.contentBean.getParentID())#'		
							});
				</cfcase>
				<cfcase value="feed_slideshow,feed_slideshow_no_summary">	
					siteManager.initSlideShowConfigurator({
								'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
								'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
								'name':'#esapiEncode('javascript',rsDisplayObject.name)#',
								'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
								'context':'#application.configBean.getContext()#',
								'params':'#esapiEncode('javascript',rsDisplayObject.params)#',
								'siteid':'#esapiEncode('javascript',rsDisplayObject.siteid)#',
								'contenthistid':'#esapiEncode('javascript',rc.contentBean.getContentHistID())#',
								'contentid':'#esapiEncode('javascript',rc.contentBean.getContentID())#',
								'parentid':'#esapiEncode('javascript',rc.contentBean.getParentID())#'
							});
				</cfcase>
				<cfcase value="category_summary,category_summary_rss">	
					siteManager.initCategorySummaryConfigurator({
								'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
								'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
								'name':'#esapiEncode('javascript',rsDisplayObject.name)#',
								'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
								'context':'#application.configBean.getContext()#',
								'params':'#esapiEncode('javascript',rsDisplayObject.params)#',
								'siteid':'#esapiEncode('javascript',rsDisplayObject.siteid)#',
								'contenthistid':'#esapiEncode('javascript',rc.contentBean.getContentHistID())#',
								'contentid':'#esapiEncode('javascript',rc.contentBean.getContentID())#',
								'parentid':'#esapiEncode('javascript',rc.contentBean.getParentID())#'		
							});
				</cfcase>
				<cfcase value="tag_cloud">	
					siteManager.initTagCloudConfigurator({
								'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
								'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
								'name':'#esapiEncode('javascript',rsDisplayObject.name)#',
								'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
								'context':'#application.configBean.getContext()#',
								'params':'#esapiEncode('javascript',rsDisplayObject.params)#',
								'siteid':'#esapiEncode('javascript',rsDisplayObject.siteid)#',
								'contenthistid':'#esapiEncode('javascript',rc.contentBean.getContentHistID())#',
								'contentid':'#esapiEncode('javascript',rc.contentBean.getContentID())#',
								'parentid':'#esapiEncode('javascript',rc.contentBean.getParentID())#'		
							});
				</cfcase>
				<cfcase value="site_map">	
					siteManager.initSiteMapConfigurator({
								'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
								'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
								'name':'#esapiEncode('javascript',rsDisplayObject.name)#',
								'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
								'context':'#application.configBean.getContext()#',
								'params':'#esapiEncode('javascript',rsDisplayObject.params)#',
								'siteid':'#esapiEncode('javascript',rsDisplayObject.siteid)#',
								'contenthistid':'#esapiEncode('javascript',rc.contentBean.getContentHistID())#',
								'contentid':'#esapiEncode('javascript',rc.contentBean.getContentID())#',
								'parentid':'#esapiEncode('javascript',rc.contentBean.getParentID())#'		
							});
				</cfcase>
				<cfcase value="related_content,related_section_content">	
					siteManager.initRelatedContentConfigurator({
								'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
								'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
								'name':'#esapiEncode('javascript',rsDisplayObject.name)#',
								'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
								'context':'#application.configBean.getContext()#',
								'params':'#esapiEncode('javascript',rsDisplayObject.params)#',
								'siteid':'#esapiEncode('javascript',rsDisplayObject.siteid)#',
								'contenthistid':'#esapiEncode('javascript',rc.contentBean.getContentHistID())#',
								'contentid':'#esapiEncode('javascript',rc.contentBean.getContentID())#',
								'parentid':'#esapiEncode('javascript',rc.contentBean.getParentID())#'		
							});
				</cfcase>
				<cfcase value="plugin">	
					var configurator=siteManager.getPluginConfigurator('#esapiEncode('javascript',rsDisplayObject.objectid)#');
					window[configurator](
						{
							'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
							'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
							'name':'#esapiEncode('javascript',rsDisplayObject.name)#',
							'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
							'context':'#application.configBean.getContext()#',
							'params':'#esapiEncode('javascript',rsDisplayObject.params)#',
							'siteid':'#esapiEncode('javascript',rc.contentBean.getSiteID())#',
							'contenthistid':'#esapiEncode('javascript',rc.contentBean.getContentHistID())#',
							'contentid':'#esapiEncode('javascript',rc.contentBean.getContentID())#',
							'parentid':'#esapiEncode('javascript',rc.contentBean.getParentID())#'
						}
					);
					jQuery("##configuratorHeader").html('#esapiEncode('javascript',rsDisplayObject.name)#');
				</cfcase>
			</cfswitch>
		</cfif>
			
		jQuery("##publishConfig").bind("click",
			function(){
				
				if (draftremovalnotice != "" &&
				!confirm(draftremovalnotice)) {
					return false;
				}
				
				siteManager.updateAvailableObject();
				
				if (siteManager.availableObjectValidate(siteManager.availableObject.params)) {
					jQuery("##configurator").html('<div class="load-inline"></div>');
					$('##configurator .load-inline').spin(spinnerArgs2);
					jQuery(".form-actions").hide();
					jQuery("##configuratorNotices").hide();
					
					jQuery.post("./index.cfm?muraAction=cArch.updateObjectParams#rc.$.renderCSRFTokens(context=rsDisplayObject.contentHistID & 'add',format='url')#", {
						'contenthistid': '#esapiEncode('javascript',rsDisplayObject.contentHistID)#',
						'objectid': '#esapiEncode('javascript',rsDisplayObject.objectid)#',
						'regionid': '#esapiEncode('javascript',rsDisplayObject.columnid)#',
						'orderno': '#esapiEncode('javascript',rsDisplayObject.orderno)#',
						'siteid': '#esapiEncode('javascript',rsDisplayObject.siteid)#',
						'params': JSON.stringify(siteManager.availableObject.params),
						'approved': 1,
						'object': '#esapiEncode('javascript',rsDisplayObject.object)#',
						'name': '#esapiEncode('javascript',rsDisplayObject.name)#',
						'changesetid': '',
						'removepreviouschangeset': false,
						'preview': 0
					}, function(){
						frontEndProxy.post({cmd:'setLocation',location:'#esapiEncode('javascript',rc.homeBean.getURL())#'});
					});
				}
			});
		
		jQuery("##saveConfigDraft").bind("click",
			function(){
				
				siteManager.updateAvailableObject();
				
				if (siteManager.availableObjectValidate(siteManager.availableObject.params)) {
					jQuery("##configurator").html('<div class="load-inline"></div>');
					$('##configurator .load-inline').spin(spinnerArgs2);
					jQuery(".form-actions").hide();
					jQuery("##configuratorNotices").hide();
					
					jQuery.post("./index.cfm?muraAction=cArch.updateObjectParams", {
						'contenthistid': '#esapiEncode('javascript',rsDisplayObject.contentHistID)#',
						'objectid': '#esapiEncode('javascript',rsDisplayObject.objectid)#',
						'regionid': '#esapiEncode('javascript',rsDisplayObject.columnid)#',
						'orderno': '#esapiEncode('javascript',rsDisplayObject.orderno)#',
						'siteid': '#esapiEncode('javascript',rsDisplayObject.siteid)#',
						'params': JSON.stringify(siteManager.availableObject.params),
						'approved': 0,
						'object': '#esapiEncode('javascript',rsDisplayObject.object)#',
						'name': '#esapiEncode('javascript',rsDisplayObject.name)#',
						'changesetid': '',
						'removepreviouschangeset': false,
						'preview': 0
					}, function(){
						frontEndProxy.post({cmd:'setLocation',location:'#esapiEncode('javascript',rc.homeBean.getURL())#'});
					});
				}
			});
			
			jQuery("##previewConfigDraft").bind("click",
			function(){
				
				siteManager.updateAvailableObject();
					
				if (siteManager.availableObjectValidate(siteManager.availableObject.params)) {
					jQuery("##configurator").html('<div class="load-inline"></div>');
					$('##configurator .load-inline').spin(spinnerArgs2);
					jQuery(".form-actions").hide();
					jQuery("##configuratorNotices").hide();
					
					jQuery.post("./index.cfm?muraAction=cArch.updateObjectParams",
					{
						'contenthistid':'#esapiEncode('javascript',rsDisplayObject.contentHistID)#',
						'objectid':'#esapiEncode('javascript',rsDisplayObject.objectid)#',
						'regionid':'#esapiEncode('javascript',rsDisplayObject.columnid)#',
						'orderno':'#esapiEncode('javascript',rsDisplayObject.orderno)#',
						'siteid':'#esapiEncode('javascript',rsDisplayObject.siteid)#',
						'params': JSON.stringify(siteManager.availableObject.params),
						'approved':0,
						'object':'#esapiEncode('javascript',rsDisplayObject.object)#',
						'name': '#esapiEncode('javascript',rsDisplayObject.name)#',
						'changesetid':'',
						'removepreviouschangeset':false,
						'preview':1	
					},
		
					function(raw){
						var resp=eval( "(" + raw + ")" );
						<cfset str=rc.homeBean.getURL()>
						var loc="#esapiEncode('javascript',str)#";
						<cfif find("?",str)>
						loc=loc + "&";
						<cfelse>
						loc=loc + "?";
						</cfif>
						//loc=loc + "contentID=" + resp.contentid;
						loc=loc + "previewID=" + resp.contenthistid;
						frontEndProxy.post({cmd:'setLocation',location:encodeURIComponent(loc)});
					}
				
					);
				}
			});
		
	});

	function saveConfiguratorToChangeset(changesetid,removepreviouschangeset){

		confirmDialog(publishitemfromchangeset, 
			function() {
				siteManager.updateAvailableObject();
				
				if (siteManager.availableObjectValidate(siteManager.availableObject.params)) {
					jQuery("##configurator").html('<div class="load-inline"></div>');
					$('##configurator .load-inline').spin(spinnerArgs2);
					jQuery(".form-actions").hide();
					
					jQuery.post("./index.cfm?muraAction=cArch.updateObjectParams", {
						'contenthistid': '#esapiEncode('javascript',rsDisplayObject.contentHistID)#',
						'objectid': '#esapiEncode('javascript',rsDisplayObject.objectid)#',
						'regionid': '#esapiEncode('javascript',rsDisplayObject.columnid)#',
						'orderno': '#esapiEncode('javascript',rsDisplayObject.orderno)#',
						'siteid': '#esapiEncode('javascript',rsDisplayObject.siteid)#',
						'params': JSON.stringify(siteManager.availableObject.params),
						'approved': 0,
						'object': '#esapiEncode('javascript',rsDisplayObject.object)#',
						'name': '#esapiEncode('javascript',rsDisplayObject.name)#',
						'changesetid': changesetid,
						'removepreviouschangeset': removepreviouschangeset,
						'preview': 0
					}, function(){
						frontEndProxy.post({cmd:'setLocation',location:'#esapiEncode('javascript',rc.homeBean.getURL())#'});
					});
					
				}
				 						
		});	
		
	}

	var draftremovalnotice=<cfif application.configBean.getPurgeDrafts() and event.getValue("suppressDraftNotice") neq "true" and rc.contentBean.hasDrafts()><cfoutput>'#esapiEncode('javascript',application.rbFactory.getKeyValue(session.rb,"sitemanager.content.draftremovalnotice"))#'</cfoutput><cfelse>""</cfif>;
	</script>
	<cfinclude template="dsp_configuratorJS.cfm">
	</cfoutput>
</cfif>