// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of an ERC20 governance token that can govern itself and a project
* using the Diamond Standard.
/******************************************************************************/

import { InternalFunctions } from './lib/InternalFunctions.sol';
import { IDiamondLoupe } from './interfaces/IDiamondLoupe.sol';
import { IERC165 } from './interfaces/IERC165.sol';
import { DiamondLoupe } from './facets/DiamondLoupe.sol';
import { Diamond, DiamondStorageContract } from './lib/Diamond.sol';

contract GovernanceTokenDiamond is InternalFunctions {  
    
    constructor() {
        erc20TokenStorage().totalSupply = 100_000_000e18;        

        // Create a DiamondLoupeFacet contract which implements the Diamond Loupe interface
        DiamondLoupe diamondLoupe = new DiamondLoupe();   

        bytes[] memory cut = new bytes[](1);
        
        // Adding diamond loupe functions                
        cut[0] = abi.encodePacked(
            diamondLoupe,
            IDiamondLoupe.facetFunctionSelectors.selector,
            IDiamondLoupe.facets.selector,
            IDiamondLoupe.facetAddress.selector,
            IDiamondLoupe.facetAddresses.selector,
            IERC165.supportsInterface.selector            
        );    
        
        diamondCut(cut);
        
        // adding ERC165 data
        DiamondStorage storage ds = diamondStorage();
        ds.supportedInterfaces[IERC165.supportsInterface.selector] = true;        
        bytes4 interfaceID = IDiamondLoupe.facets.selector ^ IDiamondLoupe.facetFunctionSelectors.selector ^ IDiamondLoupe.facetAddresses.selector ^ IDiamondLoupe.facetAddress.selector;
        ds.supportedInterfaces[interfaceID] = true;
    }  

    // Finds facet for function that is called and executes the
    // function if it is found and returns any value.
    fallback() external payable {        
        DiamondStorage storage ds;
        bytes32 position = DiamondStorageContract.DIAMOND_STORAGE_POSITION;           
        assembly { ds.slot := position }
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Function does not exist.");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), facet, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }

    receive() external payable {
    }
}
  