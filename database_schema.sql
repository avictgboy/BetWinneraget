-- BetWinner Database Schema SQL
-- Compatible with MySQL for shared hosting

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  fullName VARCHAR(255),
  balance VARCHAR(255) DEFAULT '0',
  role VARCHAR(50) DEFAULT 'user',
  referralCode VARCHAR(50),
  referredBy INT,
  profileImage VARCHAR(255),
  agentId VARCHAR(50),
  promoCode VARCHAR(50),
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Sessions table for auth
CREATE TABLE IF NOT EXISTS sessions (
  sid VARCHAR(255) NOT NULL PRIMARY KEY,
  sess JSON NOT NULL,
  expire TIMESTAMP(6) NOT NULL
);

-- Topup transactions table
CREATE TABLE IF NOT EXISTS topup_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  userId INT NOT NULL,
  amount VARCHAR(255) NOT NULL,
  currency VARCHAR(10) DEFAULT 'USDT',
  paymentMethod VARCHAR(50) NOT NULL,
  walletAddress VARCHAR(255),
  accountNumber VARCHAR(255),
  bankDetails TEXT,
  transactionId VARCHAR(255),
  status VARCHAR(50) DEFAULT 'pending',
  statusReason TEXT,
  processedById INT,
  processedAt TIMESTAMP NULL,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Withdrawal transactions table
CREATE TABLE IF NOT EXISTS withdrawal_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  userId INT NOT NULL,
  amount VARCHAR(255) NOT NULL,
  withdrawalMethod VARCHAR(50) NOT NULL,
  accountNumber VARCHAR(255),
  walletAddress VARCHAR(255),
  bankDetails TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  statusReason TEXT,
  processedById INT,
  processedAt TIMESTAMP NULL,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Players table
CREATE TABLE IF NOT EXISTS players (
  id INT AUTO_INCREMENT PRIMARY KEY,
  agentId INT NOT NULL,
  playerId VARCHAR(255) NOT NULL,
  playerName VARCHAR(255),
  platform VARCHAR(50),
  status VARCHAR(50) DEFAULT 'active',
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Player transactions table
CREATE TABLE IF NOT EXISTS player_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  agentId INT NOT NULL,
  playerId VARCHAR(255) NOT NULL,
  amount VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  notes TEXT,
  processedById INT,
  processedAt TIMESTAMP NULL,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Commissions table
CREATE TABLE IF NOT EXISTS commissions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  userId INT NOT NULL,
  amount VARCHAR(255) NOT NULL,
  rate VARCHAR(50),
  source VARCHAR(255),
  sourceId VARCHAR(255),
  status VARCHAR(50) DEFAULT 'pending',
  isPaid BOOLEAN DEFAULT FALSE,
  payoutDate TIMESTAMP NULL,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Support tickets table
CREATE TABLE IF NOT EXISTS support_tickets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  userId INT NOT NULL,
  subject VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'open',
  lastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Support messages table
CREATE TABLE IF NOT EXISTS support_messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ticketId INT NOT NULL,
  userId INT NOT NULL,
  message TEXT NOT NULL,
  isAdmin BOOLEAN DEFAULT FALSE,
  isRead BOOLEAN DEFAULT FALSE,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Remittance fees table
CREATE TABLE IF NOT EXISTS remittance_fees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  channel VARCHAR(50) NOT NULL,
  feeType VARCHAR(50) DEFAULT 'flat',
  flatFee VARCHAR(50) DEFAULT '0',
  percentageFee VARCHAR(50) DEFAULT '0',
  minAmount VARCHAR(50),
  maxAmount VARCHAR(50),
  description TEXT,
  active BOOLEAN DEFAULT TRUE,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Remittance transactions table
CREATE TABLE IF NOT EXISTS remittance_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  agentId INT NOT NULL,
  recipientChannel VARCHAR(50) NOT NULL,
  recipientName VARCHAR(255),
  recipientAccount VARCHAR(255) NOT NULL,
  recipientAdditionalInfo JSON,
  amount VARCHAR(50) NOT NULL,
  feeId INT,
  feeAmount VARCHAR(50) DEFAULT '0',
  totalAmount VARCHAR(50) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  statusReason TEXT,
  transactionNumber VARCHAR(255),
  notes TEXT,
  processedById INT,
  processedAt TIMESTAMP NULL,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Exchange rates table
CREATE TABLE IF NOT EXISTS exchange_rates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usdtToBdt DECIMAL(10, 2) NOT NULL DEFAULT 120.00,
  lastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedById INT
);

-- Default admin user
-- Password: admin123 (hashed)
INSERT INTO users (username, password, email, role, balance, agentId, promoCode) 
VALUES ('admin', '266b3a24624a7a9c76fc90c09f0beadab270a22bae8e8e31a2879502d48da266.41ad33e55bed5497', 'admin@example.com', 'admin', '1000', 'ADMIN001', 'BW12345');

-- Default regular user
-- Password: demo123 (hashed)
INSERT INTO users (username, password, email, role, balance, agentId, promoCode) 
VALUES ('koro', '60db9e4f74aa2c08c5aba5afa8ea16d4b89adf7fe4a6e4b800fa4a3140fc8ec3.d2dfad72ac5e492b', 'koro@example.com', 'user', '500', 'AGENT002', 'BW67890');

-- Default exchange rate
INSERT INTO exchange_rates (usdtToBdt, lastUpdated) 
VALUES (120.00, NOW());

-- Sample remittance fees
INSERT INTO remittance_fees (channel, feeType, flatFee, percentageFee, minAmount, maxAmount, description) 
VALUES 
('bkash', 'flat', '50', '0', '500', '25000', 'bKash money transfer fee'),
('nagad', 'flat', '45', '0', '500', '25000', 'Nagad money transfer fee'),
('rocket', 'flat', '45', '0', '500', '20000', 'Rocket money transfer fee'),
('npsb_bank', 'hybrid', '25', '0.5', '1000', '100000', 'NPSB bank transfer fee');
