import { db } from './server/db';
import { remittanceFees } from './shared/schema';

async function createRemittanceFees() {
  console.log('Creating sample remittance fees...');

  // Clear existing fees to prevent duplicates
  await db.delete(remittanceFees);

  // Sample fees for bKash
  await db.insert(remittanceFees).values({
    channel: 'bkash',
    feeType: 'flat',
    flatFee: '20',
    percentageFee: null,
    minAmount: '100',
    maxAmount: '1000',
    name: 'bKash Small Transfer',
    description: 'Fixed fee for small amount transfers to bKash',
    active: true,
  });

  await db.insert(remittanceFees).values({
    channel: 'bkash',
    feeType: 'percentage',
    flatFee: null,
    percentageFee: '1.5',
    minAmount: '1001',
    maxAmount: '25000',
    name: 'bKash Medium Transfer',
    description: 'Percentage fee for medium amount transfers to bKash',
    active: true,
  });

  await db.insert(remittanceFees).values({
    channel: 'bkash',
    feeType: 'hybrid',
    flatFee: '50',
    percentageFee: '0.8',
    minAmount: '25001',
    maxAmount: null,
    name: 'bKash Large Transfer',
    description: 'Hybrid fee for large amount transfers to bKash',
    active: true,
  });

  // Sample fees for Nagad
  await db.insert(remittanceFees).values({
    channel: 'nagad',
    feeType: 'flat',
    flatFee: '15',
    percentageFee: null,
    minAmount: '100',
    maxAmount: '1000',
    name: 'Nagad Small Transfer',
    description: 'Fixed fee for small amount transfers to Nagad',
    active: true,
  });

  await db.insert(remittanceFees).values({
    channel: 'nagad',
    feeType: 'percentage',
    flatFee: null,
    percentageFee: '1.2',
    minAmount: '1001',
    maxAmount: '25000',
    name: 'Nagad Medium Transfer',
    description: 'Percentage fee for medium amount transfers to Nagad',
    active: true,
  });

  await db.insert(remittanceFees).values({
    channel: 'nagad',
    feeType: 'hybrid',
    flatFee: '40',
    percentageFee: '0.7',
    minAmount: '25001',
    maxAmount: null,
    name: 'Nagad Large Transfer',
    description: 'Hybrid fee for large amount transfers to Nagad',
    active: true,
  });

  // Sample fees for Rocket
  await db.insert(remittanceFees).values({
    channel: 'rocket',
    feeType: 'flat',
    flatFee: '18',
    percentageFee: null,
    minAmount: '100',
    maxAmount: '1000',
    name: 'Rocket Small Transfer',
    description: 'Fixed fee for small amount transfers to Rocket',
    active: true,
  });

  await db.insert(remittanceFees).values({
    channel: 'rocket',
    feeType: 'percentage',
    flatFee: null,
    percentageFee: '1.3',
    minAmount: '1001',
    maxAmount: '25000',
    name: 'Rocket Medium Transfer',
    description: 'Percentage fee for medium amount transfers to Rocket',
    active: true,
  });

  await db.insert(remittanceFees).values({
    channel: 'rocket',
    feeType: 'hybrid',
    flatFee: '45',
    percentageFee: '0.75',
    minAmount: '25001',
    maxAmount: null,
    name: 'Rocket Large Transfer',
    description: 'Hybrid fee for large amount transfers to Rocket',
    active: true,
  });

  // Sample fees for NPSB Bank
  await db.insert(remittanceFees).values({
    channel: 'npsb_bank',
    feeType: 'flat',
    flatFee: '30',
    percentageFee: null,
    minAmount: '500',
    maxAmount: '2000',
    name: 'NPSB Small Transfer',
    description: 'Fixed fee for small amount transfers to bank account',
    active: true,
  });

  await db.insert(remittanceFees).values({
    channel: 'npsb_bank',
    feeType: 'percentage',
    flatFee: null,
    percentageFee: '1.0',
    minAmount: '2001',
    maxAmount: '50000',
    name: 'NPSB Medium Transfer',
    description: 'Percentage fee for medium amount transfers to bank account',
    active: true,
  });

  await db.insert(remittanceFees).values({
    channel: 'npsb_bank',
    feeType: 'hybrid',
    flatFee: '100',
    percentageFee: '0.5',
    minAmount: '50001',
    maxAmount: null,
    name: 'NPSB Large Transfer',
    description: 'Hybrid fee for large amount transfers to bank account',
    active: true,
  });

  // Count the number of fees
  const count = await db.select().from(remittanceFees).then(rows => rows.length);
  
  console.log(`Successfully created ${count} remittance fee structures!`);
}

createRemittanceFees()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error creating remittance fees:', err);
    process.exit(1);
  });