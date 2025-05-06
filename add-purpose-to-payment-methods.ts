import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import ws from 'ws';
import * as schema from './shared/schema';

// Configure Neon to use the ws package for WebSocket connections
neonConfig.webSocketConstructor = ws;

async function main() {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL environment variable is not set');
  }

  console.log('Adding purpose column to payment_methods table...');
  
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const db = drizzle(pool, { schema });

  try {
    // Execute raw SQL query to add the column
    await db.execute(`
      ALTER TABLE payment_methods 
      ADD COLUMN IF NOT EXISTS purpose TEXT NOT NULL DEFAULT 'agent_topup'
    `);
    
    console.log('Successfully added purpose column to payment_methods table');
  } catch (error) {
    console.error('Error adding column:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

main()
  .then(() => console.log('Migration completed successfully'))
  .catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
  });