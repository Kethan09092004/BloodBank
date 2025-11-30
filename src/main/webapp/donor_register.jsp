<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ include file="db.jsp" %>

<%

String msg = "";
String msgType = "error";

if (request.getMethod().equalsIgnoreCase("POST")) {

    String fullName = request.getParameter("full_name");
    String email = request.getParameter("email").toLowerCase();
    String phone = request.getParameter("phone");
    String password = request.getParameter("password");
    String confirmPassword = request.getParameter("confirm_password");
    String bloodGroup = request.getParameter("blood_group");
    String address = request.getParameter("address");
    String city = request.getParameter("city");

    // Generate USERNAME from email
    String username = email.contains("@") 
                      ? email.substring(0, email.indexOf("@")) 
                      : email;

    // Validation
    if (!password.equals(confirmPassword)) {
        msg = "Passwords do not match!";
    } else {

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = getConnection();

            // Check if email exists
            String checkEmail = "SELECT user_id FROM users WHERE email=?";
            ps = conn.prepareStatement(checkEmail);
            ps.setString(1, email);
            rs = ps.executeQuery();

            if (rs.next()) {
                msg = "Email already registered!";
            } else {

                // Hash password SHA-256
                MessageDigest md = MessageDigest.getInstance("SHA-256");
                byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));

                StringBuilder hexString = new StringBuilder();
                for (byte b : hash) {
                    String h = Integer.toHexString(0xff & b);
                    if (h.length() == 1) hexString.append('0');
                    hexString.append(h);
                }
                String hashedPassword = hexString.toString();

                conn.setAutoCommit(false);

                // INSERT user
                String userSql =
                    "INSERT INTO users (username, email, password_hash, phone, role, is_approved, created_at) " +
                    "VALUES (?, ?, ?, ?, 'DONOR', 'N', SYSTIMESTAMP)";

                ps = conn.prepareStatement(userSql, new String[] { "USER_ID" });
                ps.setString(1, username);
                ps.setString(2, email);
                ps.setString(3, hashedPassword);
                ps.setString(4, phone);

                ps.executeUpdate();

                int userId = 0;
                rs = ps.getGeneratedKeys();
                if (rs.next()) {
                    userId = rs.getInt(1);
                }

                // INSERT donor
                String donorSql =
                    "INSERT INTO donors (user_id, full_name, blood_group, address, city) " +
                    "VALUES (?, ?, ?, ?, ?)";

                ps = conn.prepareStatement(donorSql);
                ps.setInt(1, userId);
                ps.setString(2, fullName);
                ps.setString(3, bloodGroup);
                ps.setString(4, address);
                ps.setString(5, city);

                ps.executeUpdate();

                conn.commit();

                msg = "Registration successful! Redirecting to login...";
                msgType = "success";
                response.setHeader("Refresh", "3;url=login.jsp");
            }

        } catch (Exception e) {
            if (conn != null) conn.rollback();
            msg = "Error: " + e.getMessage();
            e.printStackTrace();
        }
        finally {
            if (rs != null) rs.close();
            if (ps != null) ps.close();
            if (conn != null) conn.close();
        }
    }
}
%>



