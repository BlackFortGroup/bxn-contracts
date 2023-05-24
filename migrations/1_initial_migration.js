const Web3 = require('web3');
const fs = require("fs");
const utils = require("../test/utils");

const AccessControlHub = artifacts.require("AccessControlHub");
const System = artifacts.require("System");
const NodeHub = artifacts.require("NodeHub");
const ValidatorHub = artifacts.require("ValidatorHub");
const DelegatorHub = artifacts.require("DelegatorHub");
const CandidateHub = artifacts.require("CandidateHub");
const SlashingHub = artifacts.require("SlashingHub");
const VoteHub = artifacts.require("VoteHub");
const PollHub = artifacts.require("PollHub");

const Contracts = [NodeHub, ValidatorHub, DelegatorHub, VoteHub, CandidateHub, SlashingHub, PollHub];
const Names = ["NODE_HUB", "VALIDATOR_HUB", "DELEGATOR_HUB", "VOTE_HUB", "CANDIDATE_HUB", "SLASHING_HUB", "POLL_HUB"];
const Amounts = ["29500000000000000000000000000", "115792089237316195423570985008687907853269984665640564039457584007913129639935", "115792089237316195423570985008687907853269984665640564039457584007913129639935", "0", "0", "0", "0"];
const Addresses = ["0x0000000000000000000000000000000000001001", "0x0000000000000000000000000000000000001002", "0x0000000000000000000000000000000000001003", "0x0000000000000000000000000000000000001004", "0x0000000000000000000000000000000000001005", "0x0000000000000000000000000000000000001006", "0x0000000000000000000000000000000000001007",];
const Roles = ["ACCESS_CONTROL_MANAGER_ROLE", "SYSTEM_MANAGER_ROLE", 'VALIDATOR_MANAGER_ROLE', 'NODE_MANAGER_ROLE', 'POLL_MANAGER_ROLE']

const Validators = ["0x56f54a8b38b3a511500b0fb28a24aeaee9292730", "0x56d61d53a7b4d6c2d01323c4cab3cac2c044abc4", "0x65a2521459f0cc43716082d435aa9bfa4e11ef10", "0xceddb2ce1253d76a1bbddacd121e4e056acd73de", "0x25589f8958cc94beb31ba785b49b1004308aea3f", "0x98bff3c4d39946f72e1295ec45bbe0df371992e1"];


