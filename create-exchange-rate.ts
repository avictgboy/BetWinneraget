import { db } from './server/db';
import { exchangeRates } from './shared/schema';
import { eq, and } from 'drizzle-orm';

async function createExchangeRate() {
  try {
    // Check if the exchange rate already exists
    const existingRate = await db.select().from(exchangeRates)
      .where(
        and(
          eq(exchangeRates.fromCurrency, 'USDT'),
          eq(exchangeRates.toCurrency, 'BDT')
        )
      );
    
    if (existingRate.length > 0) {
      console.log('USDT to BDT exchange rate already exists');
      return;
    }
    
    // Create exchange rate
    const [rate] = await db.insert(exchangeRates).values({
      fromCurrency: 'USDT',
      toCurrency: 'BDT',
      rate: '120',
      source: 'manual'
    }).returning();
    
    console.log('Exchange rate created successfully:', rate);
  } catch (error) {
    console.error('Error creating exchange rate:', error);
  }
}

createExchangeRate();