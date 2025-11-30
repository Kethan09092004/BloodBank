<%@ page import="java.sql.*" %>
<%@ include file="../db.jsp" %>

<%
    // ---------------- SESSION VALIDATION ----------------
    if (session.getAttribute("user_id") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    int uid = (int) session.getAttribute("user_id");
    String bankName = "";
    int bankId = 0;

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = getConnection();
        ps = con.prepareStatement("SELECT bank_id, name FROM blood_banks WHERE user_id=?");
        ps.setInt(1, uid);
        rs = ps.executeQuery();

        if (rs.next()) {
            bankId = rs.getInt("bank_id");
            bankName = rs.getString("name");

            // ⭐ Save bank_id for all other pages to use
            session.setAttribute("bank_id", bankId);
            session.setAttribute("bank_name", bankName);
        } else {
            out.println("<script>alert('Bank not found for this account'); window.location='../login.jsp';</script>");
            return;
        }
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
        return;
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (ps != null) ps.close(); } catch (Exception e) {}
        try { if (con != null) con.close(); } catch (Exception e) {}
    }
%>

<!DOCTYPE html>
<html>
<head>
<title>Bank Dashboard</title>
<link rel="stylesheet" href="../css/style.css">

<style>
body {
    font-family:'Segoe UI',sans-serif; background:#f4f4f9; margin:0; padding:0;background:url("../images/blood1.jpeg") no-repeat center center/cover;
}
header {
    background:#d32f2f; color:white; padding:15px 30px;
    display:flex; justify-content:space-between; align-items:center;
}
header a {
    color:white; text-decoration:none; font-weight:bold;
}
.container {
    max-width:1000px; margin:30px auto;
}
h2 {
    color:#d32f2f; margin-bottom:20px; text-align:center;
}
.cards {
    display:grid; grid-template-columns:repeat(auto-fit,minmax(250px,1fr));
    gap:20px;
}
.card {
    background:white; padding:20px; border-radius:8px;
    box-shadow:0 4px 8px rgba(0,0,0,0.1);
    transition:0.2s ease;
}
.card:hover {
    transform:translateY(-4px);
    box-shadow:0 6px 14px rgba(0,0,0,0.15);
}
.card h3 {
    margin-top:0; color:#d32f2f;
}
.btn {
    background:#d32f2f; color:white; padding:8px 12px;
    border:none; border-radius:4px; cursor:pointer;
    text-decoration:none;
}
.btn:hover {
    background-color: #ff9e9e;   /* Light red for contrast */
    color: #b30000;              /* Dark red text */
}
header a:hover {
    color: #ffcccc;              /* Light pink hover text */
}
select:hover, input[type="date"]:hover {
    border-color: #ff9e9e;
}
</style>
</head>

<body>
<header>
    <div>Welcome, <%= bankName %></div>
    <div><a href="../logout.jsp">Logout</a></div>
</header>

<div class="container">
<h2>Blood Bank Dashboard</h2>

<div class="cards">

    <div class="card">
        <h3>Manage Stock</h3>
        <p>Add new units or update existing stock.</p>
        <a class="btn" href="manage_stock.jsp">Go</a>
    </div>

    <div class="card">
        <h3>Manage Requests</h3>
        <p>Approve, reject or complete recipient blood requests.</p>
        <!-- ⭐ Updated to new file -->
        <a class="btn" href="manage_requests.jsp">Go</a>
    </div>

    <div class="card">
        <h3>Raise Request</h3>
        <p>Request blood from other banks if needed.</p>
        <a class="btn" href="raise_request.jsp">Go</a>
    </div>

</div>
</div>

</body>
</html>
