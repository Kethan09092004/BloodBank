<%@ page import="java.sql.*" %>
<%@ include file="../db.jsp" %>
<%
    int uid = (int) session.getAttribute("user_id");
    String msg = "";
    
    if(request.getParameter("submit") != null) {
        String bankId = request.getParameter("bank_id");
        String donationDate = request.getParameter("donation_date");
        
        if(bankId == null || bankId.trim().equals("") || donationDate == null || donationDate.trim().equals("")) {
            msg = "Please select both bank and date!";
        } else {
            Connection con = null;
            PreparedStatement psDonor = null;
            PreparedStatement psInsert = null;
            ResultSet rsDonor = null;
            try {
                con = getConnection();
                
                // Get donor_id
                psDonor = con.prepareStatement("SELECT donor_id FROM donors WHERE user_id=?");
                psDonor.setInt(1, uid);
                rsDonor = psDonor.executeQuery();
                rsDonor.next();
                int donorId = rsDonor.getInt("donor_id");
                
                // Insert appointment into donations table
                psInsert = con.prepareStatement(
                    "INSERT INTO donations(donation_id, donor_id, bank_id, donation_date, status, units_donated) " +
                    "VALUES(donations_seq.NEXTVAL, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), 'SCHEDULED', 0)"
                );
                psInsert.setInt(1, donorId);
                psInsert.setInt(2, Integer.parseInt(bankId));
                psInsert.setString(3, donationDate);
                int inserted = psInsert.executeUpdate();
                
                if(inserted > 0) {
                    msg = "Appointment booked successfully!";
                } else {
                    msg = "Error booking appointment.";
                }
                
            } catch(Exception e) {
                msg = "Error: " + e.getMessage();
            } finally {
                try { if(rsDonor != null) rsDonor.close(); } catch(Exception e) {}
                try { if(psDonor != null) psDonor.close(); } catch(Exception e) {}
                try { if(psInsert != null) psInsert.close(); } catch(Exception e) {}
                try { if(con != null) con.close(); } catch(Exception e) {}
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Book Appointment - Donor</title>
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
            max-width: 600px;
            margin: 40px auto;
            background-color: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        h2 {
            color: #d32f2f;
            margin-bottom: 20px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            font-weight: bold;
            margin-bottom: 6px;
        }
        select, input[type="date"] {
            width: 100%;
            padding: 10px;
            font-size: 16px;
            border-radius: 4px;
            border: 1px solid #ddd;
        }
        .btn {
            background-color: #d32f2f;
            color: #fff;
            padding: 12px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
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



        .msg {
            margin-bottom: 20px;
            padding: 10px;
            border-radius: 4px;
        }
        .success { background-color: #e8f8f0; color: #27ae60; border-left: 4px solid #2ecc71; }
        .error { background-color: #ffebee; color: #c62828; border-left: 4px solid #c62828; }
    </style>
</head>
<body>
    <header>
        <div>Book Appointment</div>
        <div><a href="donor_dashboard.jsp">Back to Dashboard</a></div>
    </header>

    <div class="container">
        <% if(!msg.equals("")) { %>
            <div class="msg <%= msg.contains("successfully") ? "success" : "error" %>"><%= msg %></div>
        <% } %>

        <h2>Book Your Blood Donation Appointment</h2>

        <form method="post">
            <div class="form-group">
                <label for="bank_id">Select Blood Bank</label>
                <select name="bank_id" id="bank_id" required>
                    <option value="">-- Select Bank --</option>
                    <%
                        Connection con = null;
                        PreparedStatement psBanks = null;
                        ResultSet rsBanks = null;
                        try {
                            con = getConnection();
                            psBanks = con.prepareStatement("SELECT bank_id, name, city FROM blood_banks WHERE status='APPROVED'");
                            rsBanks = psBanks.executeQuery();
                            while(rsBanks.next()) {
                    %>
                        <option value="<%= rsBanks.getInt("bank_id") %>">
                            <%= rsBanks.getString("name") %> - <%= rsBanks.getString("city") %>
                        </option>
                    <%
                            }
                        } catch(Exception e) {
                            out.println("Error: "+e.getMessage());
                        } finally {
                            try { if(rsBanks != null) rsBanks.close(); } catch(Exception e) {}
                            try { if(psBanks != null) psBanks.close(); } catch(Exception e) {}
                            try { if(con != null) con.close(); } catch(Exception e) {}
                        }
                    %>
                </select>
            </div>

            <div class="form-group">
                <label for="donation_date">Select Date</label>
                <input type="date" name="donation_date" id="donation_date" required min="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
            </div>

            <button type="submit" name="submit" class="btn">Book Appointment</button>
        </form>
    </div>
</body>
</html>
