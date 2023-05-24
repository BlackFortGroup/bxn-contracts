# BlackFort Exchange Network
## Concept
Default Ethereum Clique Blockchain based on PoA. Go-Ethereum is forked and used without any additional changes

### Type of hosted nodes
Type      | Amount | Connection | Description
--------- | ------ | ---------- | -----------
Validator | As amount of validators (at least 5) | Private, to Bootnodes | Used to seal new blocks in blockchain, fetching the data coming to `Bootnodes`. They use unlocked accounts, so they should keep safe from any other connection type, except ingress/egress data exchange with `Bootnodes`
Bootnodes | At least 3 | Public, to `Peer` and other `Bootnodes`. Private to `Validator` Validator and other bootnodes | Used as a core of data exchanging between `Peer` and `Validator`, because we can't grant access to `Validator`, because of unlocked account
Peer | No limit | Public, to any of `Bootnodes` | Just regular Peer node for storing a copy of blockchain on your machine
Explorer | 1 - 2 | Public, to any of `Bootnodes` | Same as `Peer`, but used for providing data to blockchain explorer

## Smart Contracts

### Setup
`System`, `NodeHub`, `ValidatorHub`, `DelegatorHub`, `VoteHub`, `CandidateHub`, `SlashingHub`, `PollHub` are deployed on genesis block, though for testing purposes you can deploy them manually using `TEST_setSystemContract` method to replace `SYSTEM_CONTRACT_ADDRESS` in `SystemAccess` contract. `AccessControlHub` is deployed manually. We have to save names of contracts in `System` in snake case e.g. `NODE_HUB` which is used for finding other system contracts and with approving of spending of certain amount of BXN. **Unfortunately we have problem with approving `AccessControlHub` which must be done first, so if you have solution without hardcoding in contracts, please let me know**. See Allocation to know allocation of BXN and approved amounts

