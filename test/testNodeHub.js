const utils = require('./utils');

const web3 = require("web3");


contract("NodeHub", accounts => {
    it("check NodeHub", async function(){
        let hubs = await utils.deployAllNodes();
        let AccessControl = hubs[0];
        let Node = hubs[1];
        await utils.grantAllRoles(AccessControl, accounts[0]);
        // await Node.setBaseTokenURI("https:/0.1.1");

        await Node.sendTransaction({from: accounts[0], value: web3.utils.toWei("10000", "ether")});
        let amount = await Node.balanceOf(accounts[0]);
        console.log(amount.toString());
    });
})
