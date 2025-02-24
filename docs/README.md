# Auroville Connect

## Overview
Auroville Connect is a comprehensive web application designed to facilitate community engagement, communication, and collaboration within the Auroville ecosystem. The platform provides a centralized digital space for Auroville residents, volunteers, and interested parties to interact, share information, and stay connected.

## Technology Stack

### Frontend
- **Framework**: React with TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **Routing**: Custom React Router implementation
- **State Management**: Context API and custom hooks
- **Progressive Web App (PWA)**: Implemented with Service Worker

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js (implied from route structure)
- **ORM**: Prisma
- **Authentication**: JWT (JSON Web Tokens)
- **Database**: Not specified in config (likely PostgreSQL)

### Key Features
- User Authentication
- Forums
- Events Management
- Notifications
- Search Functionality
- Responsive Design
- Theme Toggle (Light/Dark Mode)

### Development Tools
- ESLint for code quality
- TypeScript for type safety
- Nodemon for server-side development
- PostCSS for CSS processing

## Architecture
The application follows a modern, modular architecture with clear separation of concerns:
- Frontend components in `src/`
- Server-side routes and logic in `server/`
- Database schema managed via Prisma in `prisma/`

## Deployment
- Configured for production deployment
- Includes Nginx configuration
- Supports PM2 process management (ecosystem.config.js)

## Purpose
Auroville Connect aims to bridge digital communication gaps within the Auroville community, providing a platform for:
- Sharing community events
- Facilitating discussions
- Connecting residents and volunteers
- Providing a centralized information hub

## Getting Started
Refer to the development guides in the `docs/development/` directory for detailed setup and contribution instructions.
