const helpers = require('./testAccessControl_helpers');
const utils = require('./utils');

const web3 = require("web3");

contract("AccessControl", accounts => {
    it("check Access", async function(){
        let hubs = await utils.deployAllNodes();
        let AccessControl = hubs[0];

        await AccessControl.grantRole(web3.utils.soliditySha3("ACCESS_CONTROL_MANAGER_ROLE"), accounts[0]);
        await AccessControl.grantRole(web3.utils.soliditySha3("SYSTEM_MANAGER_ROLE"), accounts[0]);

        await helpers.checkRole(AccessControl, accounts[0], "0", "SYSTEM_MANAGER_ROLE");

        await AccessControl.grantRole(web3.utils.soliditySha3("SALE_MANAGER_ROLE"), accounts[0]);
        await helpers.checkRole(AccessControl, accounts[0], "1","SALE_MANAGER_ROLE");

        await AccessControl.grantRole(web3.utils.soliditySha3("VALIDATOR_MANAGER_ROLE"), accounts[0]);
        await helpers.checkRole(AccessControl, accounts[0], "111", "VALIDATOR_MANAGER_ROLE");

        for (let i = 0; i < hubs.length; i += 1) {
            await AccessControl.enableTransfers(hubs[i].address);
            let num = i + 5;
            await helpers.checkTransfersAvailable(AccessControl, hubs[i].address, num.toString(), true);
            await AccessControl.disableTransfers(hubs[i].address);
            num = i + 6;
            await helpers.checkTransfersAvailable(AccessControl, hubs[i].address, num.toString(), false);
        }
    });
})
