# Contracts used in Scooptimes

## Directory Tree
```
contracts
├── Factory.sol
├── NewsComment.sol
├── PositionToken.sol
├── SaleContract.sol
├── interfaces
    ├── IERC20.sol
    ├── IUniswapV2Router01.sol
    ├── IWETH.sol
```

## Contracts Details

### Factory.sol (EtherFunFactory)

- **Sale Management**: Creation of sales and setting metadata
  - `createSale(...) external payable;`
  - `setSaleMetadata(...) external;`

- **Token Transactions**: Purchase, sale, and claim of tokens
  - `buyToken(...) external payable;`
  - `sellToken(...) external;`
  - `claim(...) external;`

- **Retrieving User and Sale Information**: Functions to retrieve information related to users and sales.
  - `getUserBoughtTokens(...) external view returns (address[] memory);`
  - `getSaleMetadata(...) external view returns (Storage.SaleMetadata memory);`
  - `getCurrentNonce(...) external view returns (uint256);`
  - `getCreatorTokens(...) external view returns (address[] memory);`
  - `predictTokenAddress(...) external view returns (address);`

- **Updating Parameters**: Functions to update default parameters for sales and tokens.
  - `updateParameters(...) external;`


### NewsComment.sol
Omitted due to being unimplemented?

### PositionToken.sol

Omitted (Equivalent to ERC20)

### SaleContract.sol (EtherfunSale)

- **Token Transactions**: Purchase, sale, and claim of tokens
  - `buy(address user, uint256 minTokensOut, string memory message) external payable returns (uint256, uint256);`
  - `sell(address user, uint256 tokenAmount, uint256 minEthOut) external returns (uint256, uint256);`
  - `claimTokens(address user) external;`

- **Sale Management**: Launching of sales
  - `launchSale(address _launchContract, address firstBuyer, address saleInitiator) external;`

- **Retrieving Information**: Retrieval of token holders and historical data
  - `getAllTokenHolders() external view returns (address[] memory);`
  - `getAllHistoricalData() external view returns (HistoricalData[] memory);`

- **Price Calculation**: Calculation of exchange rates between tokens and ETH
  - `getEthIn(uint256 tokenAmount) external view returns (uint256);`
  - `getTokenIn(uint256 ethAmount) external view returns (uint256);`
