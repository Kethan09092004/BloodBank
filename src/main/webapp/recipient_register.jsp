<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ include file="db.jsp" %>

<%
String msg = "";
String msgType = "error";

String fullName = "";
String email = "";
String phone = "";
String bloodGroup = "";

if ("POST".equalsIgnoreCase(request.getMethod())) {

    fullName = request.getParameter("full_name") == null ? "" : request.getParameter("full_name").trim();
    email = request.getParameter("email") == null ? "" : request.getParameter("email").trim().toLowerCase();
    phone = request.getParameter("phone") == null ? "" : request.getParameter("phone").trim();
    String password = request.getParameter("password") == null ? "" : request.getParameter("password");
    String confirmPassword = request.getParameter("confirm_password") == null ? "" : request.getParameter("confirm_password");
    bloodGroup = request.getParameter("blood_group") == null ? "" : request.getParameter("blood_group");

    // Validation
    if (fullName.isEmpty() || email.isEmpty() || phone.isEmpty() || password.isEmpty() ||
        bloodGroup.isEmpty()) {

        msg = "All fields are required!";

    } else if (!password.equals(confirmPassword)) {
        msg = "Passwords do not match!";

    } else if (password.length() < 8) {
        msg = "Password must be at least 8 characters long!";

    } else if (!phone.matches("^[0-9]{10}$")) {
        msg = "Please enter a valid 10-digit phone number!";

    } else if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
        msg = "Please enter a valid email address!";

    } else {

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = getConnection();
            conn.setAutoCommit(false);

            // Check duplicate email or phone
            ps = conn.prepareStatement("SELECT user_id FROM users WHERE email = ? OR phone = ?");
            ps.setString(1, email);
            ps.setString(2, phone);
            rs = ps.executeQuery();

            if (rs.next()) {
                msg = "A user with this email or phone already exists!";
            } else {

                rs.close();
                ps.close();

                String username = email.split("@")[0];

                // Hash password
                MessageDigest md = MessageDigest.getInstance("SHA-256");
                byte[] hashedBytes = md.digest(password.getBytes(StandardCharsets.UTF_8));
                String hashedPassword = "";
                for (byte b : hashedBytes) hashedPassword += String.format("%02x", b);

                // INSERT USERS
                ps = conn.prepareStatement(
                    "INSERT INTO users (user_id, username, email, password_hash, phone, role, is_approved, created_at) " +
                    "VALUES (USERS_SEQ.NEXTVAL, ?, ?, ?, ?, 'RECIPIENT', 'N', SYSTIMESTAMP)",
                    new String[]{"user_id"}
                );

                ps.setString(1, username);
                ps.setString(2, email);
                ps.setString(3, hashedPassword);
                ps.setString(4, phone);
                ps.executeUpdate();

                rs = ps.getGeneratedKeys();
                int userId = 0;
                if (rs.next()) userId = rs.getInt(1);

                rs.close();
                ps.close();

                // INSERT RECIPIENTS
                ps = conn.prepareStatement(
                    "INSERT INTO recipients (recipient_id, user_id, full_name, blood_group, contact_phone) " +
                    "VALUES (RECIPIENTS_SEQ.NEXTVAL, ?, ?, ?, ?)"
                );
                ps.setInt(1, userId);
                ps.setString(2, fullName);
                ps.setString(3, bloodGroup);
                ps.setString(4, phone);
                ps.executeUpdate();

                conn.commit();

                msg = "Registration successful! You can now login.";
                msgType = "success";

                fullName = email = phone = bloodGroup = "";
            }

        } catch (Exception e) {
            if (conn != null) conn.rollback();
            e.printStackTrace();
            msg = "An error occurred. Please try again.";
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception ex) {}
            if (ps != null) try { ps.close(); } catch (Exception ex) {}
            if (conn != null) try { conn.close(); } catch (Exception ex) {}
        }
    }
}
%>


<!-- YOUR UI PART BELOW (unchanged) -->




