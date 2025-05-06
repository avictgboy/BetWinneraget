import { db } from "./server/db";
import { paymentMethods } from "./shared/schema";

async function addPaymentMethods() {
  try {
    // Check if Binance Pay method already exists
    const existingBinancePay = await db.query.paymentMethods.findFirst({
      where: (methods, { eq }) => eq(methods.type, "binance_pay")
    });

    // Check if Custom USDT method already exists
    const existingCustomUsdt = await db.query.paymentMethods.findFirst({
      where: (methods, { eq }) => eq(methods.type, "custom_usdt")
    });

    // Add Binance Pay if it doesn't exist
    if (!existingBinancePay) {
      await db.insert(paymentMethods).values({
        type: "binance_pay",
        name: "Binance Pay",
        details: {
          walletAddress: "binance-pay-address-123456789",
          qrCode: true
        },
        purpose: "agent_topup",
        active: true
      });
      console.log("Binance Pay payment method added");
    } else {
      console.log("Binance Pay payment method already exists");
    }

    // Add Custom USDT if it doesn't exist
    if (!existingCustomUsdt) {
      await db.insert(paymentMethods).values({
        type: "custom_usdt",
        name: "Custom USDT Address",
        details: {
          supportedNetworks: ["BEP20", "TRC20", "ERC20"],
          verificationRequired: true
        },
        purpose: "agent_topup",
        active: true
      });
      console.log("Custom USDT payment method added");
    } else {
      console.log("Custom USDT payment method already exists");
    }

    console.log("Payment methods added successfully");
    process.exit(0);
  } catch (error) {
    console.error("Error adding payment methods:", error);
    process.exit(1);
  }
}

addPaymentMethods();