module.exports = async function (deployer, network, accounts) {
  if (network !== 'testnet') {
      await deployer.deploy(AccessControlHub);
      let access = await AccessControlHub.deployed();
      await deployer.deploy(System, access.address, {value: Web3.utils.toWei("100000", "ether"), from: accounts[0]});
      await access.grantRole(web3.utils.soliditySha3("SYSTEM_MANAGER_ROLE"), accounts[0]);
      await deployer.deploy(NodeHub, "NodeNFT", "NODE");
      await deployer.deploy(ValidatorHub, "Validator Contract", "VLDR");
      await deployer.deploy(DelegatorHub, "Delegator Contract", "DLGR");
      await deployer.deploy(VoteHub, "Vote Token", "VOTE");
      await deployer.deploy(CandidateHub);
      await deployer.deploy(SlashingHub);
      await deployer.deploy(PollHub, "BlackFort Poll", "POLL");

      /*
      let system = await System.deployed();
      await system.setSystemContractAddress(system.address);

      for (let i of Roles) {await access.grantRole(web3.utils.soliditySha3(i), accounts[0]);}

      for (let i = 0; i < Contracts.length; i++) {
          let curContract = await Contracts[i].deployed();
          await curContract.setSystemContractAddress(system.address);
          await system.setMapping(curContract.address, Names[i]);
          await system.approve(curContract.address, Amounts[i]);
          await access.enableTransfers(curContract.address);
      }

      await access.enableTransfers(system.address);
        */
      let genesisAlloc = {'alloc': {
              "0000000000000000000000000000000000000999": {
                  "balance": "0x0",
                  "code": AccessControlHub.deployedBytecode
              },
              "0000000000000000000000000000000000001000": {
                  "balance": "0x9A60D9FB28E9B608A1C71C71",
                  "code": System.deployedBytecode,
                  "storage": {
                      "0x0000000000000000000000000000000000000000000000000000000000000000": "0000000000000000000000000000000000000000000000000000000000001000",
                      "0x32e5baaace0b7df7b09d014dfd9603ec62319b9022e01a40cb86e9e53ca3cb6b": "0000000000000000000000000000000000000000000000000000000000000999"
                  }
              },
              "0000000000000000000000000000000000001001": {
                  "balance": "0x0",
                  "code": NodeHub.deployedBytecode,
                  "storage": {
                      "0x0000000000000000000000000000000000000000000000000000000000000000": "0000000000000000000000000000000000000000000000000000000000001000",
                      "0x0000000000000000000000000000000000000000000000000000000000000001": "426c61636b466f7274204e6f646500000000000000000000000000000000001c",
                      "0x0000000000000000000000000000000000000000000000000000000000000002": "4e4f444500000000000000000000000000000000000000000000000000000008",
                  }
              },
              "0000000000000000000000000000000000001002": {
                  "balance": "0x0",
                  "code": ValidatorHub.deployedBytecode,
                  "storage": {
                      "0x0000000000000000000000000000000000000000000000000000000000000003": "426c61636b466f72742056616c696461746f7200000000000000000000000026",
                      "0x0000000000000000000000000000000000000000000000000000000000000004": "564c445200000000000000000000000000000000000000000000000000000008",
                      "0x0000000000000000000000000000000000000000000000000000000000000005": "0000000000000000000000000000000000000000000000000000000000001000",
                  }
              },
              "0000000000000000000000000000000000001003": {
                  "balance": "0x0",
                  "code": DelegatorHub.deployedBytecode,
                  "storage": {
                      "0x0000000000000000000000000000000000000000000000000000000000000003": "426c61636b466f72742044656c656761746f7200000000000000000000000026",
                      "0x0000000000000000000000000000000000000000000000000000000000000004": "444c475200000000000000000000000000000000000000000000000000000008",
                      "0x0000000000000000000000000000000000000000000000000000000000000005": "0000000000000000000000000000000000000000000000000000000000001000",
                  }
              },
              "0000000000000000000000000000000000001004": {
                  "balance": "0x0",
                  "code": VoteHub.deployedBytecode,
                  "storage": {
                      "0x0000000000000000000000000000000000000000000000000000000000000000": "0000000000000000000000000000000000000000000000000000000000001000",
                      "0x0000000000000000000000000000000000000000000000000000000000000004": "426c61636b466f727420566f746500000000000000000000000000000000001c",
                      "0x0000000000000000000000000000000000000000000000000000000000000005": "564f544500000000000000000000000000000000000000000000000000000008",
                  }
              },
              "0000000000000000000000000000000000001005": {
                  "balance": "0x0",
                  "code": CandidateHub.deployedBytecode,
                  "storage": {
                      "0x0000000000000000000000000000000000000000000000000000000000000000": "0000000000000000000000000000000000000000000000000000000000001000",
                      "0x0000000000000000000000000000000000000000000000000000000000000002": "00000000000000000000000000000000000000000000021e19e0c9bab2400000",
                  }
              },
              "0000000000000000000000000000000000001006": {
                  "balance": "0x0",
                  "code": SlashingHub.deployedBytecode,
                  "storage": {
                      "0x0000000000000000000000000000000000000000000000000000000000000000": "0000000000000000000000000000000000000000000000000000000000001000",
                  }
              },
              "0000000000000000000000000000000000001007": {
                  "balance": "0x0",
                  "code": PollHub.deployedBytecode,
                  "storage": {
                      "0x0000000000000000000000000000000000000000000000000000000000000000": "0000000000000000000000000000000000000000000000000000000000001000",
                      "0x0000000000000000000000000000000000000000000000000000000000000001": "426c61636b466f727420506f6c6c00000000000000000000000000000000001c",
                      "0x0000000000000000000000000000000000000000000000000000000000000002": "504f4c4c00000000000000000000000000000000000000000000000000000008",
                      "0x0000000000000000000000000000000000000000000000000000000000000012": "00000000000000000000000000000000000000000000021e19e0c9bab2400000",
                      "0x0000000000000000000000000000000000000000000000000000000000000013": "00000000000000000000000000000000000000000000021e19e0c9bab2400000",
                      "0x0000000000000000000000000000000000000000000000000000000000000014": "00000000000000000000000000000000000000000000021e19e0c9bab2400000",
                      "0x0000000000000000000000000000000000000000000000000000000000000015": "00000000000000000000000000000000000000000000000000000000000003e8",
                  }
              },
              "50E7Ad751BA952f5b5b1Ef8bdBB83E4e49B94B8F": {
                  "balance": "0x3635C9ADC5DEA00000"
              }
          }};

      await fs.writeFileSync('./alloc.json', JSON.stringify(genesisAlloc, null, 4));
      console.log('Deployment Finished!');


  } else {
      console.log("Fetching accounts");
      console.log("Accounts", accounts);
      console.log('Deployer', deployer);

      let access = await AccessControlHub.at("0x0000000000000000000000000000000000000999");
      let system = await System.at("0x0000000000000000000000000000000000001000");
      let node = await NodeHub.at("0x0000000000000000000000000000000000001001");
      let validator = await ValidatorHub.at("0x0000000000000000000000000000000000001002");
      let candidate = await CandidateHub.at("0x0000000000000000000000000000000000001005");
      console.log('TEST');
      console.log(accounts[0])
      console.log(await web3.eth.sendTransaction({from: accounts[0], to: "0x56a3E58AB2cB4f7Ab60eDCe33bbB5B11c8d8ca80", value: web3.utils.toWei("100", 'ether')}))
      return;
      console.log('Initializing AccessControlHub');
      await access.init();
      console.log('Initializing NodeHub');
      await node.init();

      for (let i of Roles) {console.log('Granting role:', i);await access.grantRole(web3.utils.soliditySha3(i), accounts[0]);}

      for (let i of Validators) {
          console.log('Sending BXN to validator:', i);
          await web3.eth.sendTransaction({from: accounts[0], to: i, value: "2000000000000000000", nonce: await web3.eth.getTransactionCount(accounts[0])})
      }

      console.log('Set required amount for validator');
      await candidate.setRequiredAmount("1000000000000000000");

      for (let i = 0; i < 7; i++) {
          console.log('Mapping:', Names[i]);
          await system.setMapping(Addresses[i], Names[i]);
          console.log('Approving:', Names[i]);
          await system.approve(Addresses[i], Amounts[i]);
          console.log('Enabling transfers:', Names[i]);
          await access.enableTransfers(Addresses[i]);
      }
      console.log('Approving: SALE_HUB');
      await system.approve(accounts[0], "SALE_HUB", "15000000000000000000000000000");

      console.log((await candidate.requiredAmount()).toString());

      for (let i of Validators) {
          if (i !== "0x98bff3c4d39946f72e1295ec45bbe0df371992e1") continue;
          console.log('Sending BXN to CandidateHub for:', i);
          await web3.eth.sendTransaction({from: i, to: "0x0000000000000000000000000000000000001005", value: "1000000000000000000", nonce: await web3.eth.getTransactionCount(i)})
      }
      for (let i of Validators) {
          console.log('Accepting validator:', i);
          await candidate.accept(i);
      }

      for (let i of Validators) {
          console.log("Is", i, 'validator?', await validator.isValidator(i));
      }

      console.log('Ready!')
  }
};