<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Recipient Registration - Blood Bank</title>
<style>
/* Keep your previous CSS unchanged for UI */
:root {
    --primary: #e74c3c;
    --secondary: #c0392b;
    --light: #f5f5f5;
    --dark: #333;
    --gray: #95a5a6;
    --success: #2ecc71;
    --error: #e74c3c;
}
body { background: linear-gradient(135deg,#f5f7fa 0%,#c3cfe2 100%);background:url("images/blood2.jpeg") no-repeat center center/cover; min-height:100vh; padding:20px; line-height:1.6; font-family:'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
.container { max-width:1000px; margin:0 auto; padding:0 15px; }
.card { background:white; border-radius:10px; box-shadow:0 10px 30px rgba(0,0,0,0.1); padding:30px; margin:20px 0; }
.logo { color:var(--primary); font-size:2rem; margin-bottom:20px; text-align:center; font-weight:700; }
h1 { color:var(--dark); margin-bottom:30px; text-align:center; font-size:1.8rem; }
.form-row { display:flex; flex-wrap:wrap; margin:0 -15px; }
.form-group { flex:1 0 calc(50% - 30px); margin:0 15px 20px; min-width:250px; }
.form-group.full-width { flex:1 0 calc(100% - 30px); }
label { display:block; margin-bottom:8px; color:var(--dark); font-weight:500; }
.form-control { width:100%; padding:12px 15px; border:1px solid #ddd; border-radius:5px; font-size:1rem; transition:border-color 0.3s ease; }
.form-control:focus { border-color:var(--primary); outline:none; box-shadow:0 0 0 3px rgba(231,76,60,0.2); }
select.form-control, textarea.form-control { height:45px; min-height:100px; resize:vertical; }
.btn { display:inline-block; padding:12px 30px; background:var(--primary); color:white; border:none; border-radius:5px; font-size:1rem; font-weight:600; cursor:pointer; transition:all 0.3s ease; text-decoration:none; text-align:center; }
.btn:hover { background:var(--secondary); transform:translateY(-2px); box-shadow:0 5px 15px rgba(231,76,60,0.3); }
.btn-block { display:block; width:100%; }
.alert { padding:12px 15px; border-radius:5px; margin-bottom:20px; font-size:0.9rem; }
.alert-error { background-color:#fde8e8; color:var(--error); border-left:4px solid var(--error); }
.alert-success { background-color:#e8f8f0; color:#27ae60; border-left:4px solid #2ecc71; }
.text-center { text-align:center; }
.login-link { margin-top:20px; text-align:center; color:var(--gray); }
.login-link a { color:var(--primary); text-decoration:none; font-weight:600; }
.password-container { position:relative; }
.toggle-password { position:absolute; right:10px; top:50%; transform:translateY(-50%); cursor:pointer; color:var(--gray); }
@media(max-width:768px){.form-group{flex:1 0 100%;}.card{padding:20px 15px;}}
</style>
</head>
<body>
<div class="container">
    <div class="card">
        <div class="logo">Blood Bank</div>
        <h1>Recipient Registration</h1>

        <% if (!msg.isEmpty()) { %>
            <div class="alert alert-<%= msgType %>"><%= msg %></div>
        <% } %>

        <form id="recipientForm" method="post" onsubmit="return validateForm()">
            <div class="form-row">
                <div class="form-group">
                    <label for="full_name">Full Name *</label>
                    <input type="text" id="full_name" name="full_name" class="form-control" value="<%= fullName %>" required>
                </div>
                <div class="form-group">
                    <label for="email">Email *</label>
                    <input type="email" id="email" name="email" class="form-control" value="<%= email %>" required>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="phone">Phone Number *</label>
                    <input type="tel" id="phone" name="phone" class="form-control" value="<%= phone %>" pattern="[0-9]{10}" required>
                    <small>10-digit number only</small>
                </div>
                <div class="form-group">
                    <label for="blood_group">Required Blood Group *</label>
                    <select id="blood_group" name="blood_group" class="form-control" required>
                        <option value="">Select Blood Group</option>
                        <option value="A+" <%= "A+".equals(bloodGroup) ? "selected" : "" %>>A+</option>
                        <option value="A-" <%= "A-".equals(bloodGroup) ? "selected" : "" %>>A-</option>
                        <option value="B+" <%= "B+".equals(bloodGroup) ? "selected" : "" %>>B+</option>
                        <option value="B-" <%= "B-".equals(bloodGroup) ? "selected" : "" %>>B-</option>
                        <option value="AB+" <%= "AB+".equals(bloodGroup) ? "selected" : "" %>>AB+</option>
                        <option value="AB-" <%= "AB-".equals(bloodGroup) ? "selected" : "" %>>AB-</option>
                        <option value="O+" <%= "O+".equals(bloodGroup) ? "selected" : "" %>>O+</option>
                        <option value="O-" <%= "O-".equals(bloodGroup) ? "selected" : "" %>>O-</option>
                    </select>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="password">Password *</label>
                    <input type="password" id="password" name="password" class="form-control" minlength="8" required>
                </div>
                <div class="form-group">
                    <label for="confirm_password">Confirm Password *</label>
                    <input type="password" id="confirm_password" name="confirm_password" class="form-control" minlength="8" required>
                </div>
            </div>
            <div class="form-group full-width">
                <button type="submit" class="btn btn-block">Register as Recipient</button>
            </div>
        </form>

        <div class="login-link">
            Already have an account? <a href="login.jsp">Login here</a>
        </div>
    </div>
</div>

<script>
// JS validation same as your original
function validateForm() {
    const password = document.getElementById('password').value;
    const confirmPassword = document.getElementById('confirm_password').value;
    const phone = document.getElementById('phone').value;
    const email = document.getElementById('email').value;
    if (password !== confirmPassword) { alert('Passwords do not match!'); return false; }
    if (password.length < 8) { alert('Password must be at least 8 characters long!'); return false; }
    if (!/^[0-9]{10}$/.test(phone)) { alert('Please enter a valid 10-digit phone number!'); return false; }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { alert('Please enter a valid email address!'); return false; }
    return true;
}
</script>
</body>
</html>
