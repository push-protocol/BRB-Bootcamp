## BRB Staking with Foundry

### Details of Staking Contract:
* Initialization Requirement: “Users must be able to initialize their staking profile.”
* Staking Tokens: “Users should be able to stake ERC20 tokens in the contract.”
* Lockup Period: “A 7-day lockup period must be enforced before users can unstake their tokens.”
* Unstaking Tokens: “Users should be able to unstake their tokens after the 7-day lockup period.”
* Fixed Reward: “Upon successful unstaking after the lockup period, users should receive a fixed reward of 100 tokens.”
* Reward Addition by Admin: “The admin should be able to add tokens to the reward pool.”



### Details on Foundry Framework
**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
