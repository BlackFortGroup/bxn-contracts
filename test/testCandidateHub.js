const helpers = require("./testCandidateHub_helpers");
const utils = require("./utils");
const web3 = require("web3");
const rpcURL = 'http://127.0.0.1:7545';
const Web3 = new web3(rpcURL);

contract("Candidate", accounts => {
    it("check CandidateHub", async function(){
        let hubs = await utils.deployAllNodes();
        let Candidate = hubs[4];
        let AccessControl = hubs[0];
        let Validator = hubs[2];

        await utils.grantAllRoles(AccessControl, accounts[0]);

        await helpers.checkRequiredAmount(Candidate, "0", 10000);
        await Candidate.setRequiredAmount(web3.utils.toWei("15000", "ether"));
        await helpers.checkRequiredAmount(Candidate, "0", 15000);

        await Candidate.sendTransaction({from: accounts[1], value: web3.utils.toWei("15000", "ether")});
        await helpers.checkSelfBondedAmountOf(Candidate, "0", accounts[1], 15000);

        await Candidate.accept(accounts[1]);
        await helpers.checkSelfBondedAmountOf(Candidate, "1", accounts[1], 0);
        await helpers.checkValidator(Validator,"11", accounts[1], true);

        // OK, revert CandidateHub
        // await Candidate.sendTransaction({from: accounts[1], value: web3.utils.toWei("15000", "ether")});

        await Candidate.setRequiredAmount(web3.utils.toWei("5000", "ether"));
        await Candidate.sendTransaction({from: accounts[2], value: web3.utils.toWei("5000", "ether")});
        // OK, revert CandidateHub
        //  await Candidate.accept(accounts[2]);
        await helpers.checkValidator(Validator, "2", accounts[2],false);
        await Candidate.sendTransaction({from: accounts[2], value: web3.utils.toWei("3000", "ether")});

        let amount = await Web3.eth.getBalance(accounts[2]);
        await Candidate.reject(accounts[2]);
        await helpers.checkAmount(accounts[2], amount, "3", web3.utils.toWei(String(8000), "ether"));
        await helpers.checkValidator(Validator, "33", accounts[2], false);
        await helpers.checkSelfBondedAmountOf(Candidate, "333", accounts[2], 0);
    });
})
