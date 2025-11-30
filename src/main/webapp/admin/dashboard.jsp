<%@ page import="java.sql.*" %>
<%@ include file="../db.jsp" %>
<%
    // Check if admin is logged in
    String username = (String) session.getAttribute("username");
    if(username == null || !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect("../login.jsp?error=Please login as admin");
        return;
    }

    int pendingDonors = 0;
    int pendingRecipients = 0;
    int pendingBanks = 0;

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = getConnection();

        // Pending Donors
        ps = con.prepareStatement("SELECT COUNT(*) FROM donors d JOIN users u ON d.user_id=u.user_id WHERE u.IS_APPROVED='N'");
        rs = ps.executeQuery();
        if(rs.next()) pendingDonors = rs.getInt(1);
        rs.close();
        ps.close();

        // Pending Recipients
        ps = con.prepareStatement("SELECT COUNT(*) FROM recipients r JOIN users u ON r.user_id=u.user_id WHERE u.IS_APPROVED='N'");
        rs = ps.executeQuery();
        if(rs.next()) pendingRecipients = rs.getInt(1);
        rs.close();
        ps.close();

        // Pending Banks
        ps = con.prepareStatement("SELECT COUNT(*) FROM blood_banks b JOIN users u ON b.user_id=u.user_id WHERE u.IS_APPROVED='N'");
        rs = ps.executeQuery();
        if(rs.next()) pendingBanks = rs.getInt(1);
        rs.close();
        ps.close();

    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(ps != null) ps.close(); } catch(Exception e) {}
        try { if(con != null) con.close(); } catch(Exception e) {}
    }
%>

<style>
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background:url("../images/blood1.jpeg") no-repeat center center/cover;
    margin: 0;
    background-color: #f5f5f5;
}
h1 {
    text-align: center;
    color: #d32f2f;
    margin-top: 30px;
}
.top-bar {
    display: flex;
    justify-content: flex-end;
    padding: 15px 30px;
    background: #d32f2f;
}
.top-bar a {
    color: white;
    text-decoration: none;
    font-weight: bold;
    margin-left: 15px;
}
.top-bar a:hover {
    text-decoration: underline;
}
.cards {
    display: flex;
    justify-content: space-around;
    flex-wrap: wrap;
    margin: 40px auto;
    max-width: 1000px;
    gap: 20px;
}
.card {
    background: white;
    border-radius: 10px;
    box-shadow: 0 4px 10px rgba(0,0,0,0.1);
    padding: 30px;
    flex: 1 1 250px;
    text-align: center;
}
.card h2 {
    color: #d32f2f;
    margin-bottom: 15px;
}
.card p {
    font-size: 36px;
    font-weight: bold;
    margin-bottom: 20px;
}
.card .btn {
    display: inline-block;
    padding: 10px 20px;
    background: #d32f2f;
    color: white;
    border-radius: 5px;
    text-decoration: none;
}
.card .btn:hover {
    background: #b71c1c;
}
</style>

<!-- Top bar with logout -->
<div class="top-bar">
    <span>Welcome, <%= username %></span>
    <a href="../logout.jsp">Logout</a>
</div>

<h1>Admin Dashboard</h1>

<!-- HTML for dashboard cards -->
<div class="cards">
    <div class="card">
        <h2>Pending Donor Approvals</h2>
        <p><%= pendingDonors %></p>
        <a class="btn" href="approvals.jsp?type=DONOR">Manage</a>
    </div>
    <div class="card">
        <h2>Pending Recipient Approvals</h2>
        <p><%= pendingRecipients %></p>
        <a class="btn" href="approvals.jsp?type=RECIPIENT">Manage</a>
    </div>
    <div class="card">
        <h2>Pending Blood Bank Approvals</h2>
        <p><%= pendingBanks %></p>
        <a class="btn" href="approvals.jsp?type=BANK_ADMIN">Manage</a>
    </div>
</div>
