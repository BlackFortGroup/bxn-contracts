const utils = require('./utils.js');

const Web3 = require('web3');
const rpcURL = 'http://127.0.0.1:7545';
const web3 = new Web3(rpcURL);

contract("SaleHub", accounts => {
    it("CreationAccounts test", async function() {
        let hubs = utils.deployAllNodes();
        let system = hubs[8];
        let validator = hubs[2];
        let delegator = hubs[3];
        let node = hubs[1];

        await validator.sendTransaction({from: accounts[1], value: Web3.utils.toWei("15000", "ether")});
        await validator.sendTransaction({from: accounts[2], value: Web3.utils.toWei("25000", "ether")});

        await node.sendTransaction({from: accounts[4], value: Web3.utils.toWei("5001", "ether")});
        await node.delegate(accounts[1], 0, {from: accounts[3]});
        await node.delegate(accounts[1], 1, {from: accounts[4]});

        for (let i = 0; i < 10; i++) {
            console.log('testing', i + 1, '/', 10);
            await system.sendTransaction({from: accounts[1 + i % 2], value: Web3.utils.toWei("1", "ether")});
        }

        console.log("Validator 1:", Web3.utils.fromWei(await validator.balanceOf(accounts[1])), await validator.symbol());
        console.log("Validator 2:", Web3.utils.fromWei(await validator.balanceOf(accounts[2])), await validator.symbol());
        console.log("Delegator 3:", Web3.utils.fromWei(await delegator.balanceOf(accounts[3])), await delegator.symbol());
        console.log("Delegator 4:", Web3.utils.fromWei(await delegator.balanceOf(accounts[4])), await delegator.symbol());
        console.log("Node 3:", Web3.utils.fromWei(await node.availableBalanceOf(accounts[3])), await node.symbol());
        console.log("Node 4:", Web3.utils.fromWei(await node.availableBalanceOf(accounts[4])), await node.symbol());

        await node.sendTransaction({from: accounts[5], value: Web3.utils.toWei("10001", "ether")});
        await node.delegate(accounts[1], 2, {from: accounts[5]});

        for (let i = 0; i < 10; i++) {
            console.log('testing', i + 1, '/', 10);
            await system.sendTransaction({from: accounts[1 + i % 2], value: Web3.utils.toWei("1", "ether")});
        }

        console.log("Validator 1:", Web3.utils.fromWei(await validator.balanceOf(accounts[1])), await validator.symbol());
        console.log("Validator 2:", Web3.utils.fromWei(await validator.balanceOf(accounts[2])), await validator.symbol());
        console.log("Delegator 3:", Web3.utils.fromWei(await delegator.balanceOf(accounts[3])), await delegator.symbol());
        console.log("Delegator 4:", Web3.utils.fromWei(await delegator.balanceOf(accounts[4])), await delegator.symbol());
        console.log("Delegator 5:", Web3.utils.fromWei(await delegator.balanceOf(accounts[5])), await delegator.symbol());
        console.log("Node 3:", Web3.utils.fromWei(await node.availableBalanceOf(accounts[3])), await node.symbol());
        console.log("Node 4:", Web3.utils.fromWei(await node.availableBalanceOf(accounts[4])), await node.symbol());
        console.log("Node 5:", Web3.utils.fromWei(await node.availableBalanceOf(accounts[5])), await node.symbol());
    });
})