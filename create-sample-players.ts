import { db } from './server/db';
import { players } from './shared/schema';
import { eq } from 'drizzle-orm';

async function createSamplePlayers() {
  try {
    // Get user IDs
    const koroId = 1;  // koro user ID is 1 based on the database
    
    // We'll only create players for koro since that's the only user we have
    
    // Sample players for koro
    const koroPlayers = [
      {
        username: 'player1_koro',
        agentId: koroId,
        firstDepositAmount: '250',
        totalDeposits: '1000',
        totalWithdrawals: '500',
        isActive: true
      },
      {
        username: 'player2_koro',
        agentId: koroId,
        firstDepositAmount: '500',
        totalDeposits: '1500',
        totalWithdrawals: '700',
        isActive: true
      },
      {
        username: 'player3_koro',
        agentId: koroId,
        firstDepositAmount: '800',
        totalDeposits: '2500',
        totalWithdrawals: '1200',
        isActive: true
      }
    ];
    
    // Insert all players
    const allPlayers = [...koroPlayers];
    
    for (const player of allPlayers) {
      // Check if player already exists
      const existingPlayer = await db.select().from(players).where(eq(players.username, player.username));
      
      if (existingPlayer.length === 0) {
        const [insertedPlayer] = await db.insert(players).values(player).returning();
        console.log(`Player ${player.username} created successfully:`, insertedPlayer);
      } else {
        console.log(`Player ${player.username} already exists`);
      }
    }
    
    console.log('All sample players created successfully');
    
  } catch (error) {
    console.error('Error creating sample players:', error);
  }
}

createSamplePlayers();