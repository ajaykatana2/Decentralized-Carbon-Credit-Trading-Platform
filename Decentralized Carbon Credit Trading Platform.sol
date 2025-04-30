// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title CarbonCreditExchange
 * @dev Simple carbon credit trading platform
 */
contract CarbonCreditExchange {
    address public owner;
    
    // Structure to store carbon credit metadata
    struct CarbonCredit {
        uint256 id;
        string projectName;
        string projectType; // solar, wind, reforestation, etc.
        string location;
        uint256 carbonAmount; // in tons of CO2
        address issuer;
    }
    
    // Counter for token IDs
    uint256 private _nextTokenId;
    
    // Mapping from token ID to its details
    mapping(uint256 => CarbonCredit) public carbonCredits;
    
    // Mapping from address to its token balances (tokenId => amount)
    mapping(address => mapping(uint256 => uint256)) public balances;
    
    // Verifiers who can approve carbon credit projects
    mapping(address => bool) public verifiers;
    
    // Events
    event CreditIssued(uint256 indexed tokenId, address indexed issuer, uint256 amount);
    event CreditTraded(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event CreditRetired(uint256 indexed tokenId, address indexed retirer, uint256 amount);
    
    // Modifier to restrict function access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Modifier to restrict function access to verifiers
    modifier onlyVerifier() {
        require(verifiers[msg.sender], "Only verified issuers can call this function");
        _;
    }
    
    /**
     * @dev Constructor that sets up the contract with initial settings
     */
    constructor() {
        owner = msg.sender;
        verifiers[msg.sender] = true; // Add the contract creator as the first verifier
        _nextTokenId = 1;
    }
    
    /**
     * @dev Issues new carbon credits after project verification
     * @param _projectName Name of the carbon offset project
     * @param _projectType Type of project (solar, wind, reforestation)
     * @param _location Geographic location of the project
     * @param _carbonAmount Amount of carbon offset in tons
     * @param _amount Number of tokens to mint
     * @return newTokenId The ID of the newly created token
     */
    function issueCarbonCredit(
        string memory _projectName,
        string memory _projectType,
        string memory _location,
        uint256 _carbonAmount,
        uint256 _amount
    ) external onlyVerifier returns (uint256) {
        uint256 newTokenId = _nextTokenId;
        _nextTokenId++;
        
        // Create new carbon credit
        carbonCredits[newTokenId] = CarbonCredit({
            id: newTokenId,
            projectName: _projectName,
            projectType: _projectType,
            location: _location,
            carbonAmount: _carbonAmount,
            issuer: msg.sender
        });
        
        // Mint tokens to the issuer
        balances[msg.sender][newTokenId] += _amount;
        
        emit CreditIssued(newTokenId, msg.sender, _amount);
        
        return newTokenId;
    }
    
    /**
     * @dev Retire carbon credits (mark as used for offsetting)
     * @param _tokenId ID of the token to retire
     * @param _amount Amount of tokens to retire
     */
    function retireCarbonCredit(uint256 _tokenId, uint256 _amount) external {
        require(balances[msg.sender][_tokenId] >= _amount, "Not enough tokens to retire");
        
        // Burn the tokens (permanently retire)
        balances[msg.sender][_tokenId] -= _amount;
        
        emit CreditRetired(_tokenId, msg.sender, _amount);
    }
    
    /**
     * @dev Add or remove addresses from the verifiers list
     * @param _verifier Address to update
     * @param _isVerifier Boolean indicating if address should be a verifier
     */
    function manageVerifier(address _verifier, bool _isVerifier) external onlyOwner {
        verifiers[_verifier] = _isVerifier;
    }
}
