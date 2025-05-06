<?php
/**
 * BetWinner Agent Portal - Shared Hosting Installer
 * This installer helps setting up the BetWinner Agent Portal on shared hosting environments
 * like HostGator, Namecheap, GoDaddy, etc.
 */

// Basic security - prevent direct access if not accessed through web
if (!isset($_SERVER['HTTP_HOST'])) {
    die("This script can only be run through a web browser.");
}

// Configuration
$appName = 'BetWinner Agent Portal';
$appVersion = '1.0.0';
$requiredPhpVersion = '8.0.0';
$requiredExtensions = ['pdo', 'json', 'openssl', 'zip'];  // Basic required extensions
$optionalExtensions = ['pdo_mysql', 'pdo_pgsql'];  // Database extensions - at least one is required

// Current step
$step = isset($_GET['step']) ? (int)$_GET['step'] : 1;

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    switch ($step) {
        case 1: // Requirements check
            $step = 2;
            break;
            
        case 2: // Database setup
            if (isset($_POST['db_host']) && isset($_POST['db_name']) && isset($_POST['db_user']) && isset($_POST['db_pass'])) {
                // Determine database type
                $dbType = isset($_POST['db_type']) ? $_POST['db_type'] : 'mysql';
                
                // Try to connect to database
                try {
                    if ($dbType === 'mysql') {
                        // For MySQL
                        $dsn = "mysql:host={$_POST['db_host']};port={$_POST['db_port']};dbname={$_POST['db_name']}";
                        $pdo = new PDO($dsn, $_POST['db_user'], $_POST['db_pass']);
                        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                        
                        // Save database configuration for MySQL
                        $envContent = "DATABASE_URL=mysql://{$_POST['db_user']}:{$_POST['db_pass']}@{$_POST['db_host']}:{$_POST['db_port']}/{$_POST['db_name']}\n";
                        $envContent .= "DB_TYPE=mysql\n";
                        file_put_contents('.env', $envContent);
                    } else {
                        // For PostgreSQL
                        $dsn = "pgsql:host={$_POST['db_host']};port={$_POST['db_port']};dbname={$_POST['db_name']}";
                        $pdo = new PDO($dsn, $_POST['db_user'], $_POST['db_pass']);
                        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                        
                        // Save database configuration for PostgreSQL
                        $envContent = "DATABASE_URL=postgres://{$_POST['db_user']}:{$_POST['db_pass']}@{$_POST['db_host']}:{$_POST['db_port']}/{$_POST['db_name']}\n";
                        $envContent .= "DB_TYPE=postgres\n";
                        file_put_contents('.env', $envContent);
                    }
                    
                    $step = 3;
                } catch (PDOException $e) {
                    $dbError = "Database connection failed: " . $e->getMessage();
                }
            }
            break;
            
        case 3: // Admin account setup
            if (isset($_POST['admin_username']) && isset($_POST['admin_password']) && isset($_POST['admin_email'])) {
                // Save admin information to use in node script
                $adminConfig = [
                    'username' => $_POST['admin_username'],
                    'password' => $_POST['admin_password'],
                    'email' => $_POST['admin_email'],
                    'fullName' => $_POST['admin_fullname'] ?? 'System Administrator',
                ];
                file_put_contents('admin-config.json', json_encode($adminConfig, JSON_PRETTY_PRINT));
                
                $step = 4;
            }
            break;
            
        case 4: // Final installation
            // Run installation commands
            $output = [];
            $returnVar = 0;
            
            // Run npm install
            exec('npm install --production 2>&1', $output, $returnVar);
            
            if ($returnVar !== 0) {
                $installError = "NPM installation failed. Please check your server configuration.";
            } else {
                // Run database migrations
                exec('npm run db:push 2>&1', $output, $returnVar);
                
                if ($returnVar !== 0) {
                    $installError = "Database migration failed. Please check your database configuration.";
                } else {
                    // Create admin user
                    exec('node create-admin-from-config.js 2>&1', $output, $returnVar);
                    
                    if ($returnVar !== 0) {
                        $installError = "Admin user creation failed. Please check the logs.";
                    } else {
                        // Initialize system data
                        exec('npm run create-exchange-rate 2>&1', $output, $returnVar);
                        exec('npm run add-payment-methods 2>&1', $output, $returnVar);
                        exec('npm run create-remittance-fees 2>&1', $output, $returnVar);
                        
                        $step = 5;
                    }
                }
            }
            break;
    }
}

