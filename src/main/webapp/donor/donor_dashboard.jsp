<%@ page import="java.sql.*" %>
<%@ include file="../db.jsp" %>
<%
    int uid = (int) session.getAttribute("user_id");

    Connection con = null;
    PreparedStatement psDonor = null;
    ResultSet rsDonor = null;

    try {
        con = getConnection();
        psDonor = con.prepareStatement("SELECT * FROM donors WHERE user_id=?");
        psDonor.setInt(1, uid);
        rsDonor = psDonor.executeQuery();
        rsDonor.next();
%>
<!DOCTYPE html>
<html>
<head>
    <title>Donor Dashboard</title>
    <link rel="stylesheet" href="../css/style.css">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f9;
            background:url("../images/blood1.jpeg") no-repeat center center/cover;
            margin: 0;
            padding: 0;
        }
        header {
            background-color: #d32f2f;
            color: #fff;
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        header a {
            color: #fff;
            text-decoration: none;
            font-weight: bold;
        }
        .container {
            max-width: 900px;
            margin: 30px auto;
            background-color: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        h2 {
            color: #d32f2f;
            margin-bottom: 20px;
        }
        .profile, .donations {
            margin-bottom: 30px;
        }
        .profile li {
            list-style: none;
            margin-bottom: 10px;
            font-size: 16px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 12px 15px;
            text-align: left;
        }
        th {
            background-color: #d32f2f;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background-color: #d32f2f;
            color: #fff;
            border: none;
            border-radius: 4px;
            text-decoration: none;
            font-weight: bold;
            transition: background-color 0.3s;
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
        <div>Welcome, <%= rsDonor.getString("full_name") %></div>
        <div><a href="../logout.jsp">Logout</a></div>
    </header>

    <div class="container">
        <h2>Your Profile</h2>
        <ul class="profile">
            <li><strong>Full Name:</strong> <%= rsDonor.getString("full_name") %></li>
            <li><strong>Blood Group:</strong> <%= rsDonor.getString("blood_group") %></li>
            <li><strong>Last Donation:</strong> 
                <%= (rsDonor.getDate("last_donation") != null) ? new java.text.SimpleDateFormat("dd-MMM-yyyy").format(rsDonor.getDate("last_donation")) : "No donations yet" %>
            </li>
            <li><strong>Address:</strong> <%= rsDonor.getString("address") %></li>
            <li><strong>City:</strong> <%= rsDonor.getString("city") %></li>
        </ul>

        <h2>Your Donations</h2>
        <table>
            <tr>
                <th>Bank</th>
                <th>Date</th>
                <th>Status</th>
            </tr>
            <%
                PreparedStatement psDonations = con.prepareStatement(
                    "SELECT d.donation_date, d.status, b.name FROM donations d JOIN blood_banks b ON d.bank_id=b.bank_id WHERE d.donor_id=? ORDER BY d.donation_date DESC"
                );
                psDonations.setInt(1, rsDonor.getInt("donor_id"));
                ResultSet rsDonations = psDonations.executeQuery();

                while(rsDonations.next()) {
            %>
            <tr>
                <td><%= rsDonations.getString("name") %></td>
                <td><%= (rsDonations.getDate("donation_date") != null) ? new java.text.SimpleDateFormat("dd-MMM-yyyy").format(rsDonations.getDate("donation_date")) : "-" %></td>
                <td><%= rsDonations.getString("status") %></td>
            </tr>
            <% } 
                rsDonations.close();
                psDonations.close();
            %>
        </table>

        <br>
        <a href="book_appointment.jsp" class="btn">Book Appointment</a>
    </div>
</body>
</html>
<%
    } catch(Exception e) {
        out.println("Error: " + e.getMessage());
    } finally {
        try { if(rsDonor != null) rsDonor.close(); } catch(Exception e) {}
        try { if(psDonor != null) psDonor.close(); } catch(Exception e) {}
        try { if(con != null) con.close(); } catch(Exception e) {}
    }
%>
