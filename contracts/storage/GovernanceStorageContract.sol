// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract GovernanceStorageContract {           

    bytes32 internal constant GOVERNANCE_STORAGE_POSITION = keccak256("governance.token.diamond.governance");
    
    struct Voted {        
        uint96 votes;
        bool support;
    }
    
    struct Proposal {
        address proposer;        
        address proposalContract;                
        uint64 endTime;
        bool executed;
        uint96 againstVotes;
        uint96 forVotes;                     
        mapping(address => Voted) voted;
    }   
    
    struct GovernanceStorage {
        uint24 proposalCount;        
        mapping(uint => Proposal) proposals;
        mapping(address => uint24[]) votedProposalIds;
    }

    function governanceStorage() internal pure returns(GovernanceStorage storage ds) {
        bytes32 position = GOVERNANCE_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
}
