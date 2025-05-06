import { db } from './server/db';
import { users, players, playerTransactions, commissions } from './shared/schema';
import { eq } from 'drizzle-orm';

async function testWithdrawal() {
  try {
    // Test data
    const agentId = 1; // koro
    const playerId = 3; // test_player1
    const amount = 25;
    const paymentCode = "TEST123";
    
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

      // Calculate commission (1% on withdrawals)
      const commissionAmount = amount * 0.01;

      // Create transaction with "completed" status
      const [transaction] = await tx.insert(playerTransactions).values({
        agentId,
        playerId,
        type: "withdrawal",
        amount: amount.toString(),
        paymentCode: paymentCode,
        status: "completed",
        commissionAmount: commissionAmount.toString()
      }).returning();
      
      console.log("Transaction created:", transaction);

      // Add commission to agent's balance
      const newBalance = Number(user.balance || 0) + commissionAmount;
      await tx.update(users)
        .set({ balance: newBalance.toString() })
        .where(eq(users.id, agentId));

      // Create commission entry
      const [commission] = await tx.insert(commissions).values({
        agentId,
        playerId,
        transactionId: transaction.id,
        type: "withdrawal",
        amount: amount.toString(),
        commission: commissionAmount.toString(),
        isPaid: true
      }).returning();
      
      console.log("Commission created:", commission);

      // Update player's total withdrawals
      const totalWithdrawals = Number(player.totalWithdrawals || 0) + amount;
      
      await tx.update(players).set({
        totalWithdrawals: totalWithdrawals.toString()
      }).where(eq(players.id, playerId));

      console.log("Player updated with new withdrawal total");
      
      console.log("Transaction completed successfully");
    });
    
  } catch (error) {
    console.error("Error in test withdrawal:", error);
  }
}

testWithdrawal();