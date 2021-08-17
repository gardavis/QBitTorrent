<%@ WebHandler Class="CruiseTicker" Language="C#" %>

using System;
using System.Net;
using System.Text.RegularExpressions;
using System.Web;

class CruiseTicker : IHttpHandler 
{
    /// <summary>
    /// Read file and then return it in response.
    /// See: http://www.intstrings.com/ramivemula/asp-net/how-to-download-files-from-server-to-client-using-a-generic-handler/
    /// </summary>
    /// <param name="context">HttpContext for handlers</param>
    public void ProcessRequest(HttpContext context) 
    {
		var response = context.Response;

		try
		{

		    var url = "http://www.cruise-ships.com/ticker-created/";
		    var postData = "month=9&day=22&year=2018&ship=866&sid=866";

		    using (var webClient = new WebClient())
		    {
		        webClient.Headers.Add("Content-Type", "application/x-www-form-urlencoded");
		        var webPage = webClient.UploadString(url, postData);

		        // http://ticker.cruise-ships.com/002/fc67fe46ba48d774275d815dbc135bd9.png

		        var m = Regex.Match(webPage, @">(?<imageUrl>http://ticker\.cruise-ships.com/.*\.png)");
		        if (m.Success)
		        {
		            var imageUrl = m.Groups["imageUrl"].Value;
		            var data = webClient.DownloadData(imageUrl);

		            response.Clear();
		            response.AddHeader("Content-Length", data.Length.ToString());
		            response.ContentType = "image/png";
		            response.BinaryWrite(data);
		            response.Flush();
		        }
		    }
		}
        catch (Exception ex) 
        {
			response.Write("Download NOT Successful: " + ex.Message);
		}
	}

    public bool IsReusable 
    {
        get {return false;}
    }
}