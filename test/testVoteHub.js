const utils = require('./utils');

const web3 = require("web3");


contract("VoteHub", accounts => {
    it("check VoteHub", async function(){
        let hubs = await utils.deployAllNodes();
        let AccessControl = hubs[0];
        let Vote = hubs[6];
        await utils.grantAllRoles(AccessControl, accounts[0]);

        await Vote.mint(accounts[0], 1000);

        await Vote.transferFrom(accounts[0], accounts[1], 100);
        let x = (await Vote.balanceOf(accounts[0])).toString();
        assert.equal(x, "900", "test 1 error");
        x = (await Vote.balanceOf(accounts[1])).toString();
        assert.equal(x, "100", "test 11 error");

        x = await Vote.allowance(accounts[0], accounts[1]);
        console.log(x.toString());
        assert.equal("0", x.toString(), "test 0 error");

        await Vote.burn(accounts[1], 100);
        x = (await Vote.balanceOf(accounts[1])).toString();
        assert.equal(x, "0", "test 11 error");

        // await Vote.burn(accounts[0], 0);
    });
})