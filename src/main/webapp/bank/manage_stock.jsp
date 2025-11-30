<%@ page import="java.sql.*" %>
<%@ include file="../db.jsp" %>

<%
    // Ensure only bank users access
    Object bankObj = session.getAttribute("bank_id");

    if (bankObj == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String bankId = bankObj.toString();

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String message = "";
    String error = "";

    try {

        con = getConnection();

        // HANDLE UPDATE STOCK
        if ("POST".equalsIgnoreCase(request.getMethod())) {

            // FIX: Using BLOOD_GROUP (correct column)
            String bloodGroup = request.getParameter("blood_group");
            int units = Integer.parseInt(request.getParameter("units"));

            // Check if stock exists
            ps = con.prepareStatement(
                "SELECT units_available FROM blood_stock WHERE bank_id=? AND blood_group=?"
            );
            ps.setString(1, bankId);
            ps.setString(2, bloodGroup);
            rs = ps.executeQuery();

            if (rs.next()) {
                int current = rs.getInt("units_available");
                int updated = current + units;

                if (updated < 0) {
                    error = "Units cannot be negative.";
                } else {
                    ps.close();
                    ps = con.prepareStatement(
                        "UPDATE blood_stock SET units_available=?, last_updated=SYSTIMESTAMP WHERE bank_id=? AND blood_group=?"
                    );
                    ps.setInt(1, updated);
                    ps.setString(2, bankId);
                    ps.setString(3, bloodGroup);
                    ps.executeUpdate();

                    message = "Stock updated successfully.";
                }

            } else {
                if (units < 0) {
                    error = "Cannot create stock with negative units.";
                } else {
                    ps.close();
                    ps = con.prepareStatement(
                        "INSERT INTO blood_stock (stock_id, bank_id, blood_group, units_available, last_updated) VALUES (blood_stock_seq.NEXTVAL, ?, ?, ?, SYSTIMESTAMP)"
                    );
                    ps.setString(1, bankId);
                    ps.setString(2, bloodGroup);
                    ps.setInt(3, units);
                    ps.executeUpdate();

                    message = "New blood group added!";
                }
            }
        }

        // Fetch updated list
        ps = con.prepareStatement(
            "SELECT blood_group, units_available FROM blood_stock WHERE bank_id=? ORDER BY blood_group"
        );
        ps.setString(1, bankId);
        rs = ps.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
<title>Manage Blood Stock</title>
<style>
body {
    font-family: Arial;
    background: #f7f7f7;
    margin: 0; padding: 0;
    background:url("../images/blood1.jpeg") no-repeat center center/cover;
}
.container {
    width: 70%;
    margin: auto;
    margin-top: 30px;
    background: white;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0px 0px 8px #ccc;
}
h2 { text-align: center; }
table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
}
th, td {
    border: 1px solid #ddd;
    padding: 12px;
    text-align: center;
}
th {
    background: #e91e63;
    color: white;
}
.message { color: green; font-weight: bold; }
.error { color: red; font-weight: bold; }
input, select {
    padding: 10px;
    width: 200px;
}
button {
    padding: 10px 20px;
    background: #e91e63;
    border: none;
    color: white;
    cursor: pointer;
    border-radius: 5px;
}
button:hover { background: #d81b60; }
</style>
</head>

<body>
<div class="container">
    <h2>Manage Blood Stock</h2>

    <% if (!message.equals("")) { %>
        <p class="message"><%= message %></p>
    <% } %>

    <% if (!error.equals("")) { %>
        <p class="error"><%= error %></p>
    <% } %>

    <form method="post">

        <label>Select Blood Group:</label>
        <select name="blood_group" required>
            <option value="A+">A+</option>
            <option value="A-">A-</option>
            <option value="B+">B+</option>
            <option value="B-">B-</option>
            <option value="O+">O+</option>
            <option value="O-">O-</option>
            <option value="AB+">AB+</option>
            <option value="AB-">AB-</option>
        </select>

        <br><br>

        <label>Units (+ add / - reduce):</label>
        <input type="number" name="units" required>

        <br><br>

        <button type="submit">Update Stock</button>
    </form>

    <h3>Current Stock</h3>

    <table>
        <tr>
            <th>Blood Group</th>
            <th>Units Available</th>
        </tr>

        <% while (rs.next()) { %>
            <tr>
                <td><%= rs.getString("blood_group") %></td>
                <td><%= rs.getInt("units_available") %></td>
            </tr>
        <% } %>

    </table>

    <br>
    <a href="bank_dashboard.jsp"><button>Back to Dashboard</button></a>
</div>
</body>
</html>

<%
    } catch (Exception e) {
        out.println("<p class='error'>Error: " + e.getMessage() + "</p>");
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (con != null) con.close(); } catch (Exception ex) {}
    }
%>
