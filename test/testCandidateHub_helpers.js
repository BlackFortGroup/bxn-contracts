const web3 = require("web3");
const rpcURL = 'http://127.0.0.1:7545';
const Web3 = new web3(rpcURL);

module.exports = {
    checkRequiredAmount: async function checkRequiredAmount(contract_instance, case_number, amount) {
        let reqAmount = await contract_instance.requiredAmount.call();
        assert.equal(reqAmount, web3.utils.toWei(String(amount), "ether"), "case_number=" + case_number);
    },

    checkSelfBondedAmountOf: async function checkSelfBondedAmountOf(contract_instance, case_number, account, amount) {
        let cur_amount = await contract_instance.selfBondedAmountOf(account);
        assert.equal(cur_amount, web3.utils.toWei(String(amount), "ether"), "case_number=" + case_number);
    },

    checkValidator: async function checkValidator(contract_instance, case_number, account, status) {
        let isVal = await contract_instance.isValidator(account);
        assert.equal(isVal, status, "case_number=" + case_number);
    },

    checkAmount: async function checkAmount(account, amount, case_number, need_diff) {
        let new_amount = await Web3.eth.getBalance(account);
        console.log(amount);
        console.log(new_amount);
        console.log(new_amount - amount);
        console.log(need_diff);
        let diff = Math.abs(need_diff - (new_amount - amount));
        let s = diff.toFixed(7);
        console.log(s);
        assert(diff < 1e11, "case_number=" + case_number);
    }
}
