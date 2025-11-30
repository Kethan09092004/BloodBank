<%@ page import="java.sql.*" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ include file="../db.jsp" %>
<%
    String msg = "";
    Integer userId = (Integer) session.getAttribute("user_id");
    if(userId == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    List<String[]> banks = new ArrayList<>();

    try {
        con = getConnection();

        // Get current bank id for this user
        Integer userBankId = null;
        ps = con.prepareStatement("SELECT bank_id FROM blood_banks WHERE user_id=? AND status='APPROVED'");
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if(rs.next()) {
            userBankId = rs.getInt("bank_id");
        }
        rs.close();
        ps.close();

        // Fetch all other approved banks
        String sql = "SELECT bank_id, name, city FROM blood_banks WHERE status='APPROVED'";
        if(userBankId != null) {
            sql += " AND bank_id <> ?";
            ps = con.prepareStatement(sql);
            ps.setInt(1, userBankId);
        } else {
            ps = con.prepareStatement(sql);
        }
        rs = ps.executeQuery();
        while(rs.next()) {
            banks.add(new String[]{String.valueOf(rs.getInt("bank_id")), rs.getString("name"), rs.getString("city")});
        }
        rs.close();
        ps.close();

        // Handle form submission
        if("POST".equalsIgnoreCase(request.getMethod())) {
            String targetBankStr = request.getParameter("bank_id");
            String bloodGroup = request.getParameter("blood_group");
            String unitsStr = request.getParameter("units_needed");

            if(targetBankStr == null || bloodGroup == null || unitsStr == null ||
               targetBankStr.trim().equals("") || bloodGroup.trim().equals("") || unitsStr.trim().equals("")) {
                msg = "Please fill all fields!";
            } else {
                int targetBankId = Integer.parseInt(targetBankStr);
                double units = Double.parseDouble(unitsStr);

                ps = con.prepareStatement(
                    "INSERT INTO bank_requests (request_id, requesting_bank_id, target_bank_id, blood_group, units_needed) " +
                    "VALUES (bank_requests_seq.NEXTVAL, ?, ?, ?, ?)"
                );
                ps.setInt(1, userBankId);      // bank sending request
                ps.setInt(2, targetBankId);    // bank receiving request
                ps.setString(3, bloodGroup);
                ps.setDouble(4, units);
                ps.executeUpdate();
                ps.close();

                msg = "Bank-to-bank blood request raised successfully!";
            }
        }

    } catch(Exception e) {
        msg = "Error: " + e.getMessage();
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception ex) {}
        try { if(ps != null) ps.close(); } catch(Exception ex) {}
        try { if(con != null) con.close(); } catch(Exception ex) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Raise Blood Request</title>
<link rel="stylesheet" href="../css/style.css">
<style>
/* Same styling as before */
body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4; margin:0; padding:0; background:url("../images/blood1.jpeg") no-repeat center center/cover;}
.container { max-width: 500px; margin: 50px auto; background:#fff; padding:30px; border-radius:8px; box-shadow:0 4px 6px rgba(0,0,0,0.1); }
h2 { color:#d32f2f; text-align:center; margin-bottom:25px; }
.form-group { margin-bottom:20px; }
input[type="text"], select { width:100%; padding:12px; border-radius:4px; border:1px solid #ddd; font-size:16px; box-sizing:border-box; }
.btn { display:block; width:100%; padding:12px; background-color:#d32f2f; color:#fff; border:none; border-radius:4px; cursor:pointer; font-size:16px; transition:0.25s; }
.btn:hover { background:#f8c6c6; color:#000; }

/* Back to dashboard button */
.back-btn {
    display:block;
    width:100%;
    margin-top:15px;
    padding:12px;
    background:#2196F3;
    color:#fff;
    text-align:center;
    border-radius:4px;
    text-decoration:none;
    font-size:16px;
    transition:0.25s;
}
.back-btn:hover {
    background:#f8c6c6 !important;
    color:#000 !important;
}

.error { background-color:#ffebee; color:#c62828; padding:10px; border-radius:4px; margin-bottom:15px; text-align:center; }
.success { background-color:#e8f5e9; color:#2e7d32; padding:10px; border-radius:4px; margin-bottom:15px; text-align:center; }

</style>
</head>
<body>
<div class="container">
<h2>Raise Blood Request (Bank-to-Bank)</h2>
<% if(!msg.equals("")) { %>
    <div class="<%= msg.contains("successfully") ? "success" : "error" %>"><%= msg %></div>
<% } %>
<form method="post">
    <div class="form-group">
        <label for="bank_id">Select Target Blood Bank</label>
        <select name="bank_id" id="bank_id" required>
            <option value="">-- Select Blood Bank --</option>
            <% for(String[] bank : banks) { %>
                <option value="<%= bank[0] %>"><%= bank[1] %> (<%= bank[2] %>)</option>
            <% } %>
        </select>
    </div>
    <div class="form-group">
        <label for="blood_group">Blood Group</label>
        <select name="blood_group" id="blood_group" required>
            <option value="">-- Select Blood Group --</option>
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
        <label for="units_needed">Units Needed</label>
        <input type="text" name="units_needed" id="units_needed" placeholder="Enter number of units" required>
    </div>
    <button type="submit" class="btn">Submit Request</button>
</form>
<a href="bank_dashboard.jsp" class="back-btn">Back to Dashboard</a>

</div>
</body>
</html>
