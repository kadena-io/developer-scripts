const readline = require('readline');

const rl = readline.createInterface({
  input : process.stdin,
  output : process.stdout
});

const question = (theQuestion) => {
  return new Promise(resolve => rl.question(theQuestion, answ => resolve(answ)))
}

const exitMessage = (msg) => {
  console.log("\nEXITING... ", msg)
  process.exit()
}

module.exports = {
  question: question,
  exitMessage: exitMessage
}
