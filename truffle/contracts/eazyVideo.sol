// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./SubsNFT.sol";

/** @title eazyVideo
 * @notice It is a contract for managing eazyVideo platform
 */

contract EazyVideo is eazyVideoNFTContract {
    constructor(address _ERC4907ContractAddress)
        eazyVideoNFTContract(_ERC4907ContractAddress)
    {}

    // For only service providers
    struct Service {
        string name;
        string ImageUri;
        string description;
        uint64 planDuration;
        uint256 price;
    }

    // For user type
    struct User {
        // Plan nfts of users
        mapping(uint256 => Service) availablePlans;
        uint256 availablePlansSize;
        // For Lend nfts of users that are available for rent for a specific time.
        mapping(uint256 => Service) forLendPlans;
        uint256 forLendPlansSize;
    }

    Service[] public services;
    User[] users;

    // True for Service provider, False for a User
    mapping(address => uint256) public accountType;
    // user wallet address to user array index
    mapping(address => uint256) internal userToId;
    //service provider wallet address to index in services array
    mapping(address => uint256) public serviceProviderToId;

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return memcmp(bytes(a), bytes(b));
    }

    /**
     * @notice modifier to check if user is valid
     */
    modifier onlyUser() {
        require(accountType[msg.sender] == 1, "Not a user");
        _;
    }

    /**
     * @notice modifier to check if service provider is valid
     */
    modifier onlyServiceProvider() {
        require(accountType[msg.sender] == 2, "Not a service Provider");
        _;
    }

    function getAccountType() public view returns (uint256) {
        return accountType[msg.sender];
    }

    function addToPlatform(uint256 _accountType)
        public
        returns (string memory)
    {
        require(getAccountType() == 0, "YOU ARE ALREADY REGISTERED");
        accountType[msg.sender] = _accountType;
        // serviceProvider
        if (accountType[msg.sender] == 2) {
            Service storage newService = services.push();

            newService.name = "";
            newService.ImageUri = "";
            newService.description = "";
            newService.planDuration = 0;
            newService.price = 0;

            serviceProviderToId[msg.sender] = services.length - 1;
            return "NEW SERVICE PROVIDER ADDED";
        }
        //user
        else {
            User storage newUser = users.push();

            newUser.availablePlansSize = 0;
            newUser.forLendPlansSize = 0;

            userToId[msg.sender] = users.length - 1;
            return "NEW USER ADDED";
        }
    }

    function updateServiceName(
        string memory _name,
        string memory _ImageUri,
        string memory _description,
        uint64 _planDuration,
        uint256 _planPrice
    ) public onlyServiceProvider returns (bool) {
        Service storage service = services[serviceProviderToId[msg.sender]];

        service.name =  _name;
        service.ImageUri =  _ImageUri;
        service.description =  _description;
        service.planDuration =  _planDuration;
        service.price= _planPrice;

        return true;
    
    }


    /**
     * @notice method to buy service from service providers
     */
    function BuyServiceFromServiceProvider(
        address _serviceProviderWallet
    ) public payable onlyUser {
        Service storage service = services[
            serviceProviderToId[_serviceProviderWallet]
        ];

        string memory _name = service.name;
        string memory _ImageUri = service.ImageUri;
        uint64 _time = uint64(block.timestamp) + service.planDuration;
        uint256 _price = service.price;
        string memory _description = service.description;

        payable(_serviceProviderWallet).transfer(_price);

        // Mint a expirable NFT
        // mintNFT(
        //     _name,
        //     _ImageUri,
        //     _description,
        //     service.planDuration,
        //     _time,
        //     _price,
        //     msg.sender,
        //     _serviceProviderWallet
        // );
    }

    /**
     * @notice method to lend the nfts for rents in thier profile by giving the time lending for
     * User can’t rent a nft for time more than he owns it - This requires a check from a nft metadata
     */
    function LendPlan(
        uint256 _price,
        uint256 _days,
        string memory _name
    ) public onlyUser {
        User storage user = users[userToId[msg.sender]];

        for (uint256 i = 0; i < user.availablePlansSize - 1; i++) {
            if (strcmp(user.availablePlans[i].name, _name)) {
                user.forLendPlans[user.forLendPlansSize] = Service({
                    price: _price,
                    name: _name,
                    ImageUri: user.availablePlans[i].ImageUri,
                    description: user.availablePlans[i].description,
                    planDuration: uint64(_days)
                });

                // delete from available plans
            }
        }
    }

    /**
     * @notice This method can be called by only a user wallet address to rent the
     * available nfts by giving the days user is renting it for and giving the amount to
     * the nft owner
     */
    function RentPlan(
        uint256 tokenID,
        uint256 _amount,
        uint64 _days // _days multiplied by per day amount is total amount
    ) public onlyUser {
        rentNFT(tokenID, _amount, _days);
    }
}
