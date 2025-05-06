import { db } from './server/db';
import { users, players, playerTransactions, commissions } from './shared/schema';
import { eq } from 'drizzle-orm';

async function testTransaction() {
  try {
    // Test data
    const agentId = 1; // koro
    const playerId = 3; // test_player1
    const amount = 50;
    
    await db.transaction(async (tx) => {
      // Check if user exists
      const [user] = await tx.select().from(users).where(eq(users.id, agentId));
      if (!user) {
        throw new Error("Agent not found");
      }

      // Check if player exists
      const [player] = await tx.select().from(players).where(eq(players.id, playerId));
      if (!player) {
        throw new Error("Player not found");
      }

      // Check balance
      if (Number(user.balance) < amount) {
        throw new Error("Insufficient balance");
      }

      // Update user balance
      const newBalance = Number(user.balance) - amount;
      await tx.update(users)
        .set({ balance: newBalance.toString() })
        .where(eq(users.id, agentId));
        
      // Create transaction with "completed" status
      const [transaction] = await tx.insert(playerTransactions).values({
        agentId,
        playerId,
        type: "deposit",
        amount: amount.toString(),
        status: "completed",
        commissionAmount: (amount * 0.02).toString() // 2% commission on deposits
      }).returning();
      
      console.log("Transaction created:", transaction);

      // Create commission entry
      const [commission] = await tx.insert(commissions).values({
        agentId,
        playerId,
        transactionId: transaction.id,
        type: "deposit",
        amount: amount.toString(),
        commission: (amount * 0.02).toString(),
        isPaid: true
      }).returning();
      
      console.log("Commission created:", commission);

      // Update player's total deposits
      const totalDeposits = Number(player.totalDeposits || 0) + amount;
      
      await tx.update(players).set({
        totalDeposits: totalDeposits.toString(),
        // If this is the first deposit, set the firstDepositAmount
        ...(Number(player.firstDepositAmount || 0) === 0 ? { firstDepositAmount: amount.toString() } : {})
      }).where(eq(players.id, playerId));
      
      console.log("Player updated with new deposit total");
      
      console.log("Transaction completed successfully");
    });
    
  } catch (error) {
    console.error("Error in test transaction:", error);
  }
}

testTransaction();