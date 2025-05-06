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

async function createUsers() {
  try {
    // Create a demo agent user
    const demoExists = await db.select().from(users).where(eq(users.username, 'demo'));
    
    if (demoExists.length === 0) {
      // Demo agent doesn't exist yet, create it
      const demoHashedPassword = await hashPassword('demo123');
      
      const [demoUser] = await db.insert(users).values({
        username: 'demo',
        password: demoHashedPassword,
        fullName: 'Demo Agent',
        email: 'demo@example.com',
        phone: '+88017123456789',
        balance: '5000',
        agentId: 'SA-12345',
        promoCode: 'BETWIN12345',
        role: 'agent'
      }).returning();
      
      console.log('Demo agent created successfully:', demoUser);
    } else {
      // Demo agent exists, update the password to match our known value
      const demoHashedPassword = await hashPassword('demo123');
      
      const [updatedDemo] = await db.update(users)
        .set({ password: demoHashedPassword })
        .where(eq(users.username, 'demo'))
        .returning();
      
      console.log('Demo agent password updated:', updatedDemo);
    }
    
    // Create an admin user
    const adminExists = await db.select().from(users).where(eq(users.username, 'admin'));
    
    if (adminExists.length === 0) {
      // Admin doesn't exist yet, create it
      const adminHashedPassword = await hashPassword('admin123');
      
      const [adminUser] = await db.insert(users).values({
        username: 'admin',
        password: adminHashedPassword,
        fullName: 'Admin User',
        email: 'admin@example.com',
        phone: '+88017987654321',
        balance: '10000',
        agentId: 'AD-00001',
        promoCode: 'ADMIN00001',
        role: 'admin'
      }).returning();
      
      console.log('Admin user created successfully:', adminUser);
    } else {
      // Admin exists, update the password to match our known value
      const adminHashedPassword = await hashPassword('admin123');
      
      const [updatedAdmin] = await db.update(users)
        .set({ password: adminHashedPassword })
        .where(eq(users.username, 'admin'))
        .returning();
      
      console.log('Admin user password updated:', updatedAdmin);
    }
    
  } catch (error) {
    console.error('Error creating users:', error);
  }
}

// Execute the function
createUsers();