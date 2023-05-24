const web3 = require("web3");
const rpcURL = 'http://127.0.0.1:7545';
const Web3 = new web3(rpcURL);

const deployers = require("./deployers");

module.exports = {
    grantAllRoles: async function grantAllRoles(AccessControl, account) {
        await AccessControl.grantRole(web3.utils.soliditySha3("VOTE_MINT_ROLE"), account);
        await AccessControl.grantRole(web3.utils.soliditySha3("ACCESS_CONTROL_MANAGER_ROLE"), account);
        await AccessControl.grantRole(web3.utils.soliditySha3("SYSTEM_MANAGER_ROLE"), account);
        await AccessControl.grantRole(web3.utils.soliditySha3("VALIDATOR_MANAGER_ROLE"), account);
        await AccessControl.grantRole(web3.utils.soliditySha3("NODE_MANAGER_ROLE"), account);
        await AccessControl.grantRole(web3.utils.soliditySha3("POLL_MANAGER_ROLE"), account);
        await AccessControl.grantRole(web3.utils.soliditySha3("VOTE_BURN_ROLE"), account);
        await AccessControl.grantRole(web3.utils.soliditySha3("VOTE_SPENDER_ROLE"), account);
    },

    deployAllNodes: async function deployAllNodes() {
        let access_control = await deployers.deployAccessControl();
        let node_hub = await deployers.deployNode()
        let validator_hub = await deployers.deployValidator();
        let delegator_hub = await deployers.deployDelegator();
        let candidate_hub = await deployers.deployCandidate();
        let slashing_hub = await deployers.deploySlashing();
        let vote_hub = await deployers.deployVote();
        let poll_hub = await deployers.deployPoll();
        let system = await deployers.deploySystem();
        return [access_control, // 0
                node_hub,       // 1
                validator_hub,  // 2
                delegator_hub,  // 3
                candidate_hub,  // 4
                slashing_hub,   // 5
                vote_hub,       // 6
                poll_hub,       // 7
                system          // 8
        ];
    },

    makeValidator: async function makeValidator(Candidate, account) {
        let amount = await Candidate.requiredAmount.call();
        await Candidate.sendTransaction({from: account, value: amount});
        await Candidate.accept(account);
    },

    getContractAddresses: async function getContractNames(System) {
        let contract_names = [
            "ACCESS_CONTROL_HUB",
            "NODE_HUB",
            "VALIDATOR_HUB",
            "DELEGATOR_HUB",
            "VOTE_HUB",
            "CANDIDATE_HUB",
            "SLASHING_HUB",
            "POLL_HUB"
        ];
        let addresses = [];
        for (let i = 0; i < contract_names.length; i += 1) {
            let name = contract_names[i]
            let address = await System.getAddressOf(name);
            console.log("address of", name, ":", address);
            addresses.push(address);
        }
        return addresses;
    },

    checkAmountAfterSendTransaction: async function checkAmountAfterSendTransaction(
        case_number,
        Contract,
        account,
        val,
        need_dif,
    ) {
        let value = web3.utils.toWei(val.toString(), "ether");
        let need_diff = web3.utils.toWei(String(need_dif), "ether");

        let amount = await Web3.eth.getBalance(account);
        await Contract.sendTransaction({from: account, value: value});
        let new_amount = await Web3.eth.getBalance(account);
        let diff = Math.abs(need_diff - Math.abs(new_amount - amount));
        assert(diff < 1e15, "case_number=" + case_number);
    }
}
