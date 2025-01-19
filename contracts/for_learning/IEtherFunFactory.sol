// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

interface IEtherFunFactory {
    event SaleCreated(
        address indexed saleContractAddress,
        address indexed creator,
        string name,
        string symbol,
        uint256 saleGoal,
        string logoUrl,
        string websiteUrl, 
        string twitterUrl, 
        string telegramUrl, 
        string description,
        string[] relatedLinks
    );

    event SaleLaunched(address indexed saleContractAddress, address indexed launcher);
    event Claimed(address indexed saleContractAddress, address indexed claimant);
    event MetaUpdated(address indexed saleContractAddress, string logoUrl, string websiteUrl, string twitterUrl, string telegramUrl, string description);
    event TokensBought(address indexed saleContractAddress, address indexed buyer, uint256 totalRaised, uint256 tokenBalance);
    event TokensSold(address indexed saleContractAddress, address indexed seller, uint256 totalRaised, uint256 tokenBalance);

    function createSale(
        string memory name, 
        string memory symbol,
        string memory logoUrl,
        string memory websiteUrl,
        string memory twitterUrl,
        string memory telegramUrl,
        string memory description,
        string[] memory relatedLinks,
        string memory message
    ) external payable;

    function buyToken(address saleContractAddress, uint256 minTokensOut, string memory message) external payable;

    function sellToken(address saleContractAddress, uint256 tokenAmount, uint256 minEthOut) external;

    function claim(address saleContractAddress) external;

    function setSaleMetadata(
        address saleContractAddress,
        string memory logoUrl,
        string memory websiteUrl,
        string memory twitterUrl,
        string memory telegramUrl,
        string memory description
    ) external;

    function getUserBoughtTokens(address user) external view returns (address[] memory);

    function getSaleMetadata(address saleContractAddress) external view returns (Storage.SaleMetadata memory);

    function getCurrentNonce(address user) external view returns (uint256);

    function getCreatorTokens(address creator) external view returns (address[] memory);

    function predictTokenAddress(
        address creator,
        string memory name,
        string memory symbol,
        uint256 nonce
    ) external view returns (address);

    function updateParameters(
        uint256 _defaultSaleGoal,
        uint256 _defaultK,
        uint256 _defaultAlpha,
        address _launchContractAddress,
        uint8 _buyLpFee,
        uint8 _sellLpFee,
        uint8 _buyProtocolFee,
        uint8 _sellProtocolFee
    ) external;
} 