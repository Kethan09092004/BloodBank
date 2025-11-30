<%@ page import="java.sql.*" %>
<%@ page import="java.time.*" %>
<%@ include file="../db.jsp" %>

<%
Integer bankId = (Integer) session.getAttribute("bank_id");
if(bankId == null){
    response.sendRedirect("bank_dashboard.jsp");
    return;
}

Connection con = null;
PreparedStatement ps = null;
ResultSet rsRecipients = null;
ResultSet rsBank = null;

String action = request.getParameter("action");
String reqIdStr = request.getParameter("req_id");
String type = request.getParameter("type"); // "recipient" or "bank"
String message = "";

try{
    con = getConnection();

    // HANDLE ACTIONS
    if(action != null && reqIdStr != null && type != null){
        int reqId = Integer.parseInt(reqIdStr);

        if("recipient".equals(type) || "bank".equals(type)){
            String tableName = "recipient".equals(type) ? "requests" : "bank_requests";
            String bankField = "recipient".equals(type) ? "bank_id" : "target_bank_id";

            if("approve".equals(action)){
                ps = con.prepareStatement("UPDATE " + tableName + " SET status='APPROVED' WHERE request_id=? AND " + bankField + "=?");
                ps.setInt(1, reqId);
                ps.setInt(2, bankId);
                ps.executeUpdate();
                ps.close();
                message = "Request approved successfully!";
            } else if("reject".equals(action)){
                ps = con.prepareStatement("UPDATE " + tableName + " SET status='REJECTED' WHERE request_id=? AND " + bankField + "=?");
                ps.setInt(1, reqId);
                ps.setInt(2, bankId);
                ps.executeUpdate();
                ps.close();
                message = "Request rejected successfully!";
            } else if("complete".equals(action)){
                // Fetch request details
                ps = con.prepareStatement("SELECT blood_group, units_needed FROM " + tableName + " WHERE request_id=? AND " + bankField + "=?");
                ps.setInt(1, reqId);
                ps.setInt(2, bankId);
                ResultSet rsRequest = ps.executeQuery();
                String bg = ""; int units = 0;
                if(rsRequest.next()){
                    bg = rsRequest.getString("blood_group");
                    units = rsRequest.getInt("units_needed");
                }
                rsRequest.close(); ps.close();

                // Check current stock
                ps = con.prepareStatement("SELECT units_available FROM blood_stock WHERE bank_id=? AND blood_group=?");
                ps.setInt(1, bankId);
                ps.setString(2, bg);
                ResultSet rsStock = ps.executeQuery();
                int currentStock = 0;
                if(rsStock.next()){
                    currentStock = rsStock.getInt("units_available");
                }
                rsStock.close(); ps.close();

                if(currentStock >= units){
                    // Deduct stock
                    ps = con.prepareStatement("UPDATE blood_stock SET units_available = units_available - ? WHERE bank_id=? AND blood_group=?");
                    ps.setInt(1, units);
                    ps.setInt(2, bankId);
                    ps.setString(3, bg);
                    ps.executeUpdate();
                    ps.close();

                    // Mark request fulfilled
                    ps = con.prepareStatement("UPDATE " + tableName + " SET status='FULFILLED', request_date=SYSTIMESTAMP WHERE request_id=? AND " + bankField + "=?");
                    ps.setInt(1, reqId);
                    ps.setInt(2, bankId);
                    ps.executeUpdate();
                    ps.close();

                    message = "Request fulfilled successfully!";
                } else {
                    message = "Cannot fulfill request! Only " + currentStock + " unit(s) available for blood group " + bg + ".";
                }
            }
        }
    }

    // FETCH RECIPIENT REQUESTS
    ps = con.prepareStatement(
        "SELECT r.request_id, u.email, r.blood_group, r.units_needed, r.status " +
        "FROM requests r " +
        "JOIN recipients rec ON r.recipient_id = rec.recipient_id " +
        "JOIN users u ON rec.user_id = u.user_id " +
        "WHERE r.bank_id=? ORDER BY r.request_id DESC"
    );
    ps.setInt(1, bankId);
    rsRecipients = ps.executeQuery();

    // FETCH BANK REQUESTS
    ps = con.prepareStatement(
        "SELECT br.request_id, bb1.name AS requesting_bank, br.blood_group, br.units_needed, br.status " +
        "FROM bank_requests br " +
        "JOIN blood_banks bb1 ON br.requesting_bank_id = bb1.bank_id " +
        "WHERE br.target_bank_id=? ORDER BY br.request_id DESC"
    );
    ps.setInt(1, bankId);
    rsBank = ps.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
    <title>Manage Requests</title>
    <link rel="stylesheet" href="../css/style.css">
    <style>
    body{font-family:'Segoe UI',sans-serif; background:#f4f4f9;background:url("../images/blood1.jpeg") no-repeat center center/cover;}
    .container{max-width:1000px; margin:30px auto; background:#fff; padding:20px 30px; border-radius:10px; box-shadow:0 6px 18px rgba(0,0,0,0.1);}
    h2{text-align:center;color:#d32f2f; margin-bottom:20px;}
    table{width:100%; border-collapse:collapse; margin-top:20px;}
    th,td{padding:12px 10px;border:1px solid #ccc; text-align:center;}
    th{background:#d32f2f;color:#fff;}
    tr:nth-child(even){background:#f9f9f9;}

    /* --- BUTTON STYLES --- */
    a.btn{
        padding:7px 14px;
        border-radius:6px;
        color:#fff;
        text-decoration:none;
        margin:2px;
        display:inline-block;
        transition:0.25s;
    }

    /* COMMON HOVER COLOR — soft pink */
    a.btn:hover{
        background:#f8c6c6 !important;
        color:#000 !important; /* improves visibility */
    }

    /* Specific colors for each action */
    a.approve{background:#2196F3;}
    a.reject{background:#f44336;}
    a.complete{background:#4CAF50;}
    a.disabled{background:#aaa; cursor:not-allowed;}

    .back-btn{
        display:inline-block; 
        margin-top:20px; 
        padding:8px 15px; 
        background:#d32f2f; 
        color:#fff; 
        border-radius:6px; 
        text-decoration:none;
        transition:0.25s;
    }

    /* Back button hover */
    .back-btn:hover{
        background:#f8c6c6 !important;
        color:#000 !important;
    }

    .message {text-align:center; color:green; font-weight:bold;}
    .warning {color:red; font-weight:bold;}
</style>

</head>
<body>
<div class="container">

<% if(!message.equals("")){ %>
    <p class="message"><%= message %></p>
<% } %>

<!-- Recipient Requests -->
<h2>Recipient Requests</h2>
<table>
<tr>
<th>Request ID</th>
<th>User Email</th>
<th>Blood Group</th>
<th>Units Needed</th>
<th>Status</th>
<th>Action</th>
</tr>
<%
while(rsRecipients.next()){
    String status = rsRecipients.getString("status");
    int unitsNeeded = rsRecipients.getInt("units_needed");
    String bloodGroup = rsRecipients.getString("blood_group");

    // Check stock
    ps = con.prepareStatement("SELECT units_available FROM blood_stock WHERE bank_id=? AND blood_group=?");
    ps.setInt(1, bankId);
    ps.setString(2, bloodGroup);
    ResultSet rsStock = ps.executeQuery();
    int stockAvailable = 0;
    if(rsStock.next()){
        stockAvailable = rsStock.getInt("units_available");
    }
    rsStock.close(); ps.close();
%>
<tr>
<td><%= rsRecipients.getInt("request_id") %></td>
<td><%= rsRecipients.getString("email") %></td>
<td><%= bloodGroup %></td>
<td><%= unitsNeeded %></td>
<td><%= status %></td>
<td>
<%
if("PENDING".equals(status)){
%>
<a class="btn approve" href="manage_requests.jsp?type=recipient&action=approve&req_id=<%= rsRecipients.getInt("request_id") %>">Approve</a>
<a class="btn reject" href="manage_requests.jsp?type=recipient&action=reject&req_id=<%= rsRecipients.getInt("request_id") %>">Reject</a>
<%
} else if("APPROVED".equals(status)){
    if(stockAvailable >= unitsNeeded){
%>
<a class="btn complete" href="manage_requests.jsp?type=recipient&action=complete&req_id=<%= rsRecipients.getInt("request_id") %>">Mark Fulfilled</a>
<%
    } else {
%>
<span class="btn disabled">Insufficient Stock (<%= stockAvailable %>)</span>
<%
    }
} else { %>---<% } %>
</td>
</tr>
<% } %>
</table>

<!-- Bank-to-Bank Requests -->
<h2>Bank-to-Bank Requests</h2>
<table>
<tr>
<th>Request ID</th>
<th>Requesting Bank</th>
<th>Blood Group</th>
<th>Units Needed</th>
<th>Status</th>
<th>Action</th>
</tr>
<%
while(rsBank.next()){
    String status = rsBank.getString("status");
    int unitsNeeded = rsBank.getInt("units_needed");
    String bloodGroup = rsBank.getString("blood_group");

    // Check stock
    ps = con.prepareStatement("SELECT units_available FROM blood_stock WHERE bank_id=? AND blood_group=?");
    ps.setInt(1, bankId);
    ps.setString(2, bloodGroup);
    ResultSet rsStock = ps.executeQuery();
    int stockAvailable = 0;
    if(rsStock.next()){
        stockAvailable = rsStock.getInt("units_available");
    }
    rsStock.close(); ps.close();
%>
<tr>
<td><%= rsBank.getInt("request_id") %></td>
<td><%= rsBank.getString("requesting_bank") %></td>
<td><%= bloodGroup %></td>
<td><%= unitsNeeded %></td>
<td><%= status %></td>
<td>
<%
if("PENDING".equals(status)){
%>
<a class="btn approve" href="manage_requests.jsp?type=bank&action=approve&req_id=<%= rsBank.getInt("request_id") %>">Approve</a>
<a class="btn reject" href="manage_requests.jsp?type=bank&action=reject&req_id=<%= rsBank.getInt("request_id") %>">Reject</a>
<%
} else if("APPROVED".equals(status)){
    if(stockAvailable >= unitsNeeded){
%>
<a class="btn complete" href="manage_requests.jsp?type=bank&action=complete&req_id=<%= rsBank.getInt("request_id") %>">Mark Fulfilled</a>
<%
    } else {
%>
<span class="btn disabled">Insufficient Stock (<%= stockAvailable %>)</span>
<%
    }
} else { %>---<% } %>
</td>
</tr>
<% } %>
</table>

<a class="back-btn" href="bank_dashboard.jsp">Back to Dashboard</a>
</div>
</body>
</html>

<%
} catch(Exception e){
    out.println("<p class='warning'>Error: "+e.getMessage()+"</p>");
} finally{
    try{ if(rsRecipients!=null) rsRecipients.close(); }catch(Exception e){}
    try{ if(rsBank!=null) rsBank.close(); }catch(Exception e){}
    try{ if(ps!=null) ps.close(); }catch(Exception e){}
    try{ if(con!=null) con.close(); }catch(Exception e){}
}
%>
