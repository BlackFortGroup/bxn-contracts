const web3 = require("web3");
const rpcURL = 'http://127.0.0.1:7545';
const Web3 = new web3(rpcURL);

module.exports = {
    checkSelfBondedAmountOf: async function checkSelfBondedAmountOf(case_number, Validator, account, need_amount){
        let amount = await Validator.selfBondedAmountOf(account);
        assert.equal(amount.toString(), need_amount.toString(), "case_number=" + case_number)
    },

    checkIsValidator: async function checkIsValidator(case_number, Validator, account, status) {
        let flag = await Validator.isValidator(account);
        assert.equal(flag, status, "case_number=" + case_number);
    },

    checkCommissionOf: async function checkCommissionOf(case_number, Validator, account, need_amount) {
        let amount = (await Validator.commissionOf(account)).toString();
        assert.equal(amount, need_amount, "case_numer=" + case_number);
    },

    checkAmount: async function checkAmount(case_number, account, amount, need_diff) {
        let new_amount = await Web3.eth.getBalance(account);
        let diff = Math.abs(need_diff - (new_amount - amount));
        assert(diff < 1e11, "case_number=" + case_number);
    }
}
