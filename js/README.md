# Pact and Javascript

This folder contains useful scripts to communicate with Pact servers (nodes) in javascript using [pact-lang-api](https://github.com/kadena-io/pact-lang-api) library.

## Setup
Install Node >= 8.11.4
Install All Dependencies. The dependencies include Pact Lang API.
```
npm install
```

## Simple Requests
Run the following command to learn the simplest way to use the basic Pact API endpoints: `/send` `/local` `/poll` `/listen`.

Learn about the Building Pact Command (local and Exec) and the Pact Rest API [here](https://pact-language.readthedocs.io/en/latest/pact-reference.html#rest-api)

```
npm run simple
```

## Signing API
You will need to have [Chainweaver](https://www.kadena.io/chainweaver) installed and open. Learn the coolest way of signing an already built command.
```
npm run sign
```
