<%@ Page Language="C#" %>

<% 
// http://server.webguild.com/rpc/ping.action?salt=75486140&machineId=76f3b9c6-77d3-4b82-8498-dc224b832165&hostName=Webguild.&clientVersion=4&userName=gary&buildNumber=2016.3.1%20.107.0.20161222.212756

var url = "http://localhost:9123";
url = "http://jetbrains.tencent.click";
var webClient = new System.Net.WebClient();
var rtn = webClient.DownloadString(url + "/rpc/ping.action?" + Request.QueryString);

Response.ClearHeaders();
Response.ContentType = "text/xml;application/xml;charset=utf-8";
Response.AddHeader("X-Powered-By", "JetBrainsLicenseServer");
Response.AddHeader("server", "JetBrains");
Response.Write(rtn);
%>
