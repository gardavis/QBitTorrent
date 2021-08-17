<%@ Page Language="C#" %>
<%@ Import Namespace="System.Net.Mail" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        var m = SendEmail("TestEmail", "This is the body", "gary@webguild.com", "garyd@webguild.com");
        Response.Write("Returned: <pre>" + m + "</pre>");
    }

    public static string SendEmail(string subject, string body, string to, string from)
    {
        string rtn = null;

        try
        {
            using (var message = new MailMessage(from, to))
            {
                message.IsBodyHtml = true;
                message.Body = body;
                message.Subject = subject;

                var mail = new SmtpClient();
                rtn = "Success - SMTP Host:port - " + mail.Host + ":" + mail.Port;
                mail.Send(message);
            }
        }
        catch (Exception ex)
        {
            rtn = ex.ToString();
        }

        return (rtn);
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
    </div>
    </form>
</body>
</html>
