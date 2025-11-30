<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register - Blood Bank</title>
    <style>
        :root {
            --primary: #e74c3c;
            --secondary: #c0392b;
            --light: #f5f5f5;
            --dark: #333;
            --gray: #95a5a6;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        body {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            background:url("images/blood.jpg") no-repeat center center/cover;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 15px;
            width: 100%;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
            padding: 40px;
            text-align: center;
            max-width: 500px;
            margin: 0 auto;
        }
        
        .logo {
            color: var(--primary);
            font-size: 2.5rem;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        h1 {
            color: var(--dark);
            margin-bottom: 30px;
            font-size: 1.8rem;
        }
        
        .role-options {
            display: flex;
            flex-direction: column;
            gap: 15px;
            margin-top: 30px;
        }
        
        .btn {
            display: block;
            padding: 15px 20px;
            background: var(--primary);
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 600;
            transition: all 0.3s ease;
            border: none;
            cursor: pointer;
            width: 100%;
            font-size: 1rem;
        }
        
        .btn:hover {
            background: var(--secondary);
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(231, 76, 60, 0.3);
        }
        
        .login-link {
            margin-top: 25px;
            color: var(--gray);
        }
        
        .login-link a {
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
        }
        
        @media (max-width: 480px) {
            .card {
                padding: 30px 20px;
            }
            
            h1 {
                font-size: 1.5rem;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="logo">
                <span>Blood Bank</span>
            </div>
            <h1>Join as a...</h1>
            
            <div class="role-options">
                <a href="donor_register.jsp" class="btn">
                    <i class="fas fa-hand-holding-medical"></i> Blood Donor
                </a>
                <a href="bank_register.jsp" class="btn" style="background: #3498db;">
                    <i class="fas fa-hospital"></i> Blood Bank
                </a>
                <a href="recipient_register.jsp" class="btn" style="background: #2ecc71;">
                    <i class="fas fa-user-injured"></i> Blood Recipient
                </a>
            </div>
            
            <p class="login-link">
                Already have an account? <a href="login.jsp">Sign in</a>
            </p>
        </div>
    </div>
    
    <!-- Font Awesome for icons -->
    <script src="https://kit.fontawesome.com/a076d05399.js" crossorigin="anonymous"></script>
</body>
</html>
