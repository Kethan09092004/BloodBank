<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ include file="db.jsp" %>

<%
String msg = "";
String msgType = "error";

if (request.getMethod().equalsIgnoreCase("POST")) {

    String bankName = request.getParameter("bank_name").trim();
    String email = request.getParameter("email").trim().toLowerCase();
    String phone = request.getParameter("phone").trim();
    String password = request.getParameter("password");
    String confirmPassword = request.getParameter("confirm_password");
    String address = request.getParameter("address").trim();
    String city = request.getParameter("city").trim();

    // Validation
    if (bankName.isEmpty() || email.isEmpty() || phone.isEmpty() || password.isEmpty() ||
        confirmPassword.isEmpty() || address.isEmpty() || city.isEmpty()) {

        msg = "All fields are required!";
    }
    else if (!password.equals(confirmPassword)) {
        msg = "Passwords do not match!";
    }
    else if (!phone.matches("^[0-9]{10}$")) {
        msg = "Phone number must be 10 digits!";
    }
    else if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
        msg = "Invalid email!";
    }
    else {

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = getConnection();
            conn.setAutoCommit(false);

            // Check duplicate email
            ps = conn.prepareStatement("SELECT user_id FROM users WHERE email=?");
            ps.setString(1, email);
            rs = ps.executeQuery();

            if (rs.next()) {
                msg = "Email already registered!";
            } else {
                // Hash password
                MessageDigest digest = MessageDigest.getInstance("SHA-256");
                byte[] hash = digest.digest(password.getBytes(StandardCharsets.UTF_8));
                StringBuilder hex = new StringBuilder();
                for (byte b : hash) {
                    String h = Integer.toHexString(0xff & b);
                    if (h.length() == 1) hex.append('0');
                    hex.append(h);
                }
                String passwordHash = hex.toString();

                // Insert into USERS table
                ps = conn.prepareStatement(
    "INSERT INTO users (username, email, phone, password_hash, role, is_approved, created_at) " +
    "VALUES (?, ?, ?, ?, 'BANK_ADMIN', 'N', SYSDATE)",
    new String[]{"user_id"}
);

                ps.setString(1, email.split("@")[0]); // username = email prefix
                ps.setString(2, email);
                ps.setString(3, phone);
                ps.setString(4, passwordHash);

                ps.executeUpdate();

                // Get generated user ID
                rs = ps.getGeneratedKeys();
                int userId = 0;

                if (rs.next()) {
                    userId = rs.getInt(1);
                }

                // Insert into BLOOD_BANKS
                ps = conn.prepareStatement(
    "INSERT INTO blood_banks (user_id, name, city, address, contact_phone, status) " +
    "VALUES (?, ?, ?, ?, ?, 'PENDING')"
);

                ps.setInt(1, userId);
                ps.setString(2, bankName);
                ps.setString(3, city);
                ps.setString(4, address);
                ps.setString(5, phone);

                ps.executeUpdate();

                conn.commit();

                msg = "Registration successful! Wait for admin approval.";
                msgType = "success";

            }

        } catch (Exception e) {
            if (conn != null) conn.rollback();
            msg = "Error: " + e.getMessage();
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (ps != null) try { ps.close(); } catch (Exception e) {}
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    }

}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Blood Bank Registration</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Inter', sans-serif; }

        body {
            background: linear-gradient(to right, #f5f7fa, #c3cfe2);
            background:url("images/blood2.jpeg") no-repeat center center/cover;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .container {
            background: white;
            padding: 40px 35px;
            border-radius: 12px;
            box-shadow: 0 8px 20px rgba(0,0,0,0.15);
            width: 400px;
        }

        .container .title {
            font-size: 28px;
            font-weight: 700;
            text-align: center;
            color: #e74c3c;
            margin-bottom: 25px;
        }

        .alert {
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-size: 14px;
            text-align: center;
        }

        .success { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }

        label {
            font-weight: 600;
            margin-bottom: 5px;
            display: block;
            color: #333;
        }

        input, textarea {
            width: 100%;
            padding: 12px;
            margin-bottom: 18px;
            border-radius: 6px;
            border: 1px solid #ccc;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        input:focus, textarea:focus {
            border-color: #e74c3c;
            outline: none;
            box-shadow: 0 0 5px rgba(231,76,60,0.3);
        }

        button {
            width: 100%;
            background: linear-gradient(90deg, #e74c3c, #c0392b);
            color: white;
            padding: 14px;
            font-size: 16px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 600;
        }

        button:hover {
            background: linear-gradient(90deg, #c0392b, #e74c3c);
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }

        p.login-link {
            text-align: center;
            margin-top: 15px;
            font-size: 14px;
        }

        p.login-link a {
            text-decoration: none;
            color: #e74c3c;
            font-weight: 600;
        }

        p.login-link a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>

<div class="container">

    <div class="title">Blood Bank Registration</div>

    <% if (!msg.isEmpty()) { %>
        <div class="alert <%= msgType %>"><%= msg %></div>
    <% } %>

    <form method="post">
        <label>Blood Bank Name</label>
        <input type="text" name="bank_name" required>

        <label>Email</label>
        <input type="email" name="email" required>

        <label>Phone Number</label>
        <input type="text" name="phone" maxlength="10" required>

        <label>Address</label>
        <textarea name="address" required></textarea>

        <label>City</label>
        <input type="text" name="city" required>

        <label>Password</label>
        <input type="password" name="password" required minlength="8">

        <label>Confirm Password</label>
        <input type="password" name="confirm_password" required minlength="8">

        <button type="submit">Register</button>
    </form>

    <p class="login-link">
        Already have an account? <a href="login.jsp">Login</a>
    </p>

</div>

</body>
</html>
