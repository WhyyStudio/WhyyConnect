# Nearby Sharing System

## Overview
The Nearby Sharing system replaces NFC functionality with a PIN-based card sharing mechanism that uses Firestore for secure data transmission.

## How It Works

### Sharing a Card
1. User taps "Nearby" button on their card
2. System generates a unique 6-digit PIN
3. PIN is displayed with copy functionality
4. Card data is stored in Firestore with 1-hour expiration
5. User shares PIN with recipient

### Receiving a Card
1. User taps "Receive Card" in wallet
2. Enters the 6-digit PIN provided by sender
3. System validates PIN and retrieves card data
4. Card is saved to user's wallet with sharing metadata
5. Original sharing session tracks the receipt

### Card Synchronization
- When original cards are edited, all shared copies update automatically
- When original cards are deleted, shared copies are marked as deleted
- Users always have the latest version of shared cards

## Security Features
- **Time-Limited PINs**: Expire after 1 hour automatically
- **Unique PINs**: 6-digit codes prevent conflicts
- **User Tracking**: Prevents duplicate card receipts
- **Secure Storage**: All data stored in Firestore with proper permissions

## Firestore Collections

### `card_sharing/{pin}`
Stores active sharing sessions with:
- `pin`: 6-digit sharing code
- `cardData`: Complete card information
- `sharedBy`: User ID of the sharer
- `createdAt`: Timestamp when sharing started
- `expiresAt`: Timestamp when PIN expires (1 hour)
- `isActive`: Boolean flag for session status
- `receivedBy`: Array of user IDs who received the card

### `users/{userId}/received_cards/{cardId}`
Stores cards received by users with:
- All original card data
- `sharedBy`: User ID of original sharer
- `sharedByName`: Display name of sharer
- `receivedAt`: Timestamp when card was received
- `sharingPIN`: Original PIN used for sharing
- `cardType`: Marked as 'shared'
- `originalCardId`: Reference to original card

### `cards/{cardId}` (Top-level collection)
Stores user cards with:
- `userId`: User ID of the card owner
- All card data (name, company, contact info, etc.)
- `cardType`: Type of card (Business, Social, Email)
- `cardColor`: Visual theme of the card
- `createdAt`: Timestamp when card was created
- `updatedAt`: Timestamp when card was last updated

### `connections/{connectionId}` (Top-level collection)
Stores user connections with:
- `userId`: User ID of the connection owner
- Connection data and metadata

## Analytics
The system tracks:
- Cards shared by user
- Cards received by user
- Total shares across all cards
- Recent sharing activity

## Firestore Rules
Comprehensive security rules ensure:
- Users can only access their own data
- Sharing sessions are properly secured
- Card data is protected during transmission
- Proper validation of all operations

## Deployment
Firestore rules and indexes are automatically deployed via Firebase CLI:
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```
