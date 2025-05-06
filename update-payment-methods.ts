import { db } from "./server/db";
import { paymentMethods } from "./shared/schema";
import { eq } from "drizzle-orm";

async function updatePaymentMethods() {
  try {
    console.log("Starting payment methods update...");

    // 1. Remove the existing Binance Pay and Custom USDT methods
    await db.delete(paymentMethods)
      .where(eq(paymentMethods.type, "binance_pay"));
    console.log("Deleted binance_pay payment method");
    
    await db.delete(paymentMethods)
      .where(eq(paymentMethods.type, "custom_usdt"));
    console.log("Deleted custom_usdt payment method");

    // 2. Add Payment Methods for Agent Topup 
    // Check if bKash payment method already exists for agent topup
    const existingBkash = await db.query.paymentMethods.findFirst({
      where: (methods, { and, eq }) => and(
        eq(methods.type, "bkash"),
        eq(methods.purpose, "agent_topup")
      )
    });

    // Add bKash for agent topup if it doesn't exist
    if (!existingBkash) {
      await db.insert(paymentMethods).values({
        type: "bkash",
        name: "bKash",
        details: {
          accountNumber: "01712345678",
          instructions: "Send money to this number and provide the Transaction ID"
        },
        purpose: "agent_topup",
        active: true
      });
      console.log("Added bKash payment method for agent topup");
    } else {
      console.log("bKash payment method for agent topup already exists");
    }

    // Check if Nagad payment method already exists for agent topup
    const existingNagad = await db.query.paymentMethods.findFirst({
      where: (methods, { and, eq }) => and(
        eq(methods.type, "nagad"),
        eq(methods.purpose, "agent_topup")
      )
    });

    // Add Nagad for agent topup if it doesn't exist
    if (!existingNagad) {
      await db.insert(paymentMethods).values({
        type: "nagad",
        name: "Nagad",
        details: {
          accountNumber: "01712345678",
          instructions: "Send money to this number and provide the Transaction ID"
        },
        purpose: "agent_topup",
        active: true
      });
      console.log("Added Nagad payment method for agent topup");
    } else {
      console.log("Nagad payment method for agent topup already exists");
    }

    // Check if Rocket payment method already exists for agent topup
    const existingRocket = await db.query.paymentMethods.findFirst({
      where: (methods, { and, eq }) => and(
        eq(methods.type, "rocket"),
        eq(methods.purpose, "agent_topup")
      )
    });

    // Add Rocket for agent topup if it doesn't exist
    if (!existingRocket) {
      await db.insert(paymentMethods).values({
        type: "rocket",
        name: "Rocket",
        details: {
          accountNumber: "01712345678",
          instructions: "Send money to this number and provide the Transaction ID"
        },
        purpose: "agent_topup",
        active: true
      });
      console.log("Added Rocket payment method for agent topup");
    } else {
      console.log("Rocket payment method for agent topup already exists");
    }

    // Check if Bank Transfer payment method already exists for agent topup
    const existingBankTransfer = await db.query.paymentMethods.findFirst({
      where: (methods, { and, eq }) => and(
        eq(methods.type, "bank_transfer"),
        eq(methods.purpose, "agent_topup")
      )
    });

    // Add Bank Transfer for agent topup if it doesn't exist
    if (!existingBankTransfer) {
      await db.insert(paymentMethods).values({
        type: "bank_transfer",
        name: "Bank Transfer",
        details: {
          bankName: "Bangladesh Bank",
          accountName: "BetWinner Ltd",
          accountNumber: "1234-5678-9012",
          branch: "Dhaka Main Branch"
        },
        purpose: "agent_topup",
        active: true
      });
      console.log("Added Bank Transfer payment method for agent topup");
    } else {
      console.log("Bank Transfer payment method for agent topup already exists");
    }

    console.log("Payment methods updated successfully");
    process.exit(0);
  } catch (error) {
    console.error("Error updating payment methods:", error);
    process.exit(1);
  }
}

updatePaymentMethods();