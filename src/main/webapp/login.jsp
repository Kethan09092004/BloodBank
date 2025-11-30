<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.math.BigInteger" %>
<%@ include file="db.jsp" %>



<%
String msg = "";

if ("POST".equalsIgnoreCase(request.getMethod())) {
    String uname = request.getParameter("username");
    String pass = request.getParameter("password");
    String role = request.getParameter("role");

    if (uname == null || uname.trim().equals("") || pass == null || pass.trim().equals("") || role == null || role.trim().equals("")) {
        msg = "Please fill all fields!";
    } else {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            ps = conn.prepareStatement(
                "SELECT USER_ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_APPROVED " +
                "FROM USERS WHERE USERNAME = ? AND ROLE = ?"
            );
            ps.setString(1, uname.trim());
            ps.setString(2, role.toUpperCase()); // ensure matching exactly the stored role

            rs = ps.executeQuery();

            if (rs.next()) {
                String storedHash = rs.getString("PASSWORD_HASH");
                String isApproved = rs.getString("IS_APPROVED");

                // Only check approval for non-admins
                if (!"ADMIN".equals(role.toUpperCase()) && !"Y".equalsIgnoreCase(isApproved)) {
                    msg = "Your account is not approved yet!";
                } else {
                    boolean passwordMatches = storedHash.length() == 64
                        ? storedHash.equals(hashPassword(pass))
                        : storedHash.equals(pass);

                    if (passwordMatches) {
                        // Set session attributes
                        session.setAttribute("user_id", rs.getInt("USER_ID"));
                        session.setAttribute("username", rs.getString("USERNAME"));
                        session.setAttribute("email", rs.getString("EMAIL"));
                        session.setAttribute("role", rs.getString("ROLE"));

                        // Redirect based on role
                        switch (role.toUpperCase()) {
                            case "ADMIN":
                                response.sendRedirect("admin/dashboard.jsp");
                                return;
                            case "DONOR":
                                response.sendRedirect("donor/donor_dashboard.jsp");
                                return;
                            case "BANK_ADMIN":
                                response.sendRedirect("bank/bank_dashboard.jsp");
                                return;
                            case "RECIPIENT":
                                response.sendRedirect("recipient/recipient_dashboard.jsp");
                                return;
                        }
                    } else {
                        msg = "Invalid password!";
                    }
                }
            } else {
                msg = "User not found or role mismatch!";
            }
        } catch (Exception e) {
            msg = "Error: " + e.getMessage();
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception e) {}
            try { if (ps != null) ps.close(); } catch (Exception e) {}
            try { if (conn != null) conn.close(); } catch (Exception e) {}
        }
    }
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Login - Blood Bank Management System</title>
<link rel="stylesheet" href="css/style.css">
<style>
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: #f5f5f5;
    background:url("images/blood.jpg") no-repeat center center/cover;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    margin: 0;
}
.container { width: 100%; max-width: 400px; padding: 20px; }
.login-container {
    background: white;
    padding: 30px;
    border-radius: 8px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
h2 { color: #d32f2f; text-align: center; margin-bottom: 25px; }
.form-group { margin-bottom: 20px; }
input[type="text"], input[type="password"], select {
    width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; box-sizing: border-box;
}
.btn-login {
    width: 100%; padding: 12px; background-color: #d32f2f; color: white; border: none; border-radius: 4px; font-size: 16px; cursor: pointer;
}
.btn-login:hover { background-color: #b71c1c; }
.error { background-color: #ffebee; color: #c62828; padding: 10px 15px; border-radius: 4px; margin-bottom: 20px; font-size: 14px; }
.form-footer { text-align: center; margin-top: 20px; color: #666; }
.form-footer a { color: #d32f2f; text-decoration: none; }
.form-footer a:hover { text-decoration: underline; }
</style>
</head>
<body>
<div class="container">
    <div class="login-container">
        <h2>Login to Blood Bank System</h2>
        <% if (!msg.equals("")) { %>
            <div class="error"><%= msg %></div>
        <% } %>
        <form method="post">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" name="username" id="username" required placeholder="Enter your username">
            </div>
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" name="password" id="password" required placeholder="Enter your password">
            </div>
            <div class="form-group">
                <label for="role">Login As</label>
                <select name="role" id="role" required>
                    <option value="">Select Role</option>
                    <option value="DONOR">Blood Donor</option>
                    <option value="BANK_ADMIN">Blood Bank</option>
                    <option value="RECIPIENT">Recipient</option>
                    <option value="ADMIN">Administrator</option>
                </select>
            </div>
            <button type="submit" class="btn-login">Sign In</button>
        </form>
        <div class="form-footer">
            Don't have an account? <a href="select_role.jsp">Sign up</a>
        </div>
        <div class="form-footer">
            <a href="forgot_password.jsp">Forgot password?</a>
        </div>
    </div>
</div>
</body>
</html>
