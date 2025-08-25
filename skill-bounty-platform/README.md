# Skill Bounty Platform

A decentralized skill verification and bounty platform built on the Stacks blockchain that enables users to create skill-based challenges, submit solutions, and earn reputation through community validation. The platform creates a trustless marketplace for talent verification and skill assessment using STX tokens and reputation NFTs.

## Features and Functionality

### Challenge Creation
- Create skill-based challenges across multiple categories (coding, design, writing, etc.)
- Stake STX tokens as bounty rewards for challenge completion
- Set challenge parameters including difficulty level, submission deadline, and voting period
- Define evaluation criteria and requirements for submissions

### Solution Submission
- Submit solutions to active challenges within specified timeframes
- Upload various content types depending on challenge requirements
- Track submission status and receive community feedback
- View challenge leaderboards and competing submissions

### Community Voting System
- Participate in decentralized voting on solution quality and accuracy
- Time-bounded voting periods with transparent result calculation
- Weighted voting based on voter reputation and stake in the platform
- Protection against manipulation through reputation requirements

### Reward Distribution
- Automatic distribution of staked STX tokens to winning submissions
- Proportional reward allocation for multiple winners when applicable
- Bonus reputation points for high-quality submissions
- Challenge creator reputation adjustments based on challenge quality

### Reputation System
- Earn verifiable reputation NFTs for successful challenge completion
- Skill-specific reputation tracking across different categories
- Transferable certificates that serve as proof of expertise
- Reputation decay mechanisms to maintain current skill relevance

### Marketplace Features
- Browse active challenges by category, difficulty, and reward amount
- Search and filter challenges based on skills and interests
- User profiles displaying reputation NFTs and skill verification history
- Challenge creator ratings and community feedback

## Smart Contract Overview

The platform consists of several interconnected smart contracts:

**Challenge Contract**: Manages challenge creation, parameter setting, and lifecycle management. Handles STX token staking and ensures proper challenge validation.

**Submission Contract**: Processes solution submissions, validates submission requirements, and maintains submission metadata and timestamps.

**Voting Contract**: Implements the decentralized voting mechanism with time-based periods, vote weighting, and result calculation algorithms.

**Reputation Contract**: Manages the reputation NFT system, tracks skill categories, and handles reputation point calculations and transfers.

**Reward Contract**: Automates token distribution to winners, handles escrow of staked tokens, and manages bonus reward calculations.

**Marketplace Contract**: Provides discovery functionality, user profiles, and challenge browsing capabilities with filtering and search features.

## Usage Examples

### Creating a Challenge
```clarity
(contract-call? .challenge-contract create-challenge
  u1000000 ;; 1 STX reward
  "Implement a binary search algorithm"
  u144 ;; 24 hours for submissions
  u72  ;; 12 hours for voting
  "coding")
```

### Submitting a Solution
```clarity
(contract-call? .submission-contract submit-solution
  u1 ;; challenge-id
  "https://github.com/user/solution"
  "Efficient binary search implementation with O(log n) complexity")
```

### Voting on Submissions
```clarity
(contract-call? .voting-contract cast-vote
  u1 ;; challenge-id
  u5 ;; submission-id
  u85) ;; score out of 100
```

### Claiming Rewards
```clarity
(contract-call? .reward-contract claim-reward
  u1 ;; challenge-id
  u5) ;; winning-submission-id
```

## Contributing Guidelines

We welcome contributions from developers, designers, and blockchain enthusiasts. To contribute:

1. Fork the repository and create a feature branch for your changes
2. Follow Clarity coding standards and include comprehensive comments
3. Write clear commit messages describing the purpose of your changes
4. Submit pull requests with detailed descriptions of functionality added or modified
5. Participate in code reviews and address feedback constructively

For major feature proposals or architectural changes, please open an issue for discussion before implementation. All contributions should align with the platform's goal of creating a trustless, decentralized skill verification system.

Contributors are expected to maintain code quality, follow security best practices for smart contract development, and ensure backward compatibility when possible.