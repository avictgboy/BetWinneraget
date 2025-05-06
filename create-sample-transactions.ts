import { db } from './server/db';
import { playerTransactions, commissions, players } from './shared/schema';
import { eq } from 'drizzle-orm';

async function createSampleTransactions() {
  try {
    // Sample transactions for koro's players
    const koroId = 1;  // koro user ID (ID 1 from our earlier creation)
    
    // Get koro's players
    const koroPlayers = await db.select().from(players).where(eq(players.agentId, koroId));
    
    if (koroPlayers.length === 0) {
      console.log('No players found for koro');
      return;
    }
    
    for (const player of koroPlayers) {
      try {
        // Create deposit transaction
        const depositAmount = 500;
        const depositCommissionAmount = depositAmount * 0.02; // 2% commission
        
        const [depositTx] = await db.insert(playerTransactions).values({
          agentId: koroId,
          playerId: player.id,
          type: 'deposit',
          amount: depositAmount.toString(),
          status: 'completed',
          commissionAmount: depositCommissionAmount.toString(),
          createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) // 7 days ago
        }).returning();
        
        console.log(`Deposit transaction created for ${player.username}:`, depositTx);
        
        // Create deposit commission
        const [depositCommission] = await db.insert(commissions).values({
          agentId: koroId,
          playerId: player.id,
          transactionId: depositTx.id,
          type: 'deposit',
          amount: depositAmount.toString(),
          commission: depositCommissionAmount.toString(),
          isPaid: false,
          createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) // 7 days ago
        }).returning();
        
        console.log(`Deposit commission created for ${player.username}:`, depositCommission);
        
        // Create withdrawal transaction
        const withdrawalAmount = 300;
        const withdrawalCommissionAmount = withdrawalAmount * 0.01; // 1% commission
        
        const [withdrawalTx] = await db.insert(playerTransactions).values({
          agentId: koroId,
          playerId: player.id,
          type: 'withdrawal',
          amount: withdrawalAmount.toString(),
          status: 'completed',
          commissionAmount: withdrawalCommissionAmount.toString(),
          paymentCode: 'PMT' + Math.floor(10000 + Math.random() * 90000),
          createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000) // 3 days ago
        }).returning();
        
        console.log(`Withdrawal transaction created for ${player.username}:`, withdrawalTx);
        
        // Create withdrawal commission
        const [withdrawalCommission] = await db.insert(commissions).values({
          agentId: koroId,
          playerId: player.id,
          transactionId: withdrawalTx.id,
          type: 'withdrawal',
          amount: withdrawalAmount.toString(),
          commission: withdrawalCommissionAmount.toString(),
          isPaid: false,
          createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000) // 3 days ago
        }).returning();
        
        console.log(`Withdrawal commission created for ${player.username}:`, withdrawalCommission);
      } catch (playerError) {
        console.error(`Error creating transactions for player ${player.username}:`, playerError);
        // Continue with next player
        continue;
      }
    }
    
    console.log('All sample transactions and commissions created successfully');
    
  } catch (error) {
    console.error('Error creating sample transactions:', error);
  }
}

createSampleTransactions();