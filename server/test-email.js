#!/usr/bin/env node

import { sendVerificationEmail } from './lib/email.js';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Load environment variables
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: join(__dirname, '..', '.env') });

// Print environment variables (masking sensitive data)
console.log('Environment variables:');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('SMTP_SERVER:', process.env.SMTP_SERVER);
console.log('SMTP_PORT:', process.env.SMTP_PORT);
console.log('SMTP_USERNAME:', process.env.SMTP_USERNAME);
console.log('SMTP_PASSWORD:', process.env.SMTP_PASSWORD ? '****' : 'not set');
console.log('FRONTEND_URL:', process.env.FRONTEND_URL);
console.log('API_URL:', process.env.API_URL);

// Test email address and token
const testEmail = process.argv[2] || 'test@example.com';
const testToken = 'test-verification-token-' + Date.now();

console.log(`\nSending test verification email to: ${testEmail}`);
console.log('Test token:', testToken);

// Send test email
sendVerificationEmail(testEmail, testToken)
  .then(info => {
    console.log('\nEmail sent successfully!');
    console.log('Message ID:', info.messageId);
    console.log('Response:', info.response);
    console.log('Accepted:', info.accepted);
    console.log('Rejected:', info.rejected);
    process.exit(0);
  })
  .catch(error => {
    console.error('\nError sending email:');
    console.error('Message:', error.message);
    console.error('Code:', error.code);
    console.error('Command:', error.command);
    console.error('Response:', error.response);
    
    if (error.code === 'EAUTH') {
      console.error('\nAuthentication error. Please check your SMTP credentials.');
    } else if (error.code === 'ESOCKET') {
      console.error('\nConnection error. Please check your SMTP server and port settings.');
    } else if (error.code === 'ECONNREFUSED') {
      console.error('\nConnection refused. The SMTP server may be blocking the connection or not running.');
    }
    
    process.exit(1);
  });
