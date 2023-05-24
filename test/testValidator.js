const helpers = require('./testValidator_helpers');
const utils = require('./utils');
const web3 = require("web3");
const rpcURL = 'http://127.0.0.1:7545';
const Web3 = new web3(rpcURL);

contract("ValidatorHub", accounts => {
    it("check ValidatorHub", async function(){
        let hubs = await utils.deployAllNodes();
        let Validator = hubs[2];
        let Candidate = hubs[4];
        let AccessControl = hubs[0];
        await utils.grantAllRoles(AccessControl, accounts[0]);

        await utils.makeValidator(Candidate, accounts[1]);
        await utils.makeValidator(Candidate, accounts[0]);

        await Validator.sendTransaction({from: accounts[1], value: web3.utils.toWei("15000", "ether")});
        await helpers.checkSelfBondedAmountOf("0", Validator, accounts[1], web3.utils.toWei("25000", "ether"));

        await helpers.checkIsValidator("1", Validator, accounts[1], true);
        await helpers.checkIsValidator("11", Validator, accounts[2], false);

        await Validator.setCommission(1000);
        await helpers.checkCommissionOf("2", Validator, accounts[0], "1000");
        await helpers.checkCommissionOf("22", Validator, accounts[1], "100");

        let amount = await Web3.eth.getBalance(accounts[1]);
        await Validator.kick(accounts[1]);
        await helpers.checkAmount("3", accounts[1], amount, web3.utils.toWei(String(25000), "ether"));
    });
})
