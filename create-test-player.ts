import { db } from './server/db';
import { players } from './shared/schema';

async function createTestPlayer() {
  try {
    // Insert a test player for user ID 1 (koro)
    const [player] = await db.insert(players).values({
      username: 'test_player1',
      agentId: 1,
      firstDepositAmount: '100',
      totalDeposits: '100',
      totalWithdrawals: '0',
      isActive: true
    }).returning();
    
    console.log('Test player created successfully:', player);
    
  } catch (error) {
    console.error('Error creating test player:', error);
  }
}

createTestPlayer();