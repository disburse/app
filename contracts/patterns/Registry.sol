// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract Registry {
    
    address admin;
    mapping(string => address) public contracts;
    
    constructor() public {
        admin = msg.sender;
    }
    
    // Calldata is a read-only byte array.
    // Memory is a byte array.
    function updateContract(string memory id, address contractAddress) public {
        require(msg.sender == admin);
        contracts[id] = contractAddress;
    }
 
    // Example retrieving contract from Registry:
    // 
    // Registry registry;
    // Token token = Token(registry.contracts("CONTRACT_NAME"));
    
    // Example updating Registry in a contract using it:
    //
    // function updateRegistry(address registryAddress) public {
    //   require(msg.sender == admin);
    //   registry = Registry(registryAddress);
    // }
    
}