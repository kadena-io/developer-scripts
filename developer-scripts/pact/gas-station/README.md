# Gas Station

These are two types of gas stations that can be easily built on Kadena.
- Gas Guards
  - free-x-chain-gas
- Gas Payer
  - covid-gas-station

## Gas Guard
 - Gas Guards are general "guards". Coin accounts guarded by these guards will only be used for paying gas under generalized limitations.
 - Gas Guards use "guards" module.
 - "free-x-chain-gas" account is one of the gas stations built with gas guards.

## Gas Payer
  - Gas Payer are a customized "module" that will build a gas station. The module uses a gas-payer-v1 interface.
  - The gas station will be defined inside the customized module.
  - This type allows setting up a gas station for specific purpose such as "function","number of functions", "tx type", etc.
  - "covid-gas-station" account is one of the gas stations built with gas guards.

Medium Article
