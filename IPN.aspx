<%@ Page Language="C#" %>
<%@ Import Namespace="System.Net" %>

<script runat="server">
    // Author:      Gary Davis, gary@webguild.com
    // Date:        May 25, 2008
    // Description: Webpage to process IPN (Instant Payment Notification) messages from PayPal. Mainly to
    //              know when a payment has been completed by the consumer.
    // Copyright 2008, All rights reserved

    /// <summary>
    /// IPN - Instant Payment Notification - Called like a web service from PayPal when someone 
    /// completes a payment (as well as other notifications).
    /// 
    ///PayPal's Instant Payment Notification (IPN) allows you to program your back-end operations to automate 
    ///transactions when you receive payments from your customers.
    ///
    ///Background
    ///
    ///Whenever purchases are made through PayPal by a customer, PayPal uses IPN to post the transaction 
    ///information to a resource that you specify (in notify_url).
    ///
    ///Once your resource receives the post, you must complete 4 steps:
    ///
    ///Notification Validation 
    ///In this step, your job is to post the data that was posted to you back to PayPal. This ensures that the 
    ///original post indeed came from PayPal, and is not sort of fraud. In the data that you post back, you must 
    ///append the "cmd=_notify-validate" value to the POST string. Once the data is posted back to PayPal, 
    ///PayPal will respond with a string of either "VERIFIED" or "INVALID". "VERIFIED" means that PayPal sent 
    ///the original post, and that you should continue your automation process as part of the transaction. 
    ///"INVALID" means that PayPal did not send the original post, and it should probably belogged and investigated 
    ///for possible fraud. 
    ///
    ///Payment Status Check 
    ///In this step, you should check that the "payment_status" form field is "Completed". This ensures that the 
    ///customer's payment has been processed by PayPal, and it has been added to the seller's account. 
    ///
    ///Transaction Duplication Check 
    ///In this step, you should check that the "txn_id" form field, transaction ID, has not already been processed 
    ///by your automation system. A good thing to do is to store the transaction ID in a database or file for 
    ///duplication checking. If the transaction ID posted by PayPal is a duplicate, you should not continue your 
    ///automation process for this transaction. Otherwise, this could result in sending the same product to a 
    ///customer twice. 
    ///
    ///Seller Email Validation 
    ///In this step, you simply make sure that the transaction is for your account. Your account will have specific 
    ///email addresses assigned to it. You should verify that the "receiver_email" field has a value that 
    ///corresponds to an email associated with your account. 
    ///
    ///Payment Validation 
    ///As of now, this step is not listed on other sites as a requirement, but it is very important. Because any 
    ///customer who is familiar with query strings can modify the cost of a seller's product, you should verify 
    ///that the "payment_gross" field corresponds with the actual price of the item that the customer is purchasing. 
    ///It is up to you to determine the exact price of the item the customer is purchasing using the form fields. 
    ///Some common fields you may use to lookup the item being purchased include "item_name" and "item_number". 
    ///
    ///SAMPLE FORM FIELDS:
    /// address_city=Deerfield+Beach&			notify_version=2.4&
    /// address_country=United+States&			payer_email=garyd@webguild.com&
    /// address_country_code=US&			    payer_id=VJATQKEVHPCZW&
    /// address_name=Gary+Davis&			    payer_status=verified&
    /// address_state=FL&				        payment_date=17%3A35%3A31+Aug+19%2C+2011+PDT&
    /// address_status=confirmed&			    payment_fee=0.10&
    /// address_street=513+NW+46th+Av&			payment_gross=0.10&
    /// address_zip=33442&				        payment_status=Completed&
    /// business=premseller@mystore.com&		payment_type=instant&
    /// charset=windows-1252&				    quantity=1&
    /// custom=CertsAndKeys.2008-08-0534.zip&	receiver_email=premseller@mystore.com&
    /// first_name=Gary&				        receiver_id=WCDLHJUGR6SCU&
    /// item_name=Personal+public+cer...&		residence_country=US&
    /// item_number=CertKey&				    shipping=0.00
    /// last_name=Davis&				        tax=0.00&
    /// mc_currency=USD&				        txn_id=7P6373107L5836042&
    /// mc_fee=0.10&					        txn_type=web_accept&
    /// mc_gross=0.10&					        verify_sign=AQU0e5vuZCvSg-XJploS...&
    /// </summary>

    // PayPal account primary email(s) - use all lowercase (TODO: Fix these emails):
    readonly string[] primaryBusiness = {"paypal@webguild.com",  // Match Receiver w/ Primary account emails
             "gardeb@webguild.com"};
    const string PayPalProd = "https://www.paypal.com/cgi-bin/webscr";
    const string PayPalTest = "https://www.sandbox.paypal.com/cgi-bin/webscr";

    string content;             // Form parameters
    readonly string payer_email= Req("payer_email");			// Payee (consumer)
    readonly string receiver_email = Req("receiver_email");	    // Email (Primary email in PayPal account)
    readonly string payment_status = Req("payment_status");	    // "Pending", "Completed", "Refunded", "Canceled_Reversal"
    readonly string payment_type = Req("payment_type");    	    // "instant", "echeck"
    readonly string pending_reason = Req("pending_reason");     // "echeck", "authorization"
    readonly bool testMode = Req("test_ipn") == "1";            // testMode = true for PayPal sandbox transaction

    protected void Page_Load()
    {
        content = Encoding.ASCII.GetString(Request.BinaryRead(Request.ContentLength));
        
        Log(content);   // TODO: Log the input content variable

        // Get FORM POST string. This supports accented characters via the BinaryRead
        var formPostData = "cmd=_notify-validate&" + content;
        var response = "";
        var msg = "";
        var payPalWebScr = (testMode) ? PayPalTest : PayPalProd;

        // POST the data back to PayPal for validation - should get "VERIFIED" back

        var client = new WebClient();
        client.Headers.Add("Content-Type", "application/x-www-form-urlencoded");
        var postByteArray = Encoding.ASCII.GetBytes(formPostData);

        try
        {
            var responseArray = client.UploadData(payPalWebScr, "POST", postByteArray);
            response = Encoding.ASCII.GetString(responseArray);
        }
        catch (Exception ex)            // For example if PayPal or our network is down 
        {
            response = "TRAPPED: CallBack - " + ex.Message; // Simulate failure
        }

        if (response == "VERIFIED") // Process the response from PayPal.
        {
            try
            {
                msg = ProcessVerified();
            }
            catch (Exception ex)
            {
                msg = "TRAPPED: ProcessVerified - " + ex.Message + " - " + msg; // Bug in ProcessVerified()?
            }
        }
        else    // "INVALID" 
        {
            // Possible fraud. Log for investigation. For further assistance, go to 
            // http://www.paypal.com/wf/ and click Seller Tools then Instant Payment Notification (IPN).
            // Response.StatusCode = 500;	// I want PayPal to get an error to force resend of IPN (optional)
            msg = "REJECTED: Unexpected CallBack response (" + response + ")";
        }

        //TODO: Write "msg" to some log file/Database for each incoming IPN

        if (!msg.StartsWith("SUCCESS"))                     // Send an Error email if error
        {
            Log(msg);  // TODO: Send Email and/or log the msg variable
        }
        
        Response.Write("Msg: " + msg);  // NOTE: This is not normally seen since response goes back to PayPal
    }

    /// <summary>
    /// Verify that the IPN is notification of completed payment and initiate fulfillment if so.
    /// </summary>
    /// <returns>Result message to email/display. Will start with SUCCESS, NOTE, FAILURE or REJECTED. 
    /// The 1st two should not send Emails.</returns>
    private string ProcessVerified()
    {
        if (!testMode && Array.IndexOf(primaryBusiness, receiver_email.ToLower()) == -1)    // Ignore this error if sandbox
        {
            return (string.Format("REJECTED due to receiver_email ({0}) mismatch with account email(s) ({1})",
                receiver_email, String.Join(", ", primaryBusiness)));
        }

        if ((payment_status == "Pending") && (pending_reason == "echeck"))
        {
            return ("NOTE: Payment pending (echeck)");			// Ignore pending eCheck IPNs
        }

        if (payment_status == "Failed" && payment_type == "echeck")
        {
            return ("FAILURE: eCheck Payment failed to clear");
        }

        if (payment_status != "Completed")
        {
            return ("REJECTED: Invalid payment_status (" + payment_status + ")");
        }

        // TODO: Initiate order fullfilment since we have now been paid

        return (string.Format("SUCCESS: Payment accepted for {0}", payer_email));
    }

    /// <summary>
    /// Get value of requested form field. If null, return "".
    /// </summary>
    /// <param name="fieldName">Form field's name</param>
    /// <returns>Value or "". Never return null</returns>
    private static string Req(string fieldName)
    {
        return (HttpContext.Current.Request.Form[fieldName] ?? "");
    }
    
    /// <summary>
    /// Barebones logging to ~/App_Data/PayPalLog.txt
    /// </summary>
    /// <param name="msg">Message to log</param>
    private static void Log(string msg)
    {
        var path = HttpContext.Current.Server.MapPath("/App_Data/PayPalLog.txt"); // E:\Inetpub\WwwRoot\Default\App_Data\PayPalLog.txt
        path = @"E:\Logs\PayPalIpnLog.txt";
        System.IO.File.AppendAllText(path, string.Format("{0} - {1}\n", DateTime.Now, msg));
    }
</script>
