'use strict';

const Pact = require("pact-lang-api");
const { question, exitMessage } = require("../../util/util")

const apiHost = (node, networkId, chainId) => `https://${node}/chainweb/0.0/${networkId}/chain/${chainId}/pact`;
const creationTime = () => Math.round((new Date).getTime()/1000);

const sampleBuilder = (name) => {
  if (!name) name = "Anonymous"
  return {
    keyPairs: [],
    type: "exec",
    pactCode: `(format "Hello {}" [${JSON.stringify(name)}])`,
    nonce: "Developer Script - simple",
    envData: {},
    meta: Pact.lang.mkMeta("free-x-chain-gas" , "0", 0.00000000001, 350, creationTime(), 600),
    networkId: "testnet04"
  }
};

const main = async () => {

  let name = await question("Sample Script to create Pact command and call them. What's your name?\n");
  const cmd = sampleBuilder(name);

  console.log("Printing the Command Details...\n");
  Object.keys(cmd).forEach( key => {
    console.log(key, ": ", cmd[key]);
  })

  let {keyPairs, nonce, pactCode, envData, meta, networkId} = cmd;
  await question("\nCreating Local Command. Enter to Continue\n");

  // Creates a command to send as POST to /api/local
  let localCmd = Pact.simple.exec.createLocalCommand(keyPairs, nonce, pactCode, envData, meta, networkId)
  console.log(localCmd)

  await question("\nCreating Exec Command. Enter to Continue\n")

  // Creates a command to send as POST to /api/send
  let execCmd = Pact.simple.exec.createCommand([], nonce, pactCode, envData, meta, networkId);
  console.log(execCmd)

  // Send the command to /local enpoint and retrieve preview result
  await question("\nSending request to /local endpoint to preview the result. Enter to Continue.\n")
  await Pact.fetch.local(cmd, apiHost("us1.testnet.chainweb.com", "testnet04", "0"))
    .then(console.log)

  // Send the command to /send enpoint and retrieve transaction requestKey
  await question("\nSending request to /send endpoint with the sample command. Enter to Continue.\n")
  let txRes = await Pact.fetch.send(cmd, apiHost("us1.testnet.chainweb.com", "testnet04", "0"))
  console.log(txRes)
  if (!txRes.requestKeys) exitMessage("Send Request Failed");

  // Send the command to /poll endpoint and retrieve transaction Result
  await question("\nSending request to /poll endpoint to fetch the result. Wait ~30 seconds after sending in transaction. Enter to Continue.\n")
  await Pact.fetch.poll(txRes, apiHost("us1.testnet.chainweb.com", "testnet04", "0"))
    .then(console.log)

  exitMessage("End of the script")
}

main();
