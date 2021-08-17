<script runat="server">
    protected void Application_BeginRequest(object sender, EventArgs e)
    {
        if (!Response.HeadersWritten)
        {
            Response.AddOnSendingHeaders((c) =>
            {
                if (c != null && c.Response != null && c.Response.Headers != null)
                {
                    if (c.Response.Headers["Server"] != null && c.Response.Headers["Server"].Contains("JetBrains"))
                    {
                        c.Response.Headers.Remove("Server");
                        c.Response.AddHeader("server", "JetBrains");
                    }
                }
            });
        }

    }
</script>