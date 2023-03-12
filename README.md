# PengolinNft

This project uses Hardhat and Solidity

## HOW TO DEPLOY THE CONTRACTS:

Step 1 (Enable the correct verison of node)
Use Node v16.14.0 in all windows

Step 2 (Download / clone project)
```sh
git clone this repository
```
or
```sh
git pull origin master
```

Step 3 (Install dependences)
```sh
yarn install
```

Step 4 (Clean local artifacts)
Terminal window #1
```sh
npx hardhat clean
```

Step 5 (Run local blockchain)
Terminal window #1
```sh
npx hardhat node
```

Step 6 (Deploy Auction and NFT contracts)
Terminal window #2
```sh
npx hardhat run scripts/deploy.js --network localhost
```
• Settings for the contract can be found in deploy.js

## CONTRACT FILES:
• /contracts/PengolinNft.sol
