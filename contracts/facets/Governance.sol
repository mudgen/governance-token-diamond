// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { IERC20 } from '../interfaces/IERC20.sol';
import { InternalFunctions } from '../lib/InternalFunctions.sol';



contract Governance is InternalFunctions {
    
    event Vote(uint indexed _proposalId, address indexed _voter, uint _votes, bool _support);
    event UnVote(uint indexed _proposalId, address indexed _voter, uint _votes, bool _support);  
    
    function mint(address _to, uint96 _value) internal {
        ERC20TokenStorage storage ets = erc20TokenStorage();        
        ets.totalSupply += _value;
        ets.balances[_to] += _value;
    }

    function proposalCount() external view returns (uint) {
        return governanceStorage().proposalCount;
    }

    function propose(address _proposalContract, uint _endTime) external {
        (ERC20TokenStorage storage ets,
        GovernanceStorage storage gs) = governanceTokenStorage();        
        require(_endTime > block.timestamp + (gs.minimumVotingTime * 3600), 'Governance: Voting time must be longer');
        require(_endTime < block.timestamp + (gs.maximumVotingTime * 3600), 'Governance: Voting time must be shorter');
       
        uint balance = ets.balances[msg.sender];
        uint totalSupply = ets.totalSupply;
        // proposalThreshold is 1 percent of totalSupply
        require(balance >= (totalSupply / gs.proposalThresholdDivisor), 'Governance: Balance less than proposer threshold');
        uint proposalId = gs.proposalCount++;
        Proposal storage proposal = gs.proposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.proposalContract = _proposalContract;
        proposal.endTime = uint64(_endTime);
        // adding vote
        proposal.forVotes = uint96(balance);
        proposal.voted[msg.sender] = Voted(uint96(balance), true);
        gs.votedProposalIds[msg.sender].push(uint24(proposalId));
        emit Vote(proposalId, msg.sender, balance, true);
    }

    function executeProposal(uint _proposalId) external {
        (ERC20TokenStorage storage ets,
        GovernanceStorage storage gs) = governanceTokenStorage();
        Proposal storage proposal = gs.proposals[_proposalId];
        address proposer = proposal.proposer;
        require(proposer != address(0), 'Governance: Proposal does not exist');
        require(block.timestamp > proposal.endTime, 'Governance: Voting hasn\'t ended');        
        require(proposal.executed != true, 'Governance: Proposal has already been executed');
        proposal.executed = true;        
        uint totalSupply = ets.totalSupply;
        uint forVotes = proposal.forVotes;
        uint againstVotes = proposal.againstVotes;
        bool proposalSuccess = forVotes > againstVotes && forVotes > ets.totalSupply / gs.quorumDivisor;
        uint votes = proposal.voted[proposer].votes;        
        if(proposalSuccess) {
            (proposalSuccess,) = proposal.proposalContract.delegatecall(abi.encodeWithSignature('execute', _proposalId));
        }
        if(proposalSuccess) {
            if(totalSupply < ets.totalSupplyCap) {
                uint fractionOfTotalSupply = totalSupply / gs.voteAwardCapDivisor;
                if(votes > fractionOfTotalSupply) {
                    votes = fractionOfTotalSupply;
                }
                // 5 percent reward
                uint proposerAwardDivisor = gs.proposerAwardDivisor;
                ets.totalSupply += uint96(votes / proposerAwardDivisor);
                ets.balances[proposer] += votes / proposerAwardDivisor;
            }
        }
        else {
            ets.balances[proposer] -= votes;
        }
    }

    enum ProposalStatus { 
        NoProposal,
        PassedAndReadyForExecution, 
        RejectedAndReadyForExecution,
        VotePending,
        Passed,  
        Rejected        
    }

    function proposalStatus(uint _proposalId) external view returns (ProposalStatus status) {
        (ERC20TokenStorage storage ets,
        GovernanceStorage storage gs) = governanceTokenStorage();
        Proposal storage proposal = gs.proposals[_proposalId];
        uint endTime = proposal.endTime;
        if(endTime == 0) {
            status = ProposalStatus.NoProposal;
        }
        else if(block.number < endTime) {
            status = ProposalStatus.VotePending;
        }
        else {
            uint forVotes = proposal.forVotes;
            bool passed = forVotes > proposal.againstVotes && forVotes > ets.totalSupply / gs.quorumDivisor;
            if(proposal.executed) {
                if(passed) {
                    status = ProposalStatus.Passed;
                }
                else {
                    status = ProposalStatus.Rejected;
                }
            }
            else {
                if(passed) {
                    status = ProposalStatus.PassedAndReadyForExecution;
                }
                else {
                    status = ProposalStatus.RejectedAndReadyForExecution;
                }
            }
        }
    }

    function vote(uint _proposalId, bool _support) external {
        (ERC20TokenStorage storage ets,
        GovernanceStorage storage gs) = governanceTokenStorage();
        require(_proposalId < gs.proposalCount, 'Governance: _proposalId does not exist');
        Proposal storage proposal = gs.proposals[_proposalId];
        require(block.timestamp < proposal.endTime, 'Governance: Voting ended');
        require(proposal.voted[msg.sender].votes == 0, 'Governance: Already voted');        
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
        uint totalSupply = ets.totalSupply;
        if(totalSupply < ets.totalSupplyCap) {
            // Reward voter with increase in token            
            uint fractionOfTotalSupply = ets.totalSupply / gs.voteAwardCapDivisor;
            if(balance > fractionOfTotalSupply) {
                balance = fractionOfTotalSupply;
            }
            uint voterAwardDivisor = gs.voterAwardDivisor;
            ets.totalSupply += uint96(balance / voterAwardDivisor);
            ets.balances[msg.sender] += balance / voterAwardDivisor;
        }
    }

    function unvote(uint _proposalId) external {
        (ERC20TokenStorage storage ets,
        GovernanceStorage storage gs) = governanceTokenStorage();
        require(_proposalId < gs.proposalCount, 'Governance: _proposalId does not exist');
        Proposal storage proposal = gs.proposals[_proposalId];
        require(block.timestamp < proposal.endTime, 'Governance: Voting ended');        
        uint votes = proposal.voted[msg.sender].votes;
        bool support = proposal.voted[msg.sender].support;
        require(votes > 0, 'Governance: Did not vote');                
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
        uint voterAwardDivisor = gs.voterAwardDivisor;
        ets.totalSupply -= uint96(votes / voterAwardDivisor);
        ets.balances[msg.sender] -= votes / voterAwardDivisor;
    }

}