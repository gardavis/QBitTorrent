<%@ Page Language="C#" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style type="text/css">
        body { font-family: arial;font-size: 12px; font-weight: bold }
        .red { color: #c00 }
        .blue { color: blue }
    </style>
</head>
<body>
<% 
	var msg = "not";
	var host = Request.Url.Host;
	var hostLow = host.ToLower();
	if (hostLow.Contains("webguild") || hostLow == "mediapc" || hostLow == "localhost" || host == "127.0.0.1")
	{
	   msg = "<p class=\"blue\">Congratulations - You have reached the MedaiPC Server via " + host + "</p>";
	}
	else
	{
	   msg = "<p class=\"red\">(MediaPC) Block: " + host + "</p>";
	}
%>
	<%= msg %><br />
	
</body>
</html>
