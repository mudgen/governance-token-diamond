// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { IERC20 } from '../interfaces/IERC20.sol';
import { InternalFunctions } from '../lib/InternalFunctions.sol';



contract Governance is InternalFunctions {
    
    event Vote(uint indexed _proposalId, address indexed _voter, uint _votes, bool _support);
    event UnVote(uint indexed _proposalId, address indexed _voter, uint _votes, bool _support);  

/*
    /// @notice The number of tokens required for someone to submit a proposal
    function proposerThreshold() public pure returns (uint) { return 1; } // 1 percent of totalSupply
    
    /// @notice The number of votes required for a proposal to pass
    function quorumVotes() public pure returns (uint) { return 10; } // 10 percent of totalSupply

    function voterReward() public pure returns (uint) 
*/
    
    function mint(address _to, uint96 _value) internal {
        ERC20TokenStorage storage ets = erc20TokenStorage();        
        ets.totalSupply += _value;
        ets.balances[_to] += _value;
    }

    function proposalCount() external view returns (uint) {
        return governanceStorage().proposalCount;
    }

    function propose(address _proposalContract, uint _endBlock) external {
        GovernanceStorage storage gs = governanceStorage();
    }

    function vote(uint _proposalId, bool _support) external {
        (ERC20TokenStorage storage ets,
        GovernanceStorage storage gs) = governanceTokenStorage();
        require(_proposalId < gs.proposalCount, '_proposalId does not exist');
        Proposal storage proposal = gs.proposals[_proposalId];
        require(block.number < proposal.endBlock, 'Voting ended');
        require(proposal.voted[msg.sender].votes == 0, 'Already voted');        
        uint balance = ets.balances[msg.sender];
        if(_support) {
            proposal.forVotes += uint96(balance);
        }
        else {
            proposal.againstVotes += uint96(balance);
        }
        proposal.voted[msg.sender] = Voted(uint96(balance), _support);
        gs.votedProposalIds[msg.sender].push(uint24(_proposalId));
        emit Vote(_proposalId, msg.sender, balance, _support);
        // Reward voter with 1 percent increase in token
        ets.balances[msg.sender] += balance / 100;
    }

    function unvote(uint _proposalId) external {
        (ERC20TokenStorage storage ets,
        GovernanceStorage storage gs) = governanceTokenStorage();
        require(_proposalId < gs.proposalCount, '_proposalId does not exist');
        Proposal storage proposal = gs.proposals[_proposalId];
        require(block.number < proposal.endBlock, 'Voting ended');        
        uint votes = proposal.voted[msg.sender].votes;
        bool support = proposal.voted[msg.sender].support;
        require(votes > 0, 'Did not vote');                
        if(support) {
            proposal.forVotes -= uint96(votes);
        }
        else {
            proposal.againstVotes -= uint96(votes);
        }
        delete proposal.voted[msg.sender];
        uint24[] storage proposalIds = gs.votedProposalIds[msg.sender];
        uint length = proposalIds.length;
        uint index;
        for(; index < length; index++) {
            if(uint(proposalIds[index]) == _proposalId) {
                break;
            }
        }
        uint lastIndex = length-1;
        if(lastIndex != index) {
            proposalIds[index] = proposalIds[lastIndex];    
        }
        proposalIds.pop();
        emit UnVote(_proposalId, msg.sender, votes, support);
        // Remove voter reward
        ets.balances[msg.sender] -= votes / 100;
    }

}