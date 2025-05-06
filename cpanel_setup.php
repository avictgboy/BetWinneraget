<?php
/**
 * BetWinner Agent Portal - cPanel Setup Helper
 * This script helps with setting up the application in cPanel environments.
 */

// Basic security - prevent direct access if not accessed through web
if (!isset($_SERVER['HTTP_HOST'])) {
    die("This script can only be run through a web browser.");
}

// Configuration
$appName = 'BetWinner Agent Portal';
$appVersion = '1.0.0';
$cpanelUrl = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https://' : 'http://';
$cpanelUrl .= $_SERVER['HTTP_HOST'];
$cpanelUrl = str_replace(':2083', '', $cpanelUrl);  // Remove port if present
$cpanelUrl .= ':2083';  // Add cPanel port

// Current step
$step = isset($_GET['step']) ? (int)$_GET['step'] : 1;

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if ($step === 1 && isset($_POST['domain'])) {
        $domain = trim($_POST['domain']);
        $step = 2;
    } elseif ($step === 2 && isset($_POST['db_name']) && isset($_POST['db_user']) && isset($_POST['db_pass'])) {
        $dbName = trim($_POST['db_name']);
        $dbUser = trim($_POST['db_user']);
        $dbPass = trim($_POST['db_pass']);
        $step = 3;
    }
}

// Function to get a clean base URL
function getBaseUrl() {
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
    $domain = $_SERVER['HTTP_HOST'];
    $path = dirname($_SERVER['REQUEST_URI']);
    return $protocol . $domain . rtrim($path, '/');
}

$baseUrl = getBaseUrl();

