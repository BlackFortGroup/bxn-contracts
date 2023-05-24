const helpers = require('./testDelegatorHub_helpers');
const utils = require('./utils');

const web3 = require("web3");


contract("DelegatorHub", accounts => {
    it("check Delegator Hub", async function(){
        let hubs = await utils.deployAllNodes();
        let AccessControl = hubs[0];
        let Candidate = hubs[4];
        let Delegator = hubs[3];
        await utils.grantAllRoles(AccessControl, accounts[0]);

        await utils.makeValidator(Candidate, accounts[1]);

        let x = await Delegator.delegatedAmountOf(accounts[1]);
        console.log(x);

        // только для аккаунтов валидаторов
        let validatorAccount = ""// TODO
        let tokenId = "" // TODO
        await Delegator.increaseDelegatedAmountFor(validatorAccount, tokenId);

        let amount = await Delegator.delegatedAmountOf();

        await Delegator.decreaseDelegatedAmountFor(validatorAccount, tokenId);

        amount = await Delegator.delegatedAmountOf();

        let minted = await Delegator.mintedWith(tokenId);
        let totalReward = await Delegator.mintedBy(validatorAccount);

        await Delegator.mint(validatorAccount, tokenId);

        await Delegator.burnExtraFor(tokenId);
    });
})