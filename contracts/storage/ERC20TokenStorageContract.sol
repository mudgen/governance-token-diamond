// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract ERC20TokenStorageContract {           

    bytes32 internal constant ERC20TOKEN_STORAGE_POSITION = keccak256("governance.token.diamond.ERC20Token");
    
    struct ERC20TokenStorage {  
        uint96 totalSupplyCap;      
        uint96 totalSupply;
        // calculation formula: a = (95 / 100) root 31556952 or 0.95 ^ (1/31556952)
        // 5 percent per year: 1000000001625419794
        // 3 percent per year: 1000000000965213861
        // 2 percent per year: 1000000000640198309
        uint64 deflationaryRate;
        mapping(address => uint) balances;      
        mapping(address => mapping(address => uint)) approved;        
    }

    function erc20TokenStorage() internal pure returns(ERC20TokenStorage storage ds) {
        bytes32 position = ERC20TOKEN_STORAGE_POSITION;
        assembly { ds.slot := position }
    }    
}

/*
## Deflation Math

To determine the deflation rate for a yearly percent use this formula:
 
deflation fraction rate = ((100 - RATE) / 100) ^ (1/31556952)

Use a high percision calculator like this one: https://keisan.casio.com/calculator

Then this fraction rate is converted into an unint we can use with this formula:

deflation rate = uint(100e38) / deflation fraction rate;

Example:
Get the deflationary rate for 2 percent per year.

1. 0.9999999993598016908904 = ((100 - 2) / 100) ^ (1/31556952)

2. 1000000000640198309 = uint(100e38) / 9999999993598016908904;

Use this formula to check that it is right:

98.00000000160643069345 = 100 / 1.000000000640198309^31556952

----------------

Get the deflationary rate for 3 percent per year.

1. 0.9999999990347861393582 = ((100 - 3) / 100) ^ (1/31556952)

2. 1000000000965213861 = uint(100e38) / 9999999990347861393582;

Check it:

97.00000000175537975818 = 100 / 1.000000000965213861^31556952


*/