"use strict";

const Pact = require("pact-lang-api");
const { question, exitMessage } = require("../../util/util")

const sampleBuilder = (sender) => {
  if (!sender) sender = "noSender"
  return {
    pactCode: `(format "Hello" [])`,
    caps: Pact.lang.mkCap(
      //Role of the Capability
      "Sign for Gas Fee",
      //Description of the Capability
      "Capability to scope the signature for GAS fee",
      //Name of the Capability
      "coin.GAS",
      //Arguments of the Capability
      []
    ),
    sender: sender,
    chainId: 0,
    gasLimit: 600,
    nonce: "Developer Script - Signing Api"
  }
};

const apiHost = (node, networkId, chainId) => `https://${node}/chainweb/0.0/${networkId}/chain/${chainId}/pact`;

const main = async () => {

  let sender = await question("Sample Script to use Signing Api to sign a command. Please have your Chainweaver open. If you have an testnet account, type in your account. Else, type in anything.\n");
  const cmd = sampleBuilder(sender);

  console.log("Printing the Command Details...\n");
  Object.keys(cmd).forEach( key => {
    console.log(key, ": ", cmd[key]);
  })

  await question("\nSending Request to Chainweaver to sign command. Enter to Continue\n");
  let signedCmd = await Pact.wallet.sign(cmd);

  await question("\nSending Request to Chainweaver to sign command. Enter to Continue\n");
  await Pact.wallet.sendSigned(signedCmd, apiHost("us1.testnet.chainweb.com", "testnet04", "0"))
    .then(console.log)

  exitMessage("End of the script")
}

main();
