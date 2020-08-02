// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of an example of a diamond.
/******************************************************************************/

import { DiamondStorageContract } from './storage/DiamondStorageContract.sol';
import { IDiamond } from './interfaces/IDiamond.sol';
import { IDiamondLoupe } from './interfaces/IDiamondLoupe.sol';
import { IERC165 } from './interfaces/IERC165.sol';
import { DiamondFacet } from './facets/DiamondFacet.sol';
import { DiamondLoupeFacet } from './facets/DiamondLoupeFacet.sol';

contract DiamondGovernanceToken is DiamondStorageContract {  
    
    constructor() {
        DiamondStorage storage ds = diamondStorage();        

        // Create a DiamondFacet contract which implements the Diamond interface
        DiamondFacet diamondFacet = new DiamondFacet();

        // Create a DiamondLoupeFacet contract which implements the Diamond Loupe interface
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();   

        bytes[] memory diamondCut = new bytes[](3);

        // Adding cut function
        diamondCut[0] = abi.encodePacked(diamondFacet, IDiamond.diamondCut.selector);

        // Adding diamond loupe functions                
        diamondCut[1] = abi.encodePacked(
            diamondLoupeFacet,
            IDiamondLoupe.facetFunctionSelectors.selector,
            IDiamondLoupe.facets.selector,
            IDiamondLoupe.facetAddress.selector,
            IDiamondLoupe.facetAddresses.selector            
        );    

        // Adding supportsInterface function
        diamondCut[2] = abi.encodePacked(address(this), IERC165.supportsInterface.selector);

        // execute cut function
        bytes memory cutFunction = abi.encodeWithSelector(IDiamond.diamondCut.selector, diamondCut);
        (bool success,) = address(diamondFacet).delegatecall(cutFunction);
        require(success, "Adding functions failed.");        

        // adding ERC165 data
        ds.supportedInterfaces[IERC165.supportsInterface.selector] = true;
        ds.supportedInterfaces[IDiamond.diamondCut.selector] = true;
        bytes4 interfaceID = IDiamondLoupe.facets.selector ^ IDiamondLoupe.facetFunctionSelectors.selector ^ IDiamondLoupe.facetAddresses.selector ^ IDiamondLoupe.facetAddress.selector;
        ds.supportedInterfaces[interfaceID] = true;
    }

    // This is an immutable functions because it is defined directly in the diamond.
    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return ds.supportedInterfaces[_interfaceID];
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
  