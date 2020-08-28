# Stablecoin
This contract is an example of stablecoin implementation in Pact.


## Governance
The contract is governed by a capability, "GOVERNANCE". The capability is guarded by the guard of the coin account, `my-token-admin`.

Learn more about Module Governance [here](https://pact-language.readthedocs.io/en/stable/pact-reference.html#generalized-module-governance)

## Tables
The contract contains a token table to track the guard and balance of the user.
- **token-table** : `balance` `guard`

Learn more about Pact tables [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#deftable)

## Functions

### mint
  - Mints my-token as an operator: `accountId` `amount` `guard`
```
(mint `operator` 1.0 (read-keyset 'op-keyset))
```  

### burn
  - Burn my-token as an operator: `accountId` `amount`
```
(burn `operator` 1.0 )
```  

### create-account
- Create a new account of my-token: `account` `guard`
- Fails if account already exists
```
(create-account "sender00" (read-keyset "sender00-guard"))
```

### transfer
- transfers `amount` of my-token from `sender` to `receiver`: `sender` `receiver` `amount`
- Fails if `receiver` does not exist
- This function is an implementation of the interface, [fungible-v1](https://github.com/kadena-io/chainweb-node/blob/master/pact/coin-contract/fungible-v1.pact). Learn more about Pact interface [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#interfaces)

```
(transfer "sender00" "sender01" 0.001)
```

### transfer-create
- transfers `amount` of my-token from `sender` to `receiver`: `sender` `receiver` `receiver-guard` `amount`
- If `receiver` does not exist, creates a new account with `receiver-guard`
- This function is an implementation of the interface, [fungible-v1](https://github.com/kadena-io/chainweb-node/blob/master/pact/coin-contract/fungible-v1.pact). Learn more about Pact interface [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#interfaces)

```
(transfer-create "sender00" "sender11" (read-keyset 'sender11-keyset) 1.0)
```

Learn more about Pact functions [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#defun)

### transfer-crosschain
- Transfers `amount` of  my-token from `sender` to a `receiver` on a `target-chain`: `sender` `receiver` `receiver-guard` `target-chain` `amount`
- If `receiver` does not exist, creates a new account with `receiver-guard`
- This function is an implementation of the interface, [fungible-v1](https://github.com/kadena-io/chainweb-node/blob/master/pact/coin-contract/fungible-v1.pact). Learn more about Pact interface [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#interfaces)

```
(transfer-crosschain "sender00" "sender01" "10" 1.0)
```

### rotate
- Rotates the account guard: `account`

```
(rotate "sender00" (read-keyset 'my-new-keyset))
```

### get-balance
- Returns the balance of my-token on `account` : `account`

```
(get-balance "sender00")
```

### details
- Returns the account name, guard and balance of my-token on `account` : `account`

```
(details "sender00")
```
