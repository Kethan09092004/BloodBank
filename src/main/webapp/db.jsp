<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.math.BigInteger" %>

<%!
    // Password hashing
    public static String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            BigInteger number = new BigInteger(1, hash);
            StringBuilder hexString = new StringBuilder(number.toString(16));
            while (hexString.length() < 64) {
                hexString.insert(0, '0');
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    // ✔ REAL DB connection method
    public Connection getConnection() throws Exception {
        String url = "jdbc:oracle:thin:@localhost:1521:XE";
        String usernameDB = "kethan";
        String passwordDB = "kethan";

        Class.forName("oracle.jdbc.driver.OracleDriver");
        return DriverManager.getConnection(url, usernameDB, passwordDB);
    }
%>
