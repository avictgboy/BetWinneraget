import { scrypt, randomBytes } from 'crypto';
import { promisify } from 'util';
import { db } from './server/db';
import { users } from './shared/schema';
import { eq } from 'drizzle-orm';

const scryptAsync = promisify(scrypt);

async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const buf = (await scryptAsync(password, salt, 64)) as Buffer;
  return `${buf.toString("hex")}.${salt}`;
}

async function createDemoUser() {
  try {
    // Check if the demo user already exists
    const existingUser = await db.select().from(users).where(eq(users.username, 'koro'));
    
    if (existingUser.length > 0) {
      console.log('User "koro" already exists');
      return;
    }
    
    // Create a demo user with a hashed password
    const hashedPassword = await hashPassword('koro123');
    
    // Insert the demo user
    const [user] = await db.insert(users).values({
      username: 'koro',
      password: hashedPassword,
      fullName: 'Koro User',
      email: 'koro@example.com',
      phone: '+88017123456789',
      balance: '5000',
      agentId: 'SA-12345',
      promoCode: 'BETWIN12345',
    }).returning();
    
    console.log('Demo user created successfully:', user);
  } catch (error) {
    console.error('Error creating demo user:', error);
  }
}

createDemoUser();