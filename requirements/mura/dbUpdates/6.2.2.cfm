<cfscript>
	getBean('userDevice').checkSchema();
	dbUtility.setTable("tsettings").addColumn(column="sendAuthCodeScript",dataType="longtext");
	dbUtility.setTable("tclassextendattributes").addColumn(column="adminonly",dataType="integer");
	dbUtility.setTable("tclassextend").addColumn(column="adminonly",dataType="integer");
	dbUtility.setTable("tcontentfeeds").addColumn(column="authtype",dataType="varchar",length=10);
	
	try{
		dbUtility.setTable("tcontentfeeds").addColumn(column="channellink",dataType="longtext");
	} catch (any e){}; 
</cfscript>