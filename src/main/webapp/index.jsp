<%@ page import="java.sql.*, java.util.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>Blood Bank System</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">

   <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: "Poppins", sans-serif;
        }

        body {
            background: linear-gradient(135deg, #ff4d4d, #8b0000), 
                        url("images/blood.jpg") no-repeat center center/cover;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            color: white;
            background-blend-mode: overlay; /* keeps gradient + image visible */
        }
        h1{
            color:red;
        }

        .container {
            width: 420px;
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(12px);
            padding: 35px;
            border-radius: 15px;
            text-align: center;
            box-shadow: 0 8px 25px rgba(0,0,0,0.3);
            animation: fadeIn 1.2s ease-in-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .container h1 {
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 25px;
            line-height: 34px;
        }

        .btn {
            display: block;
            width: 100%;
            background: #ffffff;
            color: #b30000;
            padding: 14px;
            margin: 12px 0;
            font-size: 18px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: 0.3s ease;
        }

        .btn:hover {
            background: #ffe6e6;
            transform: scale(1.03);
        }
</style>

</head>

<body>
    <div class="container">
        <h1>Online Blood Bank<br>Management System</h1>

        <a class="btn" href="login.jsp">Login</a>
        <a class="btn" href="select_role.jsp">Register</a>
    </div>
</body>
</html>
