module.exports = {
    checkRole: async function checkRole(contract_instance, account, case_number, role_name){
        let hasRole = await contract_instance.hasStringRole(role_name, account);
        assert.equal(hasRole, true, case_number + ": " + role_name + " not set for " + account);
    },

    checkTransfersAvailable: async function checkTransfersAvailable(contract_instance, contract_address, case_number, status){
        let transfersAvailable = await contract_instance.transfersAvailable(contract_address);
        assert.equal(transfersAvailable, status, case_number + ": transferPaused not " + status);
    }
}
