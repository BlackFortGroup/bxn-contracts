const utils = require("./utils");
const web3 = require("web3");

contract("System", accounts => {
    it("check contract address", async function() {
        let hubs = await utils.deployAllNodes();
        let AccessControl = hubs[0];
        let System = hubs[8];
        await utils.grantAllRoles(AccessControl, accounts[0]);

        let addresses = await utils.getContractAddresses(System);
        console.log(addresses);

        await utils.checkAmountAfterSendTransaction(
            "0",
            System,
            accounts[1],
            15000,
            15000
        );

        await System.sendTransaction({from: accounts[1], value: web3.utils.toWei("15000", "ether")});
    });
})