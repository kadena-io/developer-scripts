#!/usr/bin/env node

"use strict";
var fetch = require("node-fetch")
const fs = require('fs');

/**
 * Formats ExecCmd into api request object
 */
var mkReq = function(cmd) {
  return {
    headers: {
      "Content-Type": "application/json"
    },
    method: "POST",
    body: JSON.stringify(cmd)
  };
};

const signWallet = async function (pactCode, envData, sender, chainId, gasLimit, nonce){
  if (!pactCode)  throw new Error(`Pact.wallet.sign(): No Pact Code provided`);
  const cmd = {
    code: pactCode,
    data: envData,
    sender: sender,
    chainId: chainId,
    gasLimit: gasLimit,
    nonce: nonce
  }
  const res = await fetch('http://127.0.0.1:9467/v1/sign', mkReq(cmd))
  const resJSON = await res.json();
  return resJSON.body;
}

/**
 * Sends a signed Pact command to a running Pact server and retrieves tx result.
 * @param {{signedCmd: <rk:string>}} listenCmd reqest key of tx to listen.
 * @param {string} apiHost host running Pact server
 * @return {object} Request key of the tx received from pact server.
 */
const sendSigned = async function (signedCmd, apiHost) {
  const cmd = {
    "cmds": [ signedCmd ]
  }
  const txRes = await fetch(`${apiHost}/api/v1/send`, mkReq(cmd));
  const tx = await txRes.json();
  return tx;
}

const deploy = async function (code, envData, chainId){
  const cmd = await signWallet(code, envData, null, chainId, 10000);
  const reqKey = await sendSigned(cmd, "https://eu1.testnet.chainweb.com/chainweb/0.0/testnet03/chain/0/pact")
  console.log(reqKey)
}

// Add Scripts
