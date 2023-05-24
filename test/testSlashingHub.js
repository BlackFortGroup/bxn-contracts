const utils = require('./utils');

const web3 = require("web3");


contract("SlashingHub", accounts => {
    it("check SlashingHub", async function(){
        let hubs = await utils.deployAllNodes();
        let AccessControl = hubs[0];
        let Slashing = hubs[5];
        let Candidate = hubs[4];
        await utils.grantAllRoles(AccessControl, accounts[0]);
        await utils.makeValidator(Candidate, accounts[0]);

        await Slashing.slash(accounts[0], 100);

        let flag = await Slashing.isSlashed(accounts[0]);
        assert.equal(flag, false, "test 0 fail");

        let time = await Slashing.timesSlashed(accounts[0]);
        assert.equal(time.toString(), "2", "test 1 fail");

        let block = await Slashing.slashedByBlock(accounts[0]);
        assert.equal(block.toString(), "0", "test 2 fail");

        flag = await Slashing.isSlashed(accounts[0]);
        console.log(flag);
    });
})