// Function to check PHP version
function checkPhpVersion($required) {
    return version_compare(PHP_VERSION, $required, '>=');
}

// Function to check if extension is loaded
function checkExtension($extension) {
    return extension_loaded($extension);
}

// Function to check if file/directory is writable
function checkWritable($path) {
    return is_writable($path) || is_writable(dirname($path));
}

// Function to get a clean base URL
function getBaseUrl() {
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
    $domain = $_SERVER['HTTP_HOST'];
    $path = dirname($_SERVER['REQUEST_URI']);
    return $protocol . $domain . rtrim($path, '/');
}

// Check system requirements
$systemStatus = [
    'php_version' => checkPhpVersion($requiredPhpVersion),
];

// Check required extensions
foreach ($requiredExtensions as $ext) {
    $systemStatus["ext_$ext"] = checkExtension($ext);
}

// Check database extensions - at least one must be available
$databaseExtStatus = [];
foreach ($optionalExtensions as $ext) {
    $databaseExtStatus["ext_$ext"] = checkExtension($ext);
}
$systemStatus['database_ext'] = in_array(true, $databaseExtStatus, true);

// Check writeable directories
$systemStatus['writable_env'] = checkWritable('.env');
$systemStatus['writable_public'] = checkWritable('public');
$systemStatus['writable_server'] = checkWritable('server');

$allRequirementsMet = !in_array(false, $systemStatus, true);

// Get base URL for links
$baseUrl = getBaseUrl();

