# BetWinner Database Troubleshooting Guide

## Common Database Connection Issues

If you're experiencing database connection issues, especially on shared hosting environments, follow this guide to diagnose and resolve common problems.

## 1. Database Connection Diagnostic Tool

We've included a diagnostic tool that helps detect database connection issues. You can run it with:

```bash
npm run tsx database-connection-test.ts
```

## 2. Common Error Messages and Solutions

### PostgreSQL Errors

#### Error: SQLSTATE[08006] Connection refused

**Symptoms:**
```
SQLSTATE[08006] [7] could not connect to server: Connection refused
Is the server running on host "localhost" (127.0.0.1) and accepting TCP/IP connections on port 5432?
```

**Possible causes and solutions:**

1. **PostgreSQL server is not running**
   - Check if PostgreSQL is installed and running on your server
   - Try starting the PostgreSQL service

2. **PostgreSQL is not configured to accept remote connections**
   - Check `postgresql.conf` and enable `listen_addresses = '*'`
   - Update `pg_hba.conf` to allow connections from your application IP

3. **Firewall is blocking connections**
   - Verify firewall settings allow connections on port 5432

4. **Incorrect connection parameters**
   - Double-check your DATABASE_URL format
   - PostgreSQL connection string should be: `postgres://username:password@hostname:port/database`

### MySQL Errors

#### Error: SQLSTATE[HY000] [1045] Access denied for user

**Symptoms:**
```
SQLSTATE[HY000] [1045] Access denied for user 'username'@'hostname' (using password: YES)
```

**Possible causes and solutions:**

1. **Incorrect username or password**
   - Verify your MySQL credentials

2. **User doesn't have permission to access from your host**
   - In MySQL console: `GRANT ALL PRIVILEGES ON database.* TO 'username'@'%';`
   - Run: `FLUSH PRIVILEGES;`

3. **Connection from remote hosts not allowed**
   - Check MySQL configuration to allow remote connections

## 3. Shared Hosting Specific Solutions

### cPanel/WHM Based Hosts

1. **Enable Remote MySQL Access**
   - In cPanel, go to "Remote MySQL"
   - Add your application's IP to the allowed list

2. **Check MySQL Hostname**
   - Use the server's hostname, not "localhost"
   - Sometimes shared hosts require using a specific hostname like: `mysql.yourdomain.com`

3. **Use Your cPanel Username as Prefix**
   - Some hosts require database names to be prefixed with your cPanel username: `cpanelusername_databasename`

### HostGator Specific

1. **Connection String Format**
   - Use: `mysql://cpanelusername_dbuser:password@hostname:3306/cpanelusername_dbname`

2. **Database Hostnames**
   - Shared hosting: Use `localhost` or `127.0.0.1`
   - Dedicated/VPS: Use the server's hostname

## 4. Switching Between PostgreSQL and MySQL

The application is designed to work with both PostgreSQL and MySQL databases. To switch:

1. **Set the DB_TYPE environment variable**
   - For PostgreSQL: `DB_TYPE=postgres`
   - For MySQL: `DB_TYPE=mysql`

2. **Update DATABASE_URL format accordingly**
   - PostgreSQL: `postgres://username:password@hostname:port/database`
   - MySQL: `mysql://username:password@hostname:port/database`

## 5. Memory Store Fallback

In case of persistent database connection issues, the application will automatically fall back to using an in-memory store in production environments. This allows basic functionality while you resolve database issues.

**Note:** The in-memory store is temporary and data will be lost when the application restarts. This is only intended as a temporary solution while you fix the database connection.

## 6. Additional Resources

- [PostgreSQL Connection Documentation](https://www.postgresql.org/docs/current/client-authentication.html)
- [MySQL Connection Documentation](https://dev.mysql.com/doc/refman/8.0/en/connection-problems.html)
- [cPanel MySQL Database Tutorials](https://docs.cpanel.net/cpanel/databases/mysql-databases/)

## 7. Contact Support

If you continue to experience issues after trying these solutions, please contact our support team with the following information:

1. The exact error message you're receiving
2. Output from the database-connection-test.ts script
3. Your hosting provider and type of hosting (shared, VPS, dedicated)
4. Any changes you've made to the database configuration
