<%@ page import="java.sql.*" %>
<%@ include file="../db.jsp" %>

<%
    String username = (String) session.getAttribute("username");
    if(username == null || !"ADMIN".equals(session.getAttribute("role"))) {
        response.sendRedirect("../login.jsp?error=Please login as admin");
        return;
    }

    String type = request.getParameter("type"); // DONOR / RECIPIENT / BANK_ADMIN
    if(type == null) type = "DONOR";

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // Approve or reject
    String action = request.getParameter("action");
    String userIdParam = request.getParameter("user_id");
    if(action != null && userIdParam != null) {
        try {
            con = getConnection();
            int uid = Integer.parseInt(userIdParam);
            String approvalValue = action.equals("approve") ? "Y" : "N";

            // Only update users table
            String sql = "UPDATE users SET IS_APPROVED=? WHERE USER_ID=?";
            ps = con.prepareStatement(sql);
            ps.setString(1, approvalValue);
            ps.setInt(2, uid);
            ps.executeUpdate();
            ps.close();

        } catch(Exception e) {
            out.println("Error: " + e.getMessage());
        } finally {
            try { if(ps!=null) ps.close(); } catch(SQLException e){}
            try { if(con!=null) con.close(); } catch(SQLException e){}
        }
    }

    // Fetch pending users
    try {
        con = getConnection();
        String sqlFetch = "";
        if("DONOR".equals(type)) {
            sqlFetch = "SELECT u.USER_ID, u.USERNAME, u.EMAIL, d.FULL_NAME, d.BLOOD_GROUP " +
                       "FROM users u JOIN donors d ON u.USER_ID=d.USER_ID " +
                       "WHERE u.ROLE='DONOR' AND u.IS_APPROVED='N'";
            ps = con.prepareStatement(sqlFetch);
            rs = ps.executeQuery();
        } else if("RECIPIENT".equals(type)) {
            sqlFetch = "SELECT u.USER_ID, u.USERNAME, u.EMAIL, r.FULL_NAME, r.BLOOD_GROUP, r.CONTACT_PHONE " +
                       "FROM users u JOIN recipients r ON u.USER_ID=r.USER_ID " +
                       "WHERE u.ROLE='RECIPIENT' AND u.IS_APPROVED='N'";
            ps = con.prepareStatement(sqlFetch);
            rs = ps.executeQuery();
        } else if("BANK_ADMIN".equals(type)) {
            sqlFetch = "SELECT u.USER_ID, u.USERNAME, u.EMAIL, b.NAME as BANK_NAME " +
                       "FROM users u JOIN blood_banks b ON u.USER_ID=b.USER_ID " +
                       "WHERE u.ROLE='BANK_ADMIN' AND (u.IS_APPROVED='N' OR b.STATUS='N')";
            ps = con.prepareStatement(sqlFetch);
            rs = ps.executeQuery();
        }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Manage Approvals - Admin</title>
    <link rel="stylesheet" href="../css/style.css">
    <style>
        body {
    font-family:'Segoe UI', sans-serif;
    margin:0; 
    padding:0;

    /* Important FIX */
    min-height: 100vh; 
    display: flex;
    justify-content: center;

    /* Background correctly covering full page */
    background: url("../images/blood1.jpeg") no-repeat center center fixed;
    background-size: cover;
}

        .container {max-width:1000px; margin:20px auto; padding:20px; background:white; border-radius:8px; box-shadow:0 4px 6px rgba(0,0,0,0.1);}
        table {width:100%; border-collapse:collapse; margin-top:20px;}
        th, td {border:1px solid #ddd; padding:10px; text-align:left;}
        th {background:#d32f2f; color:white;}
        .btn {padding:6px 12px; border:none; border-radius:4px; text-decoration:none; color:white; cursor:pointer;}
        .approve {background:#27ae60;}
        .reject {background:#c62828;}
        .approve:hover {background:#2ecc71;}
        .reject:hover {background:#e53935;}
        .top-links {margin-top:10px;}
        .top-links a {margin-right:15px; text-decoration:none; color:#d32f2f;}
        .top-links a:hover {text-decoration:underline;}
    </style>
</head>
<body>
    <div class="container">
        <h1>Pending Approvals - <%= type %></h1>
        <div class="top-links">
            <a href="dashboard.jsp">Back to Dashboard</a>
        </div>
        <table>
            <tr>
                <th>Username</th>
                <th>Email</th>
                <% if("BANK_ADMIN".equals(type)) { %><th>Bank Name</th><% } %>
                <th>Action</th>
            </tr>
            <%
                while(rs.next()) {
            %>
            <tr>
                <td><%= rs.getString("USERNAME") %></td>
                <td><%= rs.getString("EMAIL") %></td>
                <% if("BANK_ADMIN".equals(type)) { %>
                <td><%= rs.getString("BANK_NAME") %></td>
                <% } %>
                <td>
                    <a class="btn approve" href="approvals.jsp?type=<%= type %>&action=approve&user_id=<%= rs.getInt("USER_ID") %>">Approve</a>
                    <a class="btn reject" href="approvals.jsp?type=<%= type %>&action=reject&user_id=<%= rs.getInt("USER_ID") %>">Reject</a>
                </td>
            </tr>
            <%
                }
                try { if(rs!=null) rs.close(); } catch(SQLException e){}
                try { if(ps!=null) ps.close(); } catch(SQLException e){}
                try { if(con!=null) con.close(); } catch(SQLException e){}
            %>
        </table>
    </div>
</body>
</html>
<%
    } catch(Exception e){
        out.println("Error fetching users: " + e.getMessage());
    }
%>
