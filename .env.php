<?php
// No direct access
if (!defined('SECURE_ACCESS')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

// Database settings
putenv('DB_TYPE=mysql');
putenv('DATABASE_URL=mysql://avidey36_admin:avidey36_admin@localhost:3306/avidey36_admin');

// Application settings
putenv('NODE_ENV=production');
