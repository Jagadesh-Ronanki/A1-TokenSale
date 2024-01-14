# TokenSale

## Overview

The `TokenSale` contract is designed to manage token sales, including presale and public sale contributions. It allows for the creation of token sales with specific parameters such as maximum cap, minimum and maximum contributions, and durations for presale and public sale phases. Contributors can participate in these sales by making contributions, and after the sale ends, they can claim their contributions in exchange for tokens.


## Usage
Install foundry, Clone the repository and run

```bash
forge build
```

### Test Script

Run the command to execute the test script

```bash
forge script InteractTokenSale
```
<Details>
<summary>Here is a step-by-step overview of the test script results</summary>

### Scenario 1:

#### Step 1: SUPRA Token Sale Creation
- A SUPRA Token sale is created with ID 1.
  - Parameters for the sale:
    - Presale Max Cap: 10 ETH
    - Presale Min Contribution: 1 ETH
    - Presale Max Contribution: 5 ETH
    - Public Max Cap: 30 ETH
    - Public Min Contribution: 1 ETH
    - Public Max Contribution: 3 ETH
  - Console output: 
  `1. SUPRA Token sale created with id: 1`

#### Step 2: Presale and Public Contribution
- User at address 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF contributes 1 ETH to the presale.
  - Presale contributions: 1 ETH
- User at another address contributes 3 ETH to the public sale.
  - Public contributions: 3 ETH
    ```
    2. SUPRA Token presale contribution: 1 ether
    3. SUPRA Token public contribution: 3 ether
    ```

#### Step 3: Sale Ended
- The sale is ended.
  - Total contributions to the sale: 4 ETH
  ```
  4. Sale Ended
  5. Total contributions to sale: 4 ether
  ```

#### Step 4: User Claims Contribution
- User at address 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF (user0) claims their contribution.
  - Total contributions to the sale after the claim: 3 ETH
  ```
  6. 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF claimed their contribution
  ```

#### Step 5: Total contributions to sale after claim
- Total contributions to the sale after the claim: 3 ETH
  ```
  7. Total contributions to sale: 3 ether
  ```

### Scenario 2:

#### Step 1: SUPRA Token Sale Creation
- A SUPRA Token sale is created with ID 2.
  - Parameters for the sale:
    - Presale Max Cap: 10 ETH
    - Presale Min Contribution: 1 ETH
    - Presale Max Contribution: 5 ETH
    - Public Max Cap: 30 ETH
    - Public Min Contribution: 1 ETH
    - Public Max Contribution: 3 ETH
  - Console output: `1. SUPRA Token sale created with id: 2`

#### Step 2: Presale Contributions (Multiple Users)
- Multiple users contribute to the presale, each with a contribution of 5 ETH.
  - Presale contributions: 0 ETH (Presale not started)
  ```
  2. SUPRA Token presale contribution: 0 ether
  ```

#### Step 3: Public Contributions (Multiple Users)
- Multiple users contribute to the public sale, each with a contribution of 3 ETH.
  - Public contributions: 3 ETH
  ```
  3. SUPRA Token public contribution: 3 ether
  ```

#### Step 4: Sale Ended
- The sale is ended.

#### Step 5: User Contributions - SUPRA Tokens Minted
- For each of the first 3 users:
  - User ETH contributions and corresponding SUPRA token balances are displayed:
    ```
    User Contributions - SUPRA tokens minted
    5 ETH -  5 SUPRA
    5 ETH -  5 SUPRA
    3 ETH -  3 SUPRA
    ```
</Details>

### Tests
```bash
forge test
```

## Design Choices

### 1. Modular Structure

The contract follows a modular structure by using OpenZeppelin's `Ownable` and `ERC20Token` contracts. This helps in separating ownership concerns and standardizing the ERC-20 token functionality.

### 2. Structured Sale Representation

The `Sale` struct is used to represent each token sale, providing a clear structure for storing relevant information such as sale parameters, contribution details, and sale durations.

### 3. Sale Phases and Modifiers

Modifiers such as `preSale`, `publicSale`, and `saleEnded` are used to control access to specific functions based on the current phase of the sale. This ensures that contributors can only participate or claim their contributions during the appropriate phases.

### 4. Contribution Tracking

User contributions are tracked using mapping structures (`userContributions`, `userPresales`, and `userPublicSales`). This allows for efficient retrieval of contribution information for each user and sale.

### 5. Token Minting

Tokens are minted to contributors upon successful contribution, and the distribution is managed through the `_distributeTokens` internal function. This ensures that contributors receive their tokens in exchange for their contributions.

### 6. Event Logging

Events are used to log key actions within the contract, providing transparency and facilitating external monitoring of contract activities.

## Security Considerations

### 1. Reentrancy Protection

The contract uses the check-effects-interactions pattern to protect against reentrancy attacks. The critical state changes are performed before any external calls, reducing the risk of reentrancy vulnerabilities.

### 2. Access Control

The use of the `Ownable` contract ensures that only the owner can create new token sales and distribute tokens. This mitigates the risk of unauthorized modifications to the contract's configuration.

### 3. Contribution Validation

Contributions are validated to ensure they meet the specified criteria, such as minimum and maximum contribution limits. This helps prevent invalid or malicious contributions.

### 4. Token Approval

The contract approves itself to spend an unlimited amount of tokens on behalf of contributors. This is a common practice in token sale contracts to allow seamless token transfers during the contribution process.