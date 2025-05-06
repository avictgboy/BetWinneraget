import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function updateRecipientName() {
  try {
    console.log("Starting database schema update...");
    
    // First make sure recipientName is nullable (drop not-null constraint)
    await db.execute(sql`
      ALTER TABLE remittance_transactions 
      ALTER COLUMN recipient_name DROP NOT NULL;
    `);
    
    console.log("Successfully updated remittance_transactions schema!");
    
    process.exit(0);
  } catch (error) {
    console.error("Failed to update schema:", error);
    process.exit(1);
  }
}

updateRecipientName();