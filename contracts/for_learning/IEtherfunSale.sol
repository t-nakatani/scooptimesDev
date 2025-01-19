// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEtherfunSale {
    //==== Structs ====
    struct HistoricalData {
        uint256 timestamp;
        uint256 totalRaised;
    }

    //==== Events ====
    event TokensPurchased(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount,
        string message,
        uint256 timestamp
    );
    
    event TokensSold(
        address indexed seller,
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 timestamp
    );

    event TokenLaunched(
        address indexed saleContract,
        address indexed negativeToken,
        address indexed positiveToken,
        uint256 perTokenAmount,
        uint256 timeStamp
    );

    event Comment(
        address indexed commenter,
        string comment,
        uint256 negative,
        uint256 positive,
        uint256 timestamp
    );

    //==== State variable getters ====
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function positiveToken() external view returns (address);
    function negativeToken() external view returns (address);
    function creator() external view returns (address);
    function factory() external view returns (address);
    function totalTokens() external view returns (uint256);
    function totalRaised() external view returns (uint256);
    function maxContribution() external view returns (uint256);
    function creatorshare() external view returns (uint8);
    function launched() external view returns (bool);
    function status() external view returns (bool);
    function k() external view returns (uint256);
    function alpha() external view returns (uint256);
    function saleGoal() external view returns (uint256);
    function tokensSold() external view returns (uint256);

    // tokenBalances: mapping(address => uint256)
    function tokenBalances(address user) external view returns (uint256);

    //==== External functions ====
    function getEthIn(uint256 tokenAmount) external view returns (uint256);
    function getTokenIn(uint256 ethAmount) external view returns (uint256);

    function buy(address user, uint256 minTokensOut, string memory message) external payable returns (uint256, uint256);

    function sell(address user, uint256 tokenAmount, uint256 minEthOut) external returns (uint256, uint256);

    function launchSale(address _launchContract, address firstBuyer, address saleInitiator) external;

    function claimTokens(address user) external;

    function getAllTokenHolders() external view returns (address[] memory);

    function getAllHistoricalData() external view returns (HistoricalData[] memory);
}
