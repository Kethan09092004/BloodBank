<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ include file="../db.jsp" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if(userId == null){
        response.sendRedirect("../login.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Recipient Dashboard</title>
<link rel="stylesheet" href="../css/style.css">
<style>
body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; margin:0; padding:0; background:url("../images/blood1.jpeg") no-repeat center center/cover;}
.container { max-width:1000px; margin:30px auto; background:#fff; padding:25px 30px; border-radius:8px; box-shadow:0 4px 8px rgba(0,0,0,0.1); }
h2 { text-align:center; color:#d32f2f; }
.top-links { margin-bottom: 20px; text-align: center; }
.top-links a { margin:0 10px; text-decoration:none; color:#d32f2f; font-weight:bold; }
.top-links a:hover { text-decoration:underline; }
table { width:100%; border-collapse: collapse; margin-top:15px; }
th, td { padding:12px; border:1px solid #ddd; text-align:left; }
th { background: #d32f2f; color:#fff; }
tr:nth-child(even) { background:#f9f9f9; }
.status { padding:5px 10px; border-radius:4px; color:#fff; font-weight:bold; text-align:center; }
.status.PENDING { background:#f57c00; }
.status.APPROVED { background:#388e3c; }
.status.FULFILLED { background:#1976d2; }
.status.REJECTED { background:#c62828; }
</style>
</head>
<body>
<div class="container">
<h2>Recipient Dashboard</h2>
<div class="top-links">
    <a href="request_blood.jsp">Request Blood</a>
    <a href="../logout.jsp">Logout</a>
</div>

<h3>Your Blood Requests</h3>
<table>
<tr>
<th>Request ID</th>
<th>Blood Bank</th>
<th>Blood Group</th>
<th>Units Needed</th>
<th>Status</th>
<th>Request Date</th>
</tr>

<%
try{
    con = getConnection();
    String sql = "SELECT r.request_id, b.name AS bank_name, r.blood_group, r.units_needed, r.status, r.request_date " +
                 "FROM requests r JOIN blood_banks b ON r.bank_id = b.bank_id " +
                 "JOIN recipients rec ON r.recipient_id = rec.recipient_id " +
                 "WHERE rec.user_id = ? ORDER BY r.request_date DESC";
    ps = con.prepareStatement(sql);
    ps.setInt(1, userId);
    rs = ps.executeQuery();
    while(rs.next()){
%>
<tr>
<td><%= rs.getInt("request_id") %></td>
<td><%= rs.getString("bank_name") %></td>
<td><%= rs.getString("blood_group") %></td>
<td><%= rs.getDouble("units_needed") %></td>
<td class="status <%=rs.getString("status")%>"><%= rs.getString("status") %></td>
<td><%= rs.getTimestamp("request_date") %></td>
</tr>
<%
    }
}catch(Exception e){ out.println("<tr><td colspan='6'>Error: "+e.getMessage()+"</td></tr>"); }
finally{ try{ if(rs!=null) rs.close(); }catch(Exception e){} try{ if(ps!=null) ps.close(); }catch(Exception e){} try{ if(con!=null) con.close(); }catch(Exception e){} }
%>
</table>
</div>
</body>
</html>
