<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ include file="../db.jsp" %>
<%
Integer userId = (Integer) session.getAttribute("user_id");
if(userId == null){ response.sendRedirect("../login.jsp"); return; }

String msg = "";
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

String selectedBlood = request.getParameter("blood_group");
String unitsStr = request.getParameter("units_needed");
double unitsNeeded = 0;
if(unitsStr != null && !unitsStr.trim().isEmpty()) {
    try { unitsNeeded = Double.parseDouble(unitsStr); } catch(Exception e) { unitsNeeded=0; }
}

List<String[]> availableBanks = new ArrayList<>();
try {
    if(selectedBlood != null && unitsNeeded > 0){
        con = getConnection();
        String sql = "SELECT b.bank_id, b.name, b.city, s.units_available " +
                     "FROM blood_banks b LEFT JOIN blood_stock s ON b.bank_id = s.bank_id AND s.blood_group=? " +
                     "WHERE b.status='APPROVED'";
        ps = con.prepareStatement(sql);
        ps.setString(1, selectedBlood);
        rs = ps.executeQuery();
        while(rs.next()){
            double avail = rs.getDouble("units_available");
            availableBanks.add(new String[]{String.valueOf(rs.getInt("bank_id")), rs.getString("name"), rs.getString("city"), String.valueOf(avail)});
        }
        rs.close(); ps.close();
    }
} catch(Exception e){ msg = "Error fetching banks: "+e.getMessage(); }

if("POST".equalsIgnoreCase(request.getMethod())){
    String bankIdStr = request.getParameter("bank_id");
    selectedBlood = request.getParameter("blood_group");
    unitsStr = request.getParameter("units_needed");

    if(bankIdStr==null || selectedBlood==null || unitsStr==null || bankIdStr.isEmpty() || selectedBlood.isEmpty() || unitsStr.isEmpty()){
        msg="Please fill all fields!";
    } else {
        try{
            int bankId = Integer.parseInt(bankIdStr);
            double units = Double.parseDouble(unitsStr);
            con = getConnection();
            ps = con.prepareStatement(
                "INSERT INTO requests (request_id, recipient_id, bank_id, blood_group, units_needed, status, request_date) " +
                "VALUES (REQUESTS_SEQ.NEXTVAL, (SELECT recipient_id FROM recipients WHERE user_id=?), ?, ?, ?, 'PENDING', SYSTIMESTAMP)"
            );
            ps.setInt(1, userId);
            ps.setInt(2, bankId);
            ps.setString(3, selectedBlood);
            ps.setDouble(4, units);
            ps.executeUpdate();
            ps.close();
            msg = "Request submitted successfully!";
        }catch(Exception e){ msg = "Error raising request: "+e.getMessage(); }
    }
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Request Blood</title>
<link rel="stylesheet" href="../css/style.css">
<style>
body { font-family:'Segoe UI', sans-serif; background:#f4f4f4; margin:0; padding:0; background:url("../images/blood1.jpeg") no-repeat center center/cover;}
.container { max-width:600px; margin:50px auto; background:#fff; padding:30px; border-radius:8px; box-shadow:0 4px 6px rgba(0,0,0,0.1);}
h2 { color:#d32f2f; text-align:center; margin-bottom:25px; }
form .form-group { margin-bottom:20px; }
form label { display:block; margin-bottom:5px; font-weight:bold; }
input[type=text], select { width:100%; padding:10px; border-radius:4px; border:1px solid #ddd; box-sizing:border-box; font-size:16px; }
button { width:100%; padding:12px; background:#d32f2f; border:none; border-radius:4px; color:#fff; font-size:16px; cursor:pointer; }
button:hover { background:#b71c1c; }
.success { background:#e8f5e9; color:#2e7d32; padding:10px; margin-bottom:15px; border-radius:4px; text-align:center; }
.error { background:#ffebee; color:#c62828; padding:10px; margin-bottom:15px; border-radius:4px; text-align:center; }
</style>
</head>
<body>
<div class="container">
<h2>Request Blood</h2>
<a href="recipient_dashboard.jsp">Back to Dashboard</a>
<% if(!msg.isEmpty()){ %>
<p class="<%= msg.contains("successfully") ? "success" : "error" %>"><%=msg %></p>
<% } %>

<form method="post">
<div class="form-group">
<label>Blood Group:</label>
<select name="blood_group" required>
<option value="">--Select--</option>
<option value="A+">A+</option>
<option value="A-">A-</option>
<option value="B+">B+</option>
<option value="B-">B-</option>
<option value="AB+">AB+</option>
<option value="AB-">AB-</option>
<option value="O+">O+</option>
<option value="O-">O-</option>
</select>
</div>

<div class="form-group">
<label>Units Needed:</label>
<input type="text" name="units_needed" placeholder="Enter number of units" required>
</div>

<% if(!availableBanks.isEmpty()){ %>
<div class="form-group">
<label>Select Blood Bank:</label>
<select name="bank_id" required>
<option value="">--Select Bank--</option>
<%
for(String[] b : availableBanks){
%>
<option value="<%=b[0]%>"><%=b[1]%> (<%=b[2]%>) - Available: <%=b[3]%> units</option>
<%
}
%>
</select>
</div>
<% } %>

<button type="submit">Submit Request</button>
</form>
</div>
</body>
</html>