// Page header and basic styling
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $appName; ?> Installer</title>
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
            width: 18%;
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
        .success {
            color: var(--success);
        }
        .error {
            color: var(--danger);
        }
        .warning {
            color: var(--warning);
        }
        .check-item {
            margin-bottom: 10px;
            display: flex;
            align-items: center;
        }
        .check-icon {
            margin-right: 10px;
            font-weight: bold;
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
        input[type="password"],
        input[type="email"],
        input[type="number"] {
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
        .btn-secondary {
            background-color: var(--gray-dark);
        }
        .btn-secondary:hover {
            background-color: #1f2937;
        }
        .alert {
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .alert-error {
            background-color: #fee2e2;
            color: var(--danger);
            border: 1px solid #fecaca;
        }
        .alert-success {
            background-color: #dcfce7;
            color: var(--success);
            border: 1px solid #bbf7d0;
        }
        .alert-warning {
            background-color: #fff7ed;
            color: var(--warning);
            border: 1px solid #fed7aa;
        }
        .btn-container {
            display: flex;
            justify-content: space-between;
            margin-top: 30px;
        }
        code {
            background-color: var(--gray-light);
            padding: 2px 5px;
            border-radius: 3px;
            font-family: monospace;
        }
        .help-text {
            font-size: 14px;
            color: var(--gray-dark);
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1><?php echo $appName; ?> Installer</h1>
        
        <div class="steps">
            <div class="step <?php echo $step >= 1 ? 'active' : ''; ?> <?php echo $step > 1 ? 'completed' : ''; ?>">
                <div class="step-number">1</div>
                <div class="step-label">Requirements</div>
            </div>
            <div class="step <?php echo $step >= 2 ? 'active' : ''; ?> <?php echo $step > 2 ? 'completed' : ''; ?>">
                <div class="step-number">2</div>
                <div class="step-label">Database</div>
            </div>
            <div class="step <?php echo $step >= 3 ? 'active' : ''; ?> <?php echo $step > 3 ? 'completed' : ''; ?>">
                <div class="step-number">3</div>
                <div class="step-label">Admin Account</div>
            </div>
            <div class="step <?php echo $step >= 4 ? 'active' : ''; ?> <?php echo $step > 4 ? 'completed' : ''; ?>">
                <div class="step-number">4</div>
                <div class="step-label">Installation</div>
            </div>
            <div class="step <?php echo $step >= 5 ? 'active' : ''; ?>">
                <div class="step-number">5</div>
                <div class="step-label">Complete</div>
            </div>
        </div>
        
        <?php if ($step === 1): // System Requirements Check ?>
            <h2>System Requirements Check</h2>
            <p>The installer will check if your server meets the requirements for running <?php echo $appName; ?>.</p>
            
            <?php if (isset($_GET['check']) && !$allRequirementsMet): ?>
                <div class="alert alert-error">
                    <strong>Warning:</strong> Some system requirements are not met. The application may not function correctly.
                </div>
            <?php endif; ?>
            
            <div class="check-item">
                <div class="check-icon"><?php echo $systemStatus['php_version'] ? '✓' : '✗'; ?></div>
                <div>
                    PHP Version >= <?php echo $requiredPhpVersion; ?>
                    <div class="help-text">
                        Current version: <?php echo PHP_VERSION; ?>
                        <?php if (!$systemStatus['php_version']): ?>
                            <span class="error">Your PHP version is too old. Please upgrade to PHP <?php echo $requiredPhpVersion; ?> or newer.</span>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
            
            <?php foreach ($requiredExtensions as $ext): ?>
                <div class="check-item">
                    <div class="check-icon"><?php echo $systemStatus["ext_$ext"] ? '✓' : '✗'; ?></div>
                    <div>
                        PHP Extension: <?php echo $ext; ?>
                        <?php if (!$systemStatus["ext_$ext"]): ?>
                            <div class="help-text error">The <?php echo $ext; ?> extension is not installed or enabled.</div>
                        <?php endif; ?>
                    </div>
                </div>
            <?php endforeach; ?>
            
            <!-- Database Extensions Check -->
            <div class="check-item">
                <div class="check-icon"><?php echo $systemStatus['database_ext'] ? '✓' : '✗'; ?></div>
                <div>
                    Database Extensions
                    <?php if ($systemStatus['database_ext']): ?>
                        <div class="help-text">
                            Available database extensions:
                            <?php foreach ($optionalExtensions as $ext): ?>
                                <?php if ($databaseExtStatus["ext_$ext"]): ?>
                                    <span class="success"><?php echo $ext; ?></span><?php echo $ext !== end($optionalExtensions) ? ', ' : ''; ?>
                                <?php endif; ?>
                            <?php endforeach; ?>
                        </div>
                    <?php else: ?>
                        <div class="help-text error">No database extension is installed. You need at least one of these: <?php echo implode(', ', $optionalExtensions); ?></div>
                    <?php endif; ?>
                </div>
            </div>
            
            <div class="check-item">
                <div class="check-icon"><?php echo $systemStatus['writable_env'] ? '✓' : '✗'; ?></div>
                <div>
                    Writable .env file
                    <?php if (!$systemStatus['writable_env']): ?>
                        <div class="help-text error">The .env file or its parent directory is not writable.</div>
                    <?php endif; ?>
                </div>
            </div>
            
            <div class="check-item">
                <div class="check-icon"><?php echo $systemStatus['writable_public'] ? '✓' : '✗'; ?></div>
                <div>
                    Writable public directory
                    <?php if (!$systemStatus['writable_public']): ?>
                        <div class="help-text error">The public directory is not writable.</div>
                    <?php endif; ?>
                </div>
            </div>
            
            <div class="check-item">
                <div class="check-icon"><?php echo $systemStatus['writable_server'] ? '✓' : '✗'; ?></div>
                <div>
                    Writable server directory
                    <?php if (!$systemStatus['writable_server']): ?>
                        <div class="help-text error">The server directory is not writable.</div>
                    <?php endif; ?>
                </div>
            </div>
            
            <form method="post" action="?step=1">
                <div class="btn-container">
                    <div></div> <!-- Empty div for alignment -->
                    <div>
                        <?php if (!$allRequirementsMet): ?>
                            <a href="?step=1&check=1" class="btn-secondary" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--gray-dark); color: white; border-radius: 4px;">Recheck Requirements</a>
                        <?php endif; ?>
                        <button type="submit" <?php echo !$allRequirementsMet ? 'onclick="return confirm(\'Some requirements are not met. The application may not work correctly. Do you want to continue anyway?\');"' : ''; ?>>
                            Continue to Database Setup
                        </button>
                    </div>
                </div>
            </form>
        
        <?php elseif ($step === 2): // Database Setup ?>
            <h2>Database Configuration</h2>
            <p>Please enter your database credentials. The database must already exist.</p>
            <div class="alert alert-info" style="background-color: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd;">
                <strong>Info:</strong> For shared hosting environments, MySQL is recommended and selected by default. PostgreSQL is also supported if your hosting provider offers it.
            </div>
            
            <?php if (isset($dbError)): ?>
                <div class="alert alert-error">
                    <?php echo $dbError; ?>
                </div>
            <?php endif; ?>
            
            <form method="post" action="?step=2">
                <div class="form-group">
                    <label for="db_type">Database Type</label>
                    <select id="db_type" name="db_type" style="width: 100%; padding: 10px; border: 1px solid var(--gray); border-radius: 4px; box-sizing: border-box;" onchange="updatePortValue(this.value)">
                        <option value="mysql" <?php echo (isset($_POST['db_type']) && $_POST['db_type'] === 'mysql') ? 'selected' : ''; ?>>MySQL (Recommended for shared hosting)</option>
                        <option value="postgres" <?php echo (isset($_POST['db_type']) && $_POST['db_type'] === 'postgres') ? 'selected' : ''; ?>>PostgreSQL</option>
                    </select>
                    <div class="help-text">Select the database type provided by your hosting company</div>
                </div>
                
                <div class="form-group">
                    <label for="db_host">Database Host</label>
                    <input type="text" id="db_host" name="db_host" value="<?php echo $_POST['db_host'] ?? 'localhost'; ?>" required>
                    <div class="help-text">Usually 'localhost' or a remote server URL</div>
                </div>
                
                <div class="form-group">
                    <label for="db_port">Database Port</label>
                    <input type="number" id="db_port" name="db_port" value="<?php echo $_POST['db_port'] ?? ((isset($_POST['db_type']) && $_POST['db_type'] === 'mysql') ? '3306' : '5432'); ?>" required>
                    <div class="help-text">Default ports: MySQL = 3306, PostgreSQL = 5432</div>
                </div>
                
                <script>
                function updatePortValue(dbType) {
                    const portInput = document.getElementById('db_port');
                    if (dbType === 'mysql') {
                        portInput.value = '3306';
                    } else {
                        portInput.value = '5432';
                    }
                }
                </script>
                
                <div class="form-group">
                    <label for="db_name">Database Name</label>
                    <input type="text" id="db_name" name="db_name" value="<?php echo $_POST['db_name'] ?? ''; ?>" required>
                    <div class="help-text">The database must already exist</div>
                </div>
                
                <div class="form-group">
                    <label for="db_user">Database Username</label>
                    <input type="text" id="db_user" name="db_user" value="<?php echo $_POST['db_user'] ?? ''; ?>" required>
                </div>
                
                <div class="form-group">
                    <label for="db_pass">Database Password</label>
                    <input type="password" id="db_pass" name="db_pass" value="<?php echo $_POST['db_pass'] ?? ''; ?>" required>
                </div>
                
                <div class="btn-container">
                    <a href="?step=1" class="btn-secondary" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--gray-dark); color: white; border-radius: 4px;">Previous</a>
                    <button type="submit">Continue to Admin Setup</button>
                </div>
            </form>
        
        <?php elseif ($step === 3): // Admin Account Setup ?>
            <h2>Admin Account Setup</h2>
            <p>Create the administrator account for your <?php echo $appName; ?> installation.</p>
            
            <form method="post" action="?step=3">
                <div class="form-group">
                    <label for="admin_username">Admin Username</label>
                    <input type="text" id="admin_username" name="admin_username" value="<?php echo $_POST['admin_username'] ?? 'admin'; ?>" required>
                </div>
                
                <div class="form-group">
                    <label for="admin_password">Admin Password</label>
                    <input type="password" id="admin_password" name="admin_password" value="<?php echo $_POST['admin_password'] ?? ''; ?>" required>
                    <div class="help-text">Use a strong password with at least 8 characters</div>
                </div>
                
                <div class="form-group">
                    <label for="admin_email">Admin Email</label>
                    <input type="email" id="admin_email" name="admin_email" value="<?php echo $_POST['admin_email'] ?? ''; ?>" required>
                </div>
                
                <div class="form-group">
                    <label for="admin_fullname">Admin Full Name</label>
                    <input type="text" id="admin_fullname" name="admin_fullname" value="<?php echo $_POST['admin_fullname'] ?? 'System Administrator'; ?>">
                </div>
                
                <div class="btn-container">
                    <a href="?step=2" class="btn-secondary" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--gray-dark); color: white; border-radius: 4px;">Previous</a>
                    <button type="submit">Continue to Installation</button>
                </div>
            </form>
        
        <?php elseif ($step === 4): // Installation ?>
            <h2>Installing <?php echo $appName; ?></h2>
            <p>The system will now install the application. This may take a few minutes.</p>
            
            <?php if (isset($installError)): ?>
                <div class="alert alert-error">
                    <?php echo $installError; ?>
                </div>
                <div>
                    <pre><?php echo implode("\n", $output); ?></pre>
                </div>
                <div class="btn-container">
                    <a href="?step=3" class="btn-secondary" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--gray-dark); color: white; border-radius: 4px;">Previous</a>
                    <a href="?step=4" class="btn-primary" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--primary); color: white; border-radius: 4px;">Try Again</a>
                </div>
            <?php else: ?>
                <div class="alert alert-warning">
                    <strong>Please wait:</strong> Installation is in progress. Please do not close this page.
                </div>
                
                <form method="post" action="?step=4">
                    <div class="btn-container">
                        <a href="?step=3" class="btn-secondary" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--gray-dark); color: white; border-radius: 4px;">Previous</a>
                        <button type="submit">Start Installation</button>
                    </div>
                </form>
            <?php endif; ?>
        
        <?php elseif ($step === 5): // Complete ?>
            <h2>Installation Complete!</h2>
            <div class="alert alert-success">
                <strong>Success!</strong> <?php echo $appName; ?> has been successfully installed.
            </div>
            
            <p>You can now access your application. Here are some important links:</p>
            
            <ul>
                <li><strong>Application URL:</strong> <a href="<?php echo $baseUrl; ?>/"><?php echo $baseUrl; ?>/</a></li>
                <li><strong>Admin login:</strong> <code><?php echo $_POST['admin_username'] ?? 'admin'; ?></code></li>
            </ul>
            
            <div class="alert alert-warning">
                <strong>Important Security Notice:</strong> For security reasons, you should delete this installer file (installer.php) after completing the installation.
            </div>
            
            <div class="btn-container">
                <div></div> <!-- Empty div for alignment -->
                <a href="<?php echo $baseUrl; ?>/" class="btn-primary" style="text-decoration: none; display: inline-block; padding: 12px 20px; background-color: var(--primary); color: white; border-radius: 4px;">Go to Application</a>
            </div>
            
            <?php
            // Delete the installer file option
            if (isset($_GET['delete']) && $_GET['delete'] === 'yes') {
                unlink(__FILE__);
                header("Location: ./");
                exit;
            }
            ?>
            
            <div style="margin-top: 30px; text-align: center;">
                <a href="?step=5&delete=yes" onclick="return confirm('Are you sure you want to delete the installer?');" style="color: var(--danger);">Delete Installer</a>
            </div>
        <?php endif; ?>
        
        <div style="margin-top: 40px; font-size: 12px; text-align: center; color: var(--gray-dark);">
            <?php echo $appName; ?> Installer v<?php echo $appVersion; ?>
        </div>
    </div>
</body>
</html>