// Header and styling
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $appName; ?> - cPanel Setup Helper</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1d4ed8;
            --danger: #ef4444;
            --success: #22c55e;
            --warning: #f59e0b;
            --gray-light: #f3f4f6;
            --gray: #d1d5db;
            --gray-dark: #374151;
            --text: #111827;
        }
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: var(--text);
            background-color: var(--gray-light);
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: var(--primary-dark);
            border-bottom: 2px solid var(--primary);
            padding-bottom: 10px;
            margin-top: 0;
        }
        h2 {
            color: var(--primary-dark);
            margin-top: 30px;
        }
        .steps {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid var(--gray);
        }
        .step {
            text-align: center;
            position: relative;
            width: 30%;
        }
        .step-number {
            display: inline-block;
            width: 35px;
            height: 35px;
            background-color: var(--gray);
            color: white;
            border-radius: 50%;
            line-height: 35px;
            margin-bottom: 5px;
        }
        .step.active .step-number {
            background-color: var(--primary);
        }
        .step.completed .step-number {
            background-color: var(--success);
        }
        .step-label {
            font-size: 14px;
            color: var(--gray-dark);
        }
        .step.active .step-label {
            color: var(--primary);
            font-weight: bold;
        }
        .step.completed .step-label {
            color: var(--success);
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 10px;
            border: 1px solid var(--gray);
            border-radius: 4px;
            box-sizing: border-box;
        }
        button {
            background-color: var(--primary);
            color: white;
            border: none;
            padding: 12px 20px;
            cursor: pointer;
            border-radius: 4px;
            font-size: 16px;
        }
        button:hover {
            background-color: var(--primary-dark);
        }
        .btn-container {
            display: flex;
            justify-content: space-between;
            margin-top: 30px;
        }
        .alert {
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .alert-info {
            background-color: #e0f2fe;
            color: #0369a1;
            border: 1px solid #bae6fd;
        }
        .alert-warning {
            background-color: #fff7ed;
            color: var(--warning);
            border: 1px solid #fed7aa;
        }
        a {
            color: var(--primary);
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .help-text {
            font-size: 14px;
            color: var(--gray-dark);
            margin-top: 5px;
        }
        .step-content {
            margin-bottom: 30px;
        }
        ol {
            padding-left: 20px;
        }
        li {
            margin-bottom: 15px;
        }
        code {
            background-color: var(--gray-light);
            padding: 2px 5px;
            border-radius: 3px;
            font-family: monospace;
        }
        img {
            max-width: 100%;
            border: 1px solid var(--gray);
            border-radius: 4px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1><?php echo $appName; ?> - cPanel Setup Helper</h1>
        
        <div class="steps">
            <div class="step <?php echo $step >= 1 ? 'active' : ''; ?> <?php echo $step > 1 ? 'completed' : ''; ?>">
                <div class="step-number">1</div>
                <div class="step-label">Domain Setup</div>
            </div>
            <div class="step <?php echo $step >= 2 ? 'active' : ''; ?> <?php echo $step > 2 ? 'completed' : ''; ?>">
                <div class="step-number">2</div>
                <div class="step-label">Database Setup</div>
            </div>
            <div class="step <?php echo $step >= 3 ? 'active' : ''; ?>">
                <div class="step-number">3</div>
                <div class="step-label">Installation</div>
            </div>
        </div>
        
        <?php if ($step === 1): // Domain Setup ?>
            <h2>Step 1: Domain Setup</h2>
            
            <div class="alert alert-info">
                <strong>Info:</strong> This helper will guide you through setting up BetWinner Agent Portal on your cPanel hosting account.
            </div>
            
            <div class="step-content">
                <ol>
                    <li>
                        <strong>Log in to your cPanel account</strong>
                        <div class="help-text">Go to <a href="<?php echo $cpanelUrl; ?>" target="_blank"><?php echo $cpanelUrl; ?></a> and log in with your cPanel credentials.</div>
                    </li>
                    
                    <li>
                        <strong>Create a subdomain or use an existing domain</strong>
                        <div class="help-text">In cPanel, go to <strong>Domains</strong> > <strong>Subdomains</strong> to create a new subdomain, or use your main domain.</div>
                    </li>
                </ol>
            </div>
            
            <form method="post" action="?step=1">
                <div class="form-group">
                    <label for="domain">Enter your domain/subdomain:</label>
                    <input type="text" id="domain" name="domain" placeholder="example.com or app.example.com" required>
                    <div class="help-text">Enter the domain where you want to install the application</div>
                </div>
                
                <div class="btn-container">
                    <div></div> <!-- Empty div for alignment -->
                    <button type="submit">Continue to Database Setup</button>
                </div>
            </form>
        
        <?php elseif ($step === 2): // Database Setup ?>
            <h2>Step 2: Database Setup</h2>
            
            <div class="step-content">
                <ol>
                    <li>
                        <strong>Create a MySQL database</strong>
                        <div class="help-text">In cPanel, go to <strong>Databases</strong> > <strong>MySQL Databases</strong>.</div>
                    </li>
                    
                    <li>
                        <strong>Create a database user</strong>
                        <div class="help-text">In the same MySQL Databases page, create a new user with a strong password.</div>
                    </li>
                    
                    <li>
                        <strong>Add the user to the database</strong>
                        <div class="help-text">In the "Add User To Database" section, select your database and user, then give the user "ALL PRIVILEGES".</div>
                    </li>
                </ol>
            </div>
            
            <form method="post" action="?step=2">
                <div class="form-group">
                    <label for="db_name">Database Name:</label>
                    <input type="text" id="db_name" name="db_name" required>
                    <div class="help-text">Usually your cPanel username + an underscore + the name you chose (e.g., username_betwinner)</div>
                </div>
                
                <div class="form-group">
                    <label for="db_user">Database Username:</label>
                    <input type="text" id="db_user" name="db_user" required>
                    <div class="help-text">Usually your cPanel username + an underscore + the username you chose</div>
                </div>
                
                <div class="form-group">
                    <label for="db_pass">Database Password:</label>
                    <input type="password" id="db_pass" name="db_pass" required>
                    <div class="help-text">The password you created for the database user</div>
                </div>
                
                <div class="btn-container">
                    <a href="?step=1" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--gray-dark); color: white; border-radius: 4px;">Previous</a>
                    <button type="submit">Continue to Installation</button>
                </div>
            </form>
        
        <?php elseif ($step === 3): // Installation ?>
            <h2>Step 3: Installation</h2>
            
            <div class="alert alert-info">
                <strong>Success!</strong> Your configuration information has been collected.
            </div>
            
            <div class="step-content">
                <h3>Final Steps:</h3>
                
                <ol>
                    <li>
                        <strong>Upload Application Files</strong>
                        <div class="help-text">
                            <p>Use cPanel's File Manager or FTP to upload the BetWinner application files to your server.</p>
                            <p>For the domain <strong><?php echo $domain ?? 'you selected'; ?></strong>, upload to: <code>public_html/<?php echo $domain !== $_SERVER['HTTP_HOST'] ? substr($domain, 0, strpos($domain, '.')) : ''; ?></code></p>
                        </div>
                    </li>
                    
                    <li>
                        <strong>Create .env File</strong>
                        <div class="help-text">
                            <p>Create a file named <code>.env</code> in the application root with the following content:</p>
                            <pre style="background-color: #f3f4f6; padding: 10px; border-radius: 4px; overflow-x: auto;">DATABASE_URL=postgresql://<?php echo $dbUser ?? 'database_user'; ?>:<?php echo $dbPass ?? 'database_password'; ?>@localhost:5432/<?php echo $dbName ?? 'database_name'; ?>
NODE_ENV=production
PORT=5000</pre>
                        </div>
                    </li>
                    
                    <li>
                        <strong>Run Installer</strong>
                        <div class="help-text">
                            <p>Navigate to the installer at: <code>https://<?php echo $domain ?? 'your-domain.com'; ?>/installer.php</code></p>
                            <p>Follow the on-screen instructions to complete the installation.</p>
                        </div>
                    </li>
                </ol>
            </div>
            
            <div class="alert alert-warning">
                <strong>Note:</strong> Some shared hosting environments may require additional configuration for Node.js applications. Contact your hosting provider if you encounter issues.
            </div>
            
            <div class="btn-container">
                <a href="?step=2" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--gray-dark); color: white; border-radius: 4px;">Previous</a>
                <a href="https://<?php echo $domain ?? 'your-domain.com'; ?>/installer.php" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--primary); color: white; border-radius: 4px;">Go to Installer</a>
            </div>
        <?php endif; ?>
        
        <div style="margin-top: 40px; font-size: 12px; text-align: center; color: var(--gray-dark);">
            <?php echo $appName; ?> cPanel Setup Helper v<?php echo $appVersion; ?>
        </div>
    </div>
</body>
</html>
