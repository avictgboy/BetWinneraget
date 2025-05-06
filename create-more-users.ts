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
    // Create admin user
    const adminExists = await db.select().from(users).where(eq(users.username, 'admin'));
    
    if (adminExists.length === 0) {
      const adminPassword = await hashPassword('admin123');
      
      const [adminUser] = await db.insert(users).values({
        username: 'admin',
        password: adminPassword,
        fullName: 'Administrator',
        email: 'admin@betwinner.com',
        phone: '+88019876543210',
        balance: '10000',
        agentId: 'ADMIN-001',
        promoCode: 'ADMINCODE',
      }).returning();
      
      console.log('Admin user created successfully:', adminUser);
    } else {
      console.log('Admin user already exists');
    }
    
    // Create subagent user
    const subagentExists = await db.select().from(users).where(eq(users.username, 'subagent'));
    
    if (subagentExists.length === 0) {
      const subagentPassword = await hashPassword('subagent123');
      
      const [subagentUser] = await db.insert(users).values({
        username: 'subagent',
        password: subagentPassword,
        fullName: 'Sub Agent',
        email: 'subagent@example.com',
        phone: '+88018765432109',
        balance: '2500',
        agentId: 'SA-54321',
        promoCode: 'BETWIN54321',
      }).returning();
      
      console.log('Subagent user created successfully:', subagentUser);
    } else {
      console.log('Subagent user already exists');
    }
    
  } catch (error) {
    console.error('Error creating users:', error);
  }
}

createUsers();