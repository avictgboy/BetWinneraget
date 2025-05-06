import { migrate } from 'drizzle-orm/postgres-js/migrator';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './shared/schema';

async function main() {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is not defined');
  }

  // Use postgres.js directly for migrations
  const migrationClient = postgres(process.env.DATABASE_URL);
  const db = drizzle(migrationClient, { schema });

  console.log('Creating remittance fee and transaction tables...');
  
  try {
    // First, check if remittance_fees table exists
    const checkRemittanceFeesTable = await migrationClient`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'remittance_fees'
      ) as exists
    `;
    
    if (!checkRemittanceFeesTable[0].exists) {
      console.log('Creating remittance_fees table...');
      await migrationClient`
        CREATE TABLE IF NOT EXISTS remittance_fees (
          id SERIAL PRIMARY KEY,
          channel TEXT NOT NULL,
          fee_type TEXT NOT NULL,
          flat_fee NUMERIC(10, 2),
          percentage_fee NUMERIC(10, 2),
          min_amount NUMERIC(10, 2),
          max_amount NUMERIC(10, 2),
          name TEXT,
          description TEXT,
          active BOOLEAN DEFAULT true,
          updated_by_id INTEGER REFERENCES users(id),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
        )
      `;
      console.log('remittance_fees table created successfully!');
    } else {
      console.log('remittance_fees table already exists.');
    }
    
    // Next, check if remittance_transactions table exists
    const checkRemittanceTransactionsTable = await migrationClient`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'remittance_transactions'
      ) as exists
    `;
    
    if (!checkRemittanceTransactionsTable[0].exists) {
      console.log('Creating remittance_transactions table...');
      await migrationClient`
        CREATE TABLE IF NOT EXISTS remittance_transactions (
          id SERIAL PRIMARY KEY,
          agent_id INTEGER NOT NULL REFERENCES users(id),
          recipient_channel TEXT NOT NULL,
          recipient_name TEXT NOT NULL,
          recipient_account TEXT NOT NULL,
          recipient_additional_info JSONB,
          amount NUMERIC(10, 2) NOT NULL,
          fee_id INTEGER REFERENCES remittance_fees(id),
          fee_amount NUMERIC(10, 2) DEFAULT 0,
          total_amount NUMERIC(10, 2) NOT NULL,
          transaction_number TEXT,
          status TEXT DEFAULT 'pending' NOT NULL,
          status_reason TEXT,
          notes TEXT,
          processed_by_id INTEGER REFERENCES users(id),
          processed_at TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
        )
      `;
      console.log('remittance_transactions table created successfully!');
    } else {
      console.log('remittance_transactions table already exists.');
    }
    
    // Check if scheduledPayout column exists in commissions table
    const checkResult = await migrationClient`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'commissions' AND column_name = 'scheduled_payout'
    `;
    
    if (checkResult.length === 0) {
      await migrationClient`
        ALTER TABLE commissions 
        ADD COLUMN IF NOT EXISTS scheduled_payout TIMESTAMP
      `;
      console.log('scheduled_payout column added to commissions table!');
    } else {
      console.log('scheduled_payout column already exists, no changes needed.');
    }
  } catch (error) {
    console.error('Error during schema update:', error);
  } finally {
    await migrationClient.end();
    console.log('Migration complete.');
  }
}

main();