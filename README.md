# hardhat-nft-marketplace

## Run scripts

<br/>

 ### Compile smart contracts
 ```sh
yarn hardhat compile
 ```
or if you have shortcut
 ```sh
hh compile
 ```

 ### Check tests
 ```sh
yarn hardhat test
 ```
### Check test coverage
 ```sh
yarn hardhat coverage
 ```

### smth
 ```sh
yarn hardhat run scripts/mint-and-list-item.js --network localhost
 ```

 ### Run localhost hardhat node
 ```sh
yarn hardhat node
```


## Tokens

Tokens folder contains a json values of the NFT token URI.

Steps to create an NFT:

1. Choose an image
2. Add it to the IPFS Desktop (and get link)
3. Create a new json at /tokens as the attributes & values for the new NFT (take a look on some examples)
4. Add that json to the IPFS Desktop to get TOKEN_URI
5. Take a look on the /contracts/test & see some of the basic nft examples
6. You can copy paste entire example & change token_uri with your new fresh generated token uri
7. Update /deploy/02-deploy-basic-nft with name of your nft file
8. Now you can deploy that to the goerli (with tags basicnft that is added in deploy scripts for basicnft deploy)

    ```sh
        hh deploy --tags basicnft --network goerli
    ```
    