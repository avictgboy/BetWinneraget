/**
 * Database Connection Test Utility
 * 
 * This script can be used to test database connections in different environments,
 * including shared hosting where connection parameters may be different.
 * 
 * Usage: 
 * - Configure your DATABASE_URL in .env file or set environment variable
 * - Run with: npm run tsx database-connection-test.ts
 * 
 * For MySQL on shared hosting: 
 * - Set DB_TYPE=mysql in your environment
 * - DATABASE_URL format: mysql://username:password@hostname:port/database
 */

import { Pool as PgPool } from '@neondatabase/serverless';
import mysql from 'mysql2/promise';

// Check if DATABASE_URL is provided
if (!process.env.DATABASE_URL) {
  console.error('❌ ERROR: DATABASE_URL environment variable is not set');
  console.log('Please provide a database connection string in the format:');
  console.log('  - For PostgreSQL: postgres://username:password@hostname:port/database');
  console.log('  - For MySQL: mysql://username:password@hostname:port/database');
  process.exit(1);
}

// Parse connection details for diagnostics
function parseDbUrl(url: string) {
  try {
    // Simple parsing for displaying host and port
    const dbUrlRegex = /([^:]+):\/\/([^:]+)(:[^@]+)?@([^:]+)(:([0-9]+))?\/([^?]+)(\?.*)?/;
    const matches = url.match(dbUrlRegex);
    
    if (matches) {
      const protocol = matches[1];
      const username = matches[2];
      const host = matches[4];
      const port = matches[6] || (protocol === 'mysql' ? '3306' : '5432');
      const database = matches[7];
      const params = matches[8] || '';
      
      return { protocol, username, host, port, database, params };
    }
    return { error: 'Could not parse DATABASE_URL' };
  } catch (err) {
    return { error: 'Invalid DATABASE_URL format' };
  }
}

async function testMySQLConnection() {
  console.log('\n🔍 Testing MySQL Connection...');
  try {
    const pool = mysql.createPool(process.env.DATABASE_URL as string);
    console.log('✅ Pool created successfully');
    
    console.log('📋 Executing simple query...');
    const [rows] = await pool.query('SELECT 1 as result');
    console.log(`✅ Query successful: ${JSON.stringify(rows)}`);
    
    await pool.end();
    console.log('✅ Connection pool closed properly');
    
    return true;
  } catch (error: any) {
    console.error(`❌ MySQL Connection Error: ${error.message}`);
    console.error('\nDebug information:');
    console.error(error);
    
    return false;
  }
}

async function testPostgresConnection() {
  console.log('\n🔍 Testing PostgreSQL Connection...');
  try {
    const pool = new PgPool({ connectionString: process.env.DATABASE_URL });
    console.log('✅ Pool created successfully');
    
    console.log('📋 Executing simple query...');
    const result = await pool.query('SELECT 1 as result');
    console.log(`✅ Query successful: ${JSON.stringify(result.rows)}`);
    
    await pool.end();
    console.log('✅ Connection pool closed properly');
    
    return true;
  } catch (error: any) {
    console.error(`❌ PostgreSQL Connection Error: ${error.message}`);
    console.error('\nDebug information:');
    console.error(error);
    
    return false;
  }
}

async function testSharedHostingConnection() {
  console.log('\n🔍 Testing connection for shared hosting environment...');
  
  // Check if the DATABASE_URL has a tcp: prefix (common in some shared hosting)
  let connectionUrl = process.env.DATABASE_URL || '';
  if (connectionUrl.startsWith('tcp:')) {
    connectionUrl = connectionUrl.replace('tcp:', 'mysql:');
    console.log('⚠️ Converted tcp: prefix to mysql: for compatibility');
  }
  
  try {
    // Create connection with adjusted parameters
    const dbInfo = parseDbUrl(connectionUrl);
    if (dbInfo.error) {
      throw new Error(dbInfo.error);
    }
    
    console.log('\n📋 Connection details for shared hosting:');
    console.log(`Protocol: ${dbInfo.protocol}`);
    console.log(`Host: ${dbInfo.host}`);
    console.log(`Port: ${dbInfo.port}`);
    console.log(`Database: ${dbInfo.database}`);
    
    // For MySQL, try alternative connection options
    if (dbInfo.protocol === 'mysql') {
      const pool = mysql.createPool({
        host: dbInfo.host,
        port: parseInt(dbInfo.port),
        user: dbInfo.username,
        password: process.env.DB_PASSWORD || '', // Try separate password env var
        database: dbInfo.database,
        ssl: dbInfo.params.includes('ssl=true') ? {} : undefined,
      });
      
      console.log('✅ Alternative connection pool created');
      const [rows] = await pool.query('SELECT 1 as result');
      console.log(`✅ Alternative query successful: ${JSON.stringify(rows)}`);
      
      await pool.end();
      return true;
    }
    
    return false;
  } catch (error: any) {
    console.error(`❌ Shared Hosting Connection Error: ${error.message}`);
    console.error('\nDebug information:');
    console.error(error);
    return false;
  }
}

async function main() {
  console.log('🔌 Database Connection Test Utility');
  console.log('=====================================');
  
  // Parse and log connection details
  const dbDetails = parseDbUrl(process.env.DATABASE_URL || '');
  if (!dbDetails.error) {
    console.log('\n📋 Database connection information:');
    console.log(`Protocol: ${dbDetails.protocol}`);
    console.log(`Host: ${dbDetails.host}`);
    console.log(`Port: ${dbDetails.port}`);
    console.log(`Database: ${dbDetails.database}`);
  } else {
    console.error(`❌ Database URL parsing error: ${dbDetails.error}`);
    process.exit(1);
  }
  
  // Determine database type
  const dbType = process.env.DB_TYPE || dbDetails.protocol || 'postgres';
  console.log(`\n🔧 Database type configured as: ${dbType}`);
  
  let success = false;
  
  // Test connection based on database type
  if (dbType === 'mysql') {
    success = await testMySQLConnection();
  } else if (dbType === 'postgres' || dbType === 'postgresql') {
    success = await testPostgresConnection();
  } else {
    console.error(`❌ Unsupported database type: ${dbType}`);
    process.exit(1);
  }
  
  // If standard connection fails, try shared hosting specific options
  if (!success) {
    console.log('\n⚠️ Standard connection failed, trying shared hosting specific options...');
    success = await testSharedHostingConnection();
  }
  
  if (success) {
    console.log('\n✅ DATABASE CONNECTION TEST SUCCESSFUL!');
  } else {
    console.error('\n❌ DATABASE CONNECTION TEST FAILED!');
    console.log('\n📋 Troubleshooting tips:');
    console.log('1. Verify DATABASE_URL format is correct');
    console.log('2. Check if database server is running and accessible from this host');
    console.log('3. Verify database user has correct permissions');
    console.log('4. For shared hosting:');
    console.log('   - Check if your host allows external database connections');
    console.log('   - You may need to whitelist your IP address');
    console.log('   - Some hosts require using specific ports or connection parameters');
    console.log('5. Set DB_TYPE=mysql explicitly if using MySQL database');
    process.exit(1);
  }
}

main().catch(error => {
  console.error('Unhandled error during database connection test:', error);
  process.exit(1);
});
