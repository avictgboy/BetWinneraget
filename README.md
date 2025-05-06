# BetWinner Agent Portal

A Progressive Web App for BetWinner sub-agent management, providing comprehensive USDT-to-BDT transaction processing with advanced financial tools and real-time performance tracking.

## Core Features

- **User Management**: Create and manage sub-agents with customizable permissions
- **Financial Transaction Processing**: Support for multiple payment methods
- **Player Management**: Track and manage players associated with agents
- **Commission System**: Automated commission calculations and payouts
- **Remittance System**: Fast and secure money transfer between accounts
- **Progressive Web App**: Install directly from mobile browsers
- **Real-time Notifications**: Instant alerts for transactions and approvals
- **Multi-currency Support**: USDT and BDT with configurable exchange rates
- **Comprehensive Reporting**: Transaction history and financial reports

## Technology Stack

- **Frontend**: React with TypeScript, TailwindCSS, and Shadcn UI components
- **Backend**: Express.js with TypeScript
- **Database**: PostgreSQL with Drizzle ORM
- **Authentication**: Session-based auth with Passport.js
- **Deployment**: Scripts for both dedicated servers and shared hosting

## Supported Payment Methods

- **Binance Pay**: TRC-20 USDT transfers
- **bKash**: Mobile banking in Bangladesh
- **Nagad**: Digital financial service
- **Rocket**: Mobile banking service
- **Bank Transfer**: Traditional bank transfers

## Getting Started

### Prerequisites

- Node.js v16.x or higher
- PostgreSQL v12 or higher
- npm or yarn package manager

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/betwinner-agent-portal.git
cd betwinner-agent-portal
```

2. Install dependencies
```bash
npm install
```

3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your database credentials
```

4. Run database migrations
```bash
npm run db:push
```

5. Seed the database with initial data
```bash
npm run create-admin-user
npm run create-exchange-rate
npm run add-payment-methods
npm run create-remittance-fees
```

6. Start the development server
```bash
npm run dev
```

## Deployment

For deployment instructions, see:

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - For dedicated server deployment
- [SHARED_HOSTING_GUIDE.md](SHARED_HOSTING_GUIDE.md) - For shared hosting deployment

Before deploying, go through the [PRE_DEPLOYMENT_CHECKLIST.md](PRE_DEPLOYMENT_CHECKLIST.md) to ensure your application is ready for production.

## Mobile Installation (PWA)

The application supports Progressive Web App features, allowing users to install it directly from their mobile browsers:

1. Visit the application URL on a mobile device
2. For iOS: Tap the Share button > Add to Home Screen
3. For Android: Tap the menu button > Install App

## Demo Accounts

### Admin User
- **Username**: admin
- **Password**: admin123

### Regular Agent
- **Username**: koro
- **Password**: demo123

## Support

For support, please open an issue in the repository or contact your system administrator.

## License

This project is proprietary software. Unauthorized distribution, modification, or commercial use is prohibited.
