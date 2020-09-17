# Crowdfunding App

This contract is designed to create a escrow crowdfunding system using blockchain.

## Governance
The contract is governed by a keyset, "admin-keyset"

Learn more about Pact keysets [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#keysets-and-authorization)

## Tables
The contract contains a `campaigns-table` to store each campaign details, and a `fund-table` to keep track of fund invested to a campaign.
- **campaigns-table** : `title` `description` `target-raise` `current-raise` `start-date` `target-date` `ownerAccount` `guard` `status`
- **fund-table** : `campaign-title` `fundOwner` `pact-id` `escrow` `status`

Learn more about Pact tables [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#deftable)


## Functions

### create-campaign
  - Function for any user to create a new fundraising campaign: `title` `description` `ownerAccount` `target-raise` `start-date` `target-date`
  - Inserts the campaign into `campaigns-table`
```
(create-campaign
  "project1" "DESCRIPTION" "crowd-acct" 800.0
  (time "2019-08-21T12:00:00Z") (time "2019-08-26T12:00:00Z"))
```  

### fund-campaign
  - Function to fund a campaign in the table: `from` `title` `amount` `escrow`
  - A multi-step, "pacts" function to use escrow account in funding the campaign. Learn about `pacts` [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#asynchronous-transaction-automation-with-pacts).
    - Step 0: Secure amount from the user's account into designated escrow account.
    - Step 0 - rollback: Refund the amount from escrow account back to user's account.
      - Only executed if the user signs it, campaign is canceled, or failed to meet its target raise after the target date.
    - Step 1 : Transfer escrow account's funds into the campaign holder's account.
      - Only executable if campaign meets its target and succeeds..
    - Inserts the fund information into `fund-table`.

```
(fund-campaign "kate-acct" "project1" 400.0 "escrow-0")
```  


### cancel-campaign
  - Function for a campaign holder to cancel a campaign before target date: `title`
  - Updates the status of a campaign in the `campaigns-table` to `CANCELLED`
  - Lets the funds in the `funds-table` tied to the campaign to be refundable.(Step 0-rollback of [`fund-campaign`](#fund-campaign))
```
(cancel-campaign 'project1)
```  

### fail-campaign
  - Function to fail a campaign when it does not meet its target raise by target date: `title`
  - Updates the status of a campaign in the `campaigns-table` to `FAILED`
  - Can be executed by any entity if conditions meet.
  - Lets the funds in the `funds-table` tied to the campaign to be refundable. (Step 0-rollback of [`fund-campaign`](#fund-campaign))

```
(fail-campaign 'project1)
```  

### succeed-campaign
  - Function to succeed a campaign when it meets its target raise by target date: `title`
  - Updates the status of a campaign in the `campaigns-table` to `SUCCEEDED`
  - Can be executed by any entity if conditions meet.
  - Lets the funds in the `funds-table` tied to the campaign to be transferred to campaign holder's account. (Step 1 of [`fund-campaign`](#fund-campaign))

```
(fail-campaign 'project1)
```  
