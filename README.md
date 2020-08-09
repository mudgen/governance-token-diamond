# Governance Token Diamond

> Note: A diamond is a contract that uses the code of its "facet" contracts to execute functionality. Diamond implementations follow the [Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535).

An ERC20 governance token diamond that can govern a project as well as itself. Implemented using the Diamond Standard.

The `GovernanceTokenDiamond` contract is the governance token diamond. It routes function calls to the facets defined in the facets folder.

Features:

1. Implements the ERC20 standard.
2. Accepts executable proposals.
3. Allows people to vote on proposals using their ERC20 token balance.
4. Token holders are rewarded for voting by being minted new tokens. Safeguards exist to prevent too much inflation.
5. Token holders are rewarded for submitting proposals that pass and are penalized for submitting proposals that are rejected.
6. Passed proposals are executed on-chain.
7. Passed proposals are executed using `delegatecall` to enable governance of the governance token diamond itself.
8. Implements the Diamond Standard so that passed proposals can add/replace/remove functions on itself.

## Executable Proposals

Governance token holders can make proposals to change the project it is governing or change the governance token diamond.

A proposal is a contract that implements the `execute(uint256 _proposalId)` function. All functionality of a proposal is executed and/or triggered by this function.

The `execute` function is called with `delegatecall` from `GovernanceTokenDiamond`. Remember that `GovernanceTokenDiamond` is the diamond.

> Note: The solidity `delegatecall` opcode enables a contract to execute a function from another contract, but it is executed as if the function was from the calling contract. Essentially `delegatecall` enables a contract to “borrow” another contract’s function. Functions executed with delegatecall affect the storage variables of the calling contract, not the contract where the functions are defined.

Using `delegatecall` to call the `execute` function is what enables governance token holders to govern the governance token diamond itself.

Using `delegatecall` to call `execute` allows the governance token diamond to be modified in two different ways:

1. The governance token diamond has a number of state variables that are settings for various functionality. The `execute` function can change the values of state variables and therefore can change any of the settings.
2. The `execute` function can call the `diamondCut` internal function from the Diamond Standard to add new functions to the goverance token diamond, replace existing functions and remove functions.

The `execute` function can of course interact with other contracts on the network in order to cause changes and effects in order to govern a project.

I got the idea of executable proposals from [DerivaDEX](https://derivadex.com) and [Compound's governance token contract](https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol).

## Proposals and Voting

A proposal is submitted by calling the `propose(address _proposalContract, uint _endTime)` function on the diamond.

`_proposalContract` is the proposal, which is a contract that has the `execute(uint256 _proposalId)` function, which is called with `delegatecall` after it is voted on and if it passes the vote.

`_endTime` specifies what time, in seconds, the vote for `_proposalContract` ends. `_endTime` is a timestamp, the number of seconds that have elapsed since January 1, 1970.

For example to specify that the voting period for a proposal is 3 days `_endTime` could be calculated like this: `block.timestamp + 60 * 60 * 24 * 3`. There are `minimumVotingTime` and `maximumVotingTime` that control the minimum and maximum voting time.

In order to submit a proposal a governance token holder must own a certain amount of the governance token. This is controlled by the `proposalThresholdDivisor` setting.

Token holders that submit proposals that pass a vote are rewarded by being minted new governance tokens, and are penalized by losing their entire governance token balance when their proposals lose a vote. This is "governane mining". How much the reward is, is determined by the `proposerAwardDivisor` and `voteAwardCapDivisor` settings. When a proposal loses a vote the proposer's tokens are burned.

Remember that any of the settings can be changed by a proposal.

The voting period for a proposal starts once a proposal is succssfully submitted using the `propose` function mentioned above.

### Voting

Once a proposal is submitted governance token holders can vote on it.

Governance token holders call the `vote(uint _proposalId, bool _support)` function to vote. `_proposalId` is for choosing which proposal to vote on and `_support` is for voting for or againt. The value `true` is voting for, and the value `false` is voting against.

The weight of a token holder's vote is how many governance tokens the token holder owns.

Once a token holder votes on a proposal their tokens become locked until the voting period for the proposal is over. By "locked" is meant token holders will not be able to transfer governance tokens from the address that they used to vote until the voting period for the proposal they voted on is over. However a token holder can vote for multiple proposals when their tokens are locked.

The reason for locking governance tokens after a vote is to prevent double voting with the same tokens.  Holder A could vote and then transfer his/her tokens to another address and vote again. This is prevented by locking the tokens until after a vote is over.

Tokens holders are rewarded for voting by being minted new governance tokens. This is "governance mining". How much the reward is, is determined by the `voterAwardDivisor` setting and the `voteAwardCapDivisor` setting.

Token holders can change their mind and undo their vote for a proposal by calling the `unvote(uint _proposalId)` function. That removes the token holder's votes, removes their reward for voting, and unlocks the token holder's tokens so they can be transferred again.






