<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Donor Registration - Blood Bank</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        body {
            background-color: #f8f9fa;
            background:url("images/blood2.jpeg") no-repeat center center/cover;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .card {
            border: none;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
        }
        .card-header {
            background: linear-gradient(135deg, #e74c3c, #c0392b);
            color: white;
            border-radius: 10px 10px 0 0 !important;
            padding: 20px;
            text-align: center;
        }
        .form-control:focus {
            border-color: #e74c3c;
            box-shadow: 0 0 0 0.25rem rgba(231, 76, 60, 0.25);
        }
        .btn-primary {
            background-color: #e74c3c;
            border: none;
            padding: 10px 20px;
        }
        .btn-primary:hover {
            background-color: #c0392b;
        }
        .error {
            color: #dc3545;
            font-size: 0.875em;
            margin-top: 0.25rem;
        }
        .success {
            color: #28a745;
            font-size: 1em;
            margin: 1rem 0;
            padding: 0.75rem 1.25rem;
            border: 1px solid #d4edda;
            border-radius: 0.25rem;
            background-color: #d4edda;
        }
        .password-container {
            position: relative;
        }
        .password-toggle {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            color: #6c757d;
        }
    </style>
</head>
<body>
    <div class="container py-5">
        <div class="row justify-content-center">
            <div class="col-md-8 col-lg-6">
                <div class="card">
                    <div class="card-header">
                        <h2 class="mb-0"><i class="fas fa-user-plus me-2"></i>Donor Registration</h2>
                    </div>
                    <div class="card-body p-4">
                        <% if (!msg.isEmpty()) { %>
                            <div class="<%= "error".equals(msgType) ? "alert alert-danger" : "alert alert-success" %>">
                                <%= msg %>
                            </div>
                        <% } %>
                        
                        <form id="donorForm" method="post" onsubmit="return validateForm()">
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label for="full_name" class="form-label">Full Name <span class="text-danger">*</span></label>
                                    <input type="text" class="form-control" id="full_name" name="full_name" value="<%= request.getParameter("full_name") != null ? request.getParameter("full_name") : "" %>" required>
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label for="email" class="form-label">Email <span class="text-danger">*</span></label>
                                    <input type="email" class="form-control" id="email" name="email" value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>" required>
                                </div>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label for="phone" class="form-label">Phone <span class="text-danger">*</span></label>
                                    <input type="tel" class="form-control" id="phone" name="phone" value="<%= request.getParameter("phone") != null ? request.getParameter("phone") : "" %>" required>
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label for="blood_group" class="form-label">Blood Group <span class="text-danger">*</span></label>
                                    <select class="form-select" id="blood_group" name="blood_group" required>
                                        <option value="">Select Blood Group</option>
                                        <option value="A+" <%= "A+".equals(request.getParameter("blood_group")) ? "selected" : "" %>>A+</option>
                                        <option value="A-" <%= "A-".equals(request.getParameter("blood_group")) ? "selected" : "" %>>A-</option>
                                        <option value="B+" <%= "B+".equals(request.getParameter("blood_group")) ? "selected" : "" %>>B+</option>
                                        <option value="B-" <%= "B-".equals(request.getParameter("blood_group")) ? "selected" : "" %>>B-</option>
                                        <option value="AB+" <%= "AB+".equals(request.getParameter("blood_group")) ? "selected" : "" %>>AB+</option>
                                        <option value="AB-" <%= "AB-".equals(request.getParameter("blood_group")) ? "selected" : "" %>>AB-</option>
                                        <option value="O+" <%= "O+".equals(request.getParameter("blood_group")) ? "selected" : "" %>>O+</option>
                                        <option value="O-" <%= "O-".equals(request.getParameter("blood_group")) ? "selected" : "" %>>O-</option>
                                    </select>
                                </div>
                            </div>
                            
                            
                            
                            <div class="mb-3">
                                <label for="address" class="form-label">Address <span class="text-danger">*</span></label>
                                <textarea class="form-control" id="address" name="address" rows="2" required><%= request.getParameter("address") != null ? request.getParameter("address") : "" %></textarea>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label for="city" class="form-label">City <span class="text-danger">*</span></label>
                                    <input type="text" class="form-control" id="city" name="city" value="<%= request.getParameter("city") != null ? request.getParameter("city") : "" %>" required>
                                </div>
                               
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label for="password" class="form-label">Password <span class="text-danger">*</span></label>
                                    <div class="password-container">
                                        <input type="password" class="form-control" id="password" name="password" required>
                                        <i class="fas fa-eye password-toggle" onclick="togglePassword('password')"></i>
                                    </div>
                                    <div class="form-text">At least 8 characters with 1 uppercase, 1 lowercase, and 1 number</div>
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label for="confirm_password" class="form-label">Confirm Password <span class="text-danger">*</span></label>
                                    <div class="password-container">
                                        <input type="password" class="form-control" id="confirm_password" name="confirm_password" required>
                                        <i class="fas fa-eye password-toggle" onclick="togglePassword('confirm_password')"></i>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="d-grid gap-2 mt-4">
                                <button type="submit" class="btn btn-primary btn-lg">
                                    <i class="fas fa-user-plus me-2"></i>Register
                                </button>
                            </div>
                            
                            <div class="text-center mt-3">
                                <p>Already have an account? <a href="login.jsp">Login here</a></p>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function validateForm() {
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirm_password').value;
            const phone = document.getElementById('phone').value;
            const email = document.getElementById('email').value;
            
            // Check if passwords match
            if (password !== confirmPassword) {
                alert('Passwords do not match!');
                return false;
            }
            
            // Check password strength (at least 8 characters, 1 number, 1 uppercase, 1 lowercase)
            const passwordRegex = /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}$/;
            if (!passwordRegex.test(password)) {
                alert('Password must be at least 8 characters long and include at least one number, one uppercase and one lowercase letter.');
                return false;
            }
            
            // Validate phone number (basic validation)
            const phoneRegex = /^[0-9]{10,15}$/;
            if (!phoneRegex.test(phone)) {
                alert('Please enter a valid phone number (10-15 digits)');
                return false;
            }
            
            // Validate email
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email)) {
                alert('Please enter a valid email address');
                return false;
            }
            
            return true;
        }
        
        function togglePassword(fieldId) {
            const field = document.getElementById(fieldId);
            const icon = field.nextElementSibling;
            
            if (field.type === 'password') {
                field.type = 'text';
                icon.classList.remove('fa-eye');
                icon.classList.add('fa-eye-slash');
            } else {
                field.type = 'password';
                icon.classList.remove('fa-eye-slash');
                icon.classList.add('fa-eye');
            }
        }
        
        // Format phone number
        document.getElementById('phone').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            if (value.length > 10) value = value.substring(0, 10);
            e.target.value = value;
        });
        
        // Format pincode
        document.getElementById('pincode').addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            if (value.length > 6) value = value.substring(0, 6);
            e.target.value = value;
        });
        
        // Set max date for date of birth (18 years ago)
        document.addEventListener('DOMContentLoaded', function() {
            const today = new Date();
            const maxDate = new Date();
            maxDate.setFullYear(today.getFullYear() - 18);
            
            const formattedDate = maxDate.toISOString().split('T')[0];
            document.getElementById('date_of_birth').setAttribute('max', formattedDate);
        });
    </script>
</body>
</html>