# BLOCKDRAW - Tiny Lottery

## Overview

BLOCKDRAW is a minimal deterministic lottery smart contract written in Clarity for the Stacks blockchain. It demonstrates basic lottery mechanics and contract state management for educational and demonstration purposes.

### Lifecycle

1. Participants enter by paying a fixed entry fee.
2. Each participant is recorded exactly once per round.
3. Owner triggers winner selection.
4. Winner receives the entire prize pool.
5. Contract state resets for the next round.

## Features

- **Pseudo-random winner selection** using block height.
- **No duplicate entries** per round.
- **Prize pool** equals total entries × entry fee.
- **Owner-controlled draw** and state reset.

## Contract Details

- **Entry Fee:** 1 STX (1,000,000 microSTX)
- **Minimum Participants:** 2
- **Owner:** Set at contract deployment

## Usage

### Enter the Lottery

Participants join by calling the `enter` function and sending the entry fee. Duplicate entries are prevented.

### Draw Winner

The contract owner calls `draw-winner` to select a winner and transfer the prize pool. The contract state resets for the next round.

### Read-Only Functions

- `get-participant-count`: Returns the current number of participants.
- `get-prize-pool`: Returns the current prize pool size.
- `has-user-entered`: Checks if a user has entered the current round.

## Security Notes

- Uses block height for pseudo-randomness; **not suitable for high-value production lotteries**.
- Designed for deterministic execution and demonstration.