### Allocation
Name | Address | Allocation on start (BXN) | Approved to spend (BXN)
------ | --------- | --------- | --------
`AccessControlHub` | Manually deployed | 0 | 0
`System` | `0x0000000000000000000000000000000000001000` | 47,777,777,777 | Not related
`NodeHub` | `0x0000000000000000000000000000000000001001` | 0 | 29,500,000,000
`ValidatorHub` | `0x0000000000000000000000000000000000001002` | 0 | 2^256^ (unlimited)
`DelegatorHub` | `0x0000000000000000000000000000000000001003` | 0 | 2^256^ (unlimited)
`VoteHub` | `0x0000000000000000000000000000000000001004` | 0 | 0
`CandidateHub` | `0x0000000000000000000000000000000000001005` | 0 | 0
`SlashingHub` | `0x0000000000000000000000000000000000001006` | 0 | 0
`PollHub` | `0x0000000000000000000000000000000000001007` | 0 | 0
~~`SaleHub`~~ | Not a smart contract (operated by one of our's account) | 10000 (reserve for making transactions) | 15,000,000,000 (approx number)

### `AccessControlHub`
Contract is used for managing accessing for protected methods across all core smart contracts. Also it manages pausing/unpausing transfers for a bunch of core contracts + Bx assets (wrapped BTC, ETH and so on), which will be managed by us. Most of functionality is inherited from `AccessControl` of OpenZeppelin

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`transfersAvailable` | `address` | `bool` | returns whether the address (contract) has transfers enabled
`hasStringRole` | `string memory`, `address` | — | override on `AccessControl`'s `hasRole` method accepting human-readable string instead of bytes in the code
`enableTransfers` | `address` | — | enables transfers for given address of core smart contract
`disableTransfers` | `address` | — | same as above, but disables


### `System`
Core contract that locks whole blockchain supply. Used to store supply and grant it to users/contracts. Withdraw of token is managed by limited set of contracts that can do and the total amount they can withdraw from the contract

Works as coinbase, block sealers must send rewards there for their further distribution
Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`approve` | `address`, `string memory`, `uint256` | — | Method to approve spending of certain amount of tokens from the `System`. Also saves name of the contract that can be used for finding it without using addresses in the code, e.g. `NODE_HUB` will stand for `0x0000000000000000000000000000000000001001` (check `getAddressOf`)
`approvedAmountOf` | `address` | `uint256` | Returns approved amount for certain address
`spentAmountOf` | `address` | `uint256` | Returns spent amount for certain address
`getAddressOf` | `string memory` | `address` | Returns address by contract name
`receive` | — | — | Default method for receiving BXN. If it was sent by block sealer (validator), it will be distributed as a reward. Otherwise just stays in the `System`
`transferTo` | `address`, `uint256` | `bool` | Used to send certain amount of token to certain address. Allowed to use only by approved contracts/addresses

### `NodeHub`
ERC721 compatible token used to describe the BXN NODE Token, which unlocks BXN from the `System` for approx. next 10 years after mint. NODE doesn't have any common with hosted nodes. By minting NODE you're going to unlock BXN from the `System`, reward is collected each block

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`receive` | — | — | Default receive method
`balanceOf` | `address` | `uint256` | As in ERC721
`ownerOf` | `uint256` | `address` | As in ERC721
`tokenOfOwnerByIndex` | `address`, `uint256` | `uint256` | Extension of  ERC721
`isLocked` | `uint256` | `bool` | Returns if token is locked
`mintedWith` | `uint256` | `uint256` | Amount of BXN minted with certain NODE token
`mintedBy` | `address` | `uint256` | `mintedWith` applied on all NODE tokens that are held by given `address`
`burnedBy` | `address` | `uint256` | Amount of reward burned by certain address
`availableBalanceOf` | `address` | `uint256` | Amount of reward which is available to burn
`rewardShareFor` | `uint256` | `uint256` | reward share of given NODE, equals to block reward of NODE
`rewardShareOf` | `address` | `uint256` | `rewardShareFor` applied on all NODE tokens that are held by given `address`
`delegatedTo` | `uint256` | `address` | Returns address of the validator to which that NODE is delegated
`mint` | `address` | — | Accepts payment and mints new NODEs to the address, depending on invested amount. Also checks for not exceeding of deposit limit and gives you some amount of VOTE token. Always refunds not used for purchase BXN
`lock` | `uint256` | — | Locks the NODE. Locked NODE can't earn anything. Can be run only by `SaleHub`
`unlock` | `uint256` | — | Unlocks the NODE. Can be run only by `SaleHub`
`delegate` | `address` | `uint256` | Delegates NODE to given validator address. Undelegates if `delegatedTo` is `address(0)`
`_burnFrom` | `address`, `uint256` | — | Burns given amount from `availableBalanceOf` giving back BXN from `System`
`_beforeTokenTransfer` | `address`, `address`, `uint256` | — | Upgraded method to handle some processes on NODE transfer to new owner e.g. undelegating, burning reward
`_baseURI` | — | `string memory` | returns URI prefix to our pictures


### `ValidatorHub`
ERC20/BXP20 compatible token used to describe the block sealer e.g.  validator, which sends transaction fee to the `System` in order to distribute it

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`receive` | — | — | Default receive method used to top up validator's self bonded amount of BXN
`isValidator` | `address` | `bool` | Is the given address a validator
`commissionOf` | `address` | `uint256` | returns validator's commission (4951 stands for 49.51%)
`setCommission` | `uint256` | — | Method for setting commission of validator. Value must be in range (0, 5000)
`selfBondedAmountOf` | `address` | `uint256` | Returns self bonded amount of validator. 0 if that user is not validator
`mint` | `address`, `uint256` | — | Method used by `System` to mint validator's reward
`join` | `address` | — | Method accepts new validator, is run by `CandidateHub` contract
`kick` | `address` | `bool` | Kicking of validator, performed only with `VALIDATOR_MANAGER_ROLE`. Self bonded amount is returned back to validator's account

### `DelegatorHub`
ERC20/BXP20 compatible token used to describe the block sealer e.g.  validator, which sends transaction fee to the `System` in order to distribute it

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`increaseDelegatedAmountFor` | `address`, `uint256` | — | Processes the calculations of changing of shares (increases)
`decreaseDelegatedAmountFor` | `address`, `uint256` | — | Just the same as above, but decrease
`delegatedAmountOf` | `address` | `uint256` | returns amount of tokens delegated to validator (sum of all costs of NODEs delegated)
`mintedWith` | `uint256` | `uint256` | returns total amount of reward earned by certain NODE
`mintedBy` | `address` | `uint256` | returns total amount of reward earned by NODEs owned by certain address
`mint` | `address`, `uint256` | — | Method used by `System` to mint delegator's reward of certain validator
`burnExtraFor` | `uint256` | — | burns all reward earned by certain token

### `VoteHub`
ERC20/BXP20 compatible token used as voting power on blockchain. At start used in polls by `PollHub`. Can be used by multiple projects in future

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`mint` | `address`, `uint256` | — | Mints the VOTE token for certain address if `msg.sender` is allowed to do that
`burn` | `address`, `uint256` | — | Same as above, but burns the VOTE and gives instead BXN token. Available only for certain `msg.sender`'s
`allowance` | `address`, `uint256` | — | same as `allowance` in ERC20/BXP20, but for `PollHub` it's always equals to `balanceOf`

### `CandidateHub`
Small contract that used to accept new validators of hosted nodes (they would require to install software too)

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`receive` | — | — | Default receive account used to add new candidate. Account should pass certain limit to become a candidate
`accept` | `address` | — | makes candidate a validator and moves self bonded amount to `ValidatorHub`
`reject` | `address` | — | rejects candidate and returns back deposited amount
`selfBondedAmountOf` | `address` | `uint256` | Returns self bonded amount of candidate. 0 if that user is not validator
`setRequiredAmount` | `uint256` | — | sets required amount to become candidate

### `SlashingHub`
Contract is used for slashing validator

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`isSlashed` | `address` | `bool` | returns true if validator is slashed
`slashedByBlock` | `address` | — | returns block number until the validator is slashed, `0` returned is validator is not slashed
`timesSlashed` | `address` | — | count of times of certain validator was slashed
`slash` | `address`, `uint8` | — | slashes the validator untils the certain block number, reducing his further rewards for some period of time

### `PollHub`
Contract is used for managing on-chain polls. Public to everyone. Poll represents ERC721 token

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`setRequiredAmountOfVote` | `uint256` | — | sets required amount of VOTE token that creator of Poll must have
`setRequiredAmountOfBXN` | `uint256` | — | sets required amount of BXN token that creator of Poll must have
`setPollPrice` | `uint256` | — | sets price of initiation of the Poll
`setPollCreatorFee` | `uint256` | — | sets the fee that creator of the Poll receives on each amount of VOTE spent with `vote` method
`mint` | `string memory` | — | mints Poll with the given `title`
`burn` | `uint256` | — | burns Poll token if poll was not opened e.g. voting started of finished
`titleOf` | `uint256` | `string memory` | returns title of existing Poll
`updateTitle` | `uint256`, `string memory` | — | updates title of certain Poll
`optionOfPollByIndex` | `uint256`, `uint256` | `string memory` | returns text of option by `optionId` of given Poll
`optionsCountOf` | `uint256` | `uint256` | returns count of options of given Poll
`addOption` | `uint256`, `string memory` | — | adds new option for not opened Poll
`removeOption` | `uint256`, `uint256` | — | removes option of the poll, by given optionId
`updateOption` | `uint256`, `uint256`, `string memory` | — | updates the option of the Poll by given string and `optionId`
`start` | `uint256`, `uint8` | — | opens not yet opened Poll with preset deadline block number
`deadlineBlockOf` | `uint256` | `uint8` | returns deadline block number (block number when the Poll closes)
`updateDeadlineBlock` | `uint256`, `uint8` | — | updates deadline block number for given Poll
`vote` | `uint256`, `uint256`, `uint256` | — | vote for certain option of certain Poll with certain amount of VOTE token
`votesByOptionOf` | `uint256`, `uint256` | `uint256` | returns amount of VOTE spent for given `optionId` of given Poll
`totalVotesOf` | `uint256` | `uint256` | returns total amount of VOTE was spent in the Poll

## Inherited Smart Contracts

### `SystemAccess`

Contract defines certain internal methods to make available interaction between different core contracts without declaring address references

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`_getSystemContractInstance` | — | `ISystem` | returns `ISystem` interface of `System` contract
`_getAddressOf` | `string memory` | `address` | override of  `getAddressOf` method of `System` contract
`hasRole` | `string memory`, `address` | `bool` | override of  `hasStringRole` method of `AccessControlHub` contract


### `BXP20SystemRewardToken`

Contract (re)defines methods of `BXP20` to be compatible with `ValidatorHub` and `DelegatorHub`

Method | Arguments | Returns | Description
------ | --------- | ------- | -----------
`TBA` | — | `TBA` | TBA

## BXP20

BXP20 realization is a slightly extended version of OpenZeppelin's ERC20. Additional methods are `mint` and `burn` which are allowed to run only by asset manager address. Other details are to be announced and described

## How it would work
### Regular user
Regular user can buy BXN token through our web interface or exchange it on DEX (in future). We send out BXN from `System`. Access to it will be available only to one address that will be responsible for sales (aka `SaleHub`)

User also can buy NODEs. User can do it by himself sending BXN to `NodeHub`. Amount depends on NODEs the user wants to obtain. Also ther will be possibility to buy BXN tokens to spend them on NODEs (means that `SaleHub` requests to send BXN from `System` directly to `NodeHub`'s `mint` method mentioning the recepient's address

### NODE Owner
NODE owner can get the block reward using `burn` method, `System` will send him BXN tokens. Also NODE owner can delegate his NODEs across different validators using `delegate` method of `NodeHub`

If NODE is delegated to a validator, NODE owner can obtain share of reward that validator shall always send to `System` for futher distribution. In order to get BXN, user must `burn` the `DelegatorHub` token, which acts as BXP20 token and burns at 1:1 rate

### Validator
Validators seal the blocks and are responsible for sharing all their rewards with `System` contract. Sharing of reward is automated and managed by [etherbase.js](https://gist.github.com/BlackFortGroup/e464094effebb6d648a58f65059d7761) script that we provide. Any misbehaviour including changing of that script will lead to punishment (slashing). Slashing reduces reward share of validator increasing the share of delegators

Validators must have self bonded amount of BXN to seal the blocks. New validators always share their self bonded amount with `CandidateHub`, after we accept new validator with `clique.propose` on-chain vote, we additionaly accept him in smart contracts and give access to `ValidatorHub` contract which allows them to set their own commission for their work and also receiving their validator's reward with `burn` of `ValidatorHub` token which acts as BXP20 token and burns at 1:1 rate
