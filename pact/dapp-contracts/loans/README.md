# Manage Loans

This contract is designed to manage loans between multiple entities.
The main features of the loans contract is the following:
- Create and initiate a loan
- Assign a loan
- Sell a loan to a different entity
## Governance
The contract is governed by a keyset, "loans-admin-keyset"

Learn more about Pact keysets [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#keysets-and-authorization)

## Tables
The contract contains 3 tables with following schema:
- **loans-table**: `loanName` `entityName` `loanAmount` `status`
- **loan-history-table**: `loanId` `buyer` `seller` `amount`
- **loan-inventory-table**: `balance`

Learn more about Pact tables [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#deftable)

## Functions

### create-loan
  - Creates a loan with the parameters: `loanId` `loanName` `entityName` `loanAmount`
  - Inserts the loan into `loans-table` and `loan-history-table` with status `INITIATED`
  ```
  (create-loan	"C30231G102-1" "C30231G102" "Exxon Mobil"	100000)
  ```

### assign-a-loan
- Assign a loan with parameter : `txid` `loanId` `buyer` `amount`
- Inserts the assignment of the loan into `loan-history-table` and update the balance into the `loan-inventory-table`.
- Updates the status of loan to `assigned`
  ```
  (assign-loan "TX_0" "C30231G102-1" "Exxon Mobil" 4000)
  ```

### sell-a-loan
  - Sell a loan with the parameters: `txid` `loanId` `buyer` `seller` `amount`
  - Insert the transaction into `loans-history` and update the balance on `loans-inventory-table`
  ```
  (sell-loan "TX_1" "C30231G102-1" "McKesson" "Exxon Mobil" 2000)
  ```

Learn more about Pact functions [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#defun)


## Demo
Take a look at detailed description about the project [here](https://pactlang.org/beginner/project-loans)
