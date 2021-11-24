Include EnsSQLTypes

Class Oliver.SqlInsertOperation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "Oliver.SQL.OutboundAdapter";

Property Adapter As Oliver.SQL.OutboundAdapter;

Property batch As %Integer [ InitialExpression = 10 ];

Property insertSize As %Integer [ InitialExpression = 10 ];

Parameter SETTINGS = "batch,insertSize";

Parameter INVOCATION = "Queue";

// Set max RAM memory for this process

Method OnInit() As %Status
{
	Do ##class(Oliver.SQL.Util).DebugTEST("Oliver.SqlInsertOperation > OnInit")

	Do ##super()
	SET $ZSTORAGE=2147483647
	q $$$OK
}

Method BatchInsert(
	pRequest As Oliver.SQL.InsertRequest,
	Output pResponse As Ens.Response) As %Status
{
	Do ##class(Oliver.SQL.Util).DebugTEST("Oliver.SqlInsertOperation > BatchInsert")

	Set tStatus = $$$OK
	Try {
		//Set tSC = ..GetConnection(.tGateway)
		//Do ##class(Oliver.SQL.Util).DebugTEST("tGateway = "_tGateway)

		Set tLineCount = 0
		set tInsertCount = 0

		Set pResponse = ##class(Ens.StringResponse).%New()
		/*
		   for i=1:1:($L(context.SourceLine,"|")-1)
   {
     set tmpValue=$P(context.SourceLine,"|",i)
     set tCol = $P(context.CDWTableFields,"|",i)
     Set tColName = $P(tCol,":",1)
     Set tColType = $ZCONVERT($P(tCol,":",2),"U") 
     
     
     if (tmpValue = "")
     {
        set tInsertValues=tInsertValues_",NULL"
     } else {
        if (tColType="VARCHAR")
        {
          set tInsertValues=tInsertValues_","_"'"_$REPLACE(tmpValue,"'","''")_"'"
        }
        if (tColType="NUMERIC")
        {
          set tInsertValues=tInsertValues_","_tmpValue
        }
        if (tColType="DATE")
        {
          set tInsertValues = tInsertValues_","_"coalesce(TRY_CONVERT(datetime,'"_tmpValue_"',121),  TRY_CONVERT(datetime,'"_tmpValue_"',101), TRY_CONVERT(datetime,'"_tmpValue_"',102), TRY_CONVERT(datetime,'"_tmpValue_"',103))"
        }  
     } 
   }
	*/
		Set batchRow = 0
			kill param
			set param = ""
		Set tInsertCols = ""
		Set tSC = pRequest.Stream.Rewind()
		While ('pRequest.Stream.AtEnd) {
			Set tSourceLine = pRequest.Stream.ReadLine()
			If (tSourceLine = "") Continue
			Set ^DEBUG($I(^DEBUG)) = tSourceLine
			set batchRow = batchRow + 1
				Set tInsertCols = "SITEID"
				Set tInsertValues = "'"_pRequest.SiteID_"'"
			Set dataFields = $L(tSourceLine,"|")-1
			for i=1:1:dataFields {
				set tmpValue=$P(tSourceLine,"|",i)
				set tCol = $P(pRequest.TableFields,"|",i)
				Set tColName = $P(tCol,":",1)
				Set tColType = $ZCONVERT($P(tCol,":",2),"U") 

				Set param(batchRow,i) = tmpValue
				Set param(batchRow,i,"SqlType") = $$$SqlVarchar 

				Set tInsertCols = tInsertCols_","_tColName
				Set tInsertValues = tInsertValues_",?"

			}
			Set param(batchRow) = dataFields
			Set tSourceLine=""
			Set tLineCount = tLineCount + 1
		}

		set SqlInsertView = "Insert into "_pRequest.TableName_" ("_tInsertCols_") values ( "_tInsertValues_")"
		Set ^DEBUG($I(^DEBUG)) = SqlInsertView
		     
			set param = batchRow

	Do ##class(Oliver.SQL.Util).DebugTEST("..Adapter = "_..Adapter)
			
			set sc = ..Adapter.ExecuteUpdateBatchParamArray(.nrows,SqlInsertView,.param)
			Set tInfo = $system.Status.GetOneErrorText(sc)
			$$$LOGINFO(tInfo)
		Set ^DEBUG($I(^DEBUG)) = tInfo
			If $$$ISERR(sc) Set tStatus = sc

			k param
				
			set tInsertCount = tInsertCount + $Get(nrows,0)

	


	} Catch ex {
		Do ##class(Oliver.SQL.Util).DebugTEST("Oliver.SqlInsertOperation > BatchInsert CATCH")
		Set tStatus = ex.AsStatus()
		Do ##class(Oliver.SQL.Util).DebugStatus(tStatus)
	}
	Quit tStatus
}

Method SetResultSetView(
	pRequest As Ens.StringRequest,
	Output pResponse As Ens.StringResponse) As %Status
{
	set tStatus = $$$OK
	
	try{
					
		set nbLignes = 0
		set pResponse = ##class(Ens.StringResponse).%New()
		
		Set TimeStampStart = ##class(%Library.PosixTime).LogicalToUnixTime(##class(%Library.PosixTime).CurrentTimeStamp())

		//Pour les tests, on truncate les tables avant insertion
		$$$ThrowOnError(..Adapter.ExecuteUpdate(.nrows,"DROP TABLE IF EXISTS DemoData.ODS_Products"))

		//Creer la table pour l'exemple
		$$$ThrowOnError(..Adapter.ExecuteUpdate(.nrows,"CREATE TABLE DemoData.ODS_Products (id int8 NULL,productname varchar NULL,date_alimentation date NULL)"))		

		set SqlInsertView = "INSERT into DemoData.ODS_Products (ID,ProductName,Date_Alimentation) values (?,?,TO_DATE(?,'yyyy-mm-dd hh24:mi:ss'))"

		$$$LOGINFO(SqlInsertView)
		
		set batch = ..batch
				
		set end =""
		set i=0
		while i<..insertSize{
			
			set param = ""
			
			for k=1:1:batch {
				
				set param(k,1) = i
				set param(k,1,"SqlType")=$$$SqlInteger

				set param(k,2) = ##class(%PopulateUtils).Name()
				set param(k,2,"SqlType")=$$$SqlVarchar
			
				set param(k,3) = $ZDATETIME($NOW(),3)
				set param(k,3,"SqlType")=$$$SqlVarchar

				set param(k) = 3

				set i = i + 1
				q:(i=..insertSize)
							
				}	
		     
			set param = k
			
			set sc = ..Adapter.ExecuteUpdateBatchParamArray(.nrows,SqlInsertView,.param)

			$$$LOGINFO(sc)	

			k param
				
			set nbLignes = nbLignes + nrows
				
	}

	Set TimeStampEnd = ##class(%Library.PosixTime).LogicalToUnixTime(##class(%Library.PosixTime).CurrentTimeStamp())

	Set Delta = TimeStampEnd - TimeStampStart

	set pResponse.StringValue = nbLignes_" in "_Delta
		
	}
	catch exp
	{
		Set tStatus = exp.AsStatus()
	}

	Quit tStatus
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="Ens.StringRequest"> 
		<Method>SetResultSetView</Method>
	</MapItem>
	<MapItem MessageType="Oliver.SQL.InsertRequest"> 
		<Method>BatchInsert</Method>
	</MapItem>
</MapItems>
}

}
