const web3 = require("web3");

const AccessControl = artifacts.require("AccessControlHub");
const Candidate = artifacts.require("CandidateHub");
const Delegator = artifacts.require("DelegatorHub");
const Node = artifacts.require("NodeHub");
const Poll = artifacts.require("PollHub");
const Slashing = artifacts.require("SlashingHub");
const System = artifacts.require("System");
const Validator = artifacts.require("ValidatorHub");
const Vote = artifacts.require("VoteHub");

module.exports = {
    deployCandidate: async function deployCandidate() {
        return await Candidate.deployed();
    },

    deployAccessControl: async function deployAccessControl() {
        return await AccessControl.deployed();
    },

    deployDelegator: async function deployDelegator() {
        return await Delegator.deployed();
    },

    deployNode: async function deployNode() {
        return await Node.deployed();
    },

    deployPoll: async function deployPoll() {
        return await Poll.deployed();
    },

    deploySlashing: async function deploySlashing() {
        return await Slashing.deployed();
    },

    deploySystem: async function deploySystem() {
        return await System.deployed();
    },

    deployValidator: async function deployValidator() {
        return await Validator.deployed();
    },

    deployVote: async function deployVote() {
        return await Vote.deployed();
    },
}
