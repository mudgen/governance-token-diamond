// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Diamond } from './Diamond.sol';
import { ERC20TokenStorageContract } from '../storage/ERC20TokenStorageContract.sol';
import { GovernanceStorageContract } from '../storage/GovernanceStorageContract.sol';

contract InternalFunctions is Diamond, ERC20TokenStorageContract, GovernanceStorageContract {
    function governanceTokenStorage() internal pure returns(
        ERC20TokenStorage storage ets, 
        GovernanceStorage storage gs
    ) {
        bytes32 position = ERC20TOKEN_STORAGE_POSITION;
        assembly { ets.slot := position }
        position = GOVERNANCE_STORAGE_POSITION;
        assembly { gs.slot := position }        
    }
    

    function balance(address _user) returns (uint) {
            

        
        
    }

}