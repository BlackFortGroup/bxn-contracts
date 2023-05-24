const utils = require('./utils.js');

const web3 = require("web3");


contract("PollHub", accounts => {
    it("check PollHub", async function(){
        let hubs = await utils.deployAllNodes();
        let Poll = hubs[7];
        let AccessControl = hubs[0];
        await utils.grantAllRoles(AccessControl, accounts[0]);
        await Poll.setBaseTokenURI("https:/1.1.1.1");
        await Poll.setRequiredAmountOfVote(100);
        await Poll.setRequiredAmountOfBXN(10);
        await Poll.setPollPrice(1000);
        await Poll.setPollCreatorFee(11);
        await Poll.mint("1-st Poll in BXN");
    });
})