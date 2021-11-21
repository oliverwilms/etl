Class Oliver.SQL.InsertRequest Extends (Ens.StreamContainer, Ens.Request)
{

/// context.SiteID
Property SiteID As %String;

/// context.CDWTableFields
Property TableFields As %String(MAXLEN = 100000000);

/// context.CDWTableName
Property TableName As %String(MAXLEN = 100000000);

/// Request type
Property SQLQueryType As %String;

Storage Default
{
<Data name="InsertRequestDefaultData">
<Subscript>"InsertRequest"</Subscript>
<Value name="1">
<Value>SiteID</Value>
</Value>
<Value name="2">
<Value>TableFields</Value>
</Value>
<Value name="3">
<Value>TableName</Value>
</Value>
<Value name="4">
<Value>SQLQueryType</Value>
</Value>
</Data>
<DefaultData>InsertRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}
