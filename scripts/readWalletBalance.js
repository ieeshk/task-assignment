var Web3 = require("web3");
const testnet = 'https://goerli.infura.io/v3/3846354e4f0b4d3f8a52965f71e0b63c';
const walletAddress = '0xa66f9e9310374f9e9bbAf1aB5030d40A7C070489';

const web3 = new Web3(new Web3.providers.HttpProvider(testnet));

var balance = await web3.eth.getBalance(walletAddress); //Will give value in.
//balance = web3.toDecimal(balance);
console.log("balance is", balance);