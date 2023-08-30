# FOUNDRY RAFFLE
### A Fare Lottery for Everyone, Anyone can Participate into it. Only One Participant will be the Owner and take All Funds as a Reward.

<br>
<br>

# Getting Started

## Requirements

- Foundry
    - [Foundry Installation](https://book.getfoundry.sh/getting-started/installation), **Please Follow thoroughly.**
    - **For Windows Users Only**: After Installing all necessities, You'll would need to install `WSL` extension into your vscode. In extensions tab, Please make search for wsl and install One Provided by `Microsoft`. After extension installation you might needed to have a reload|restart (vscode), After restarting|reloading vscode you would need to click onto bottom left corner icon, that will ask you to open remote wsl, After this a new vscode instance will appear onto the top of your Screen. Since after, Please (`Terminal|Bash`) `cd` to the directory where you want to keep your Project -> Create Your Project Folder -> `cd` into that -> execute `code .` <- (code space_bar( ) period(.))

- git
    - [Mac](https://sourceforge.net/projects/git-osx-installer/files/) Installer.
    - [Windows](https://gitforwindows.org/) Installer.
    - After Successful Installation, You can check if `git` installed successfully or not into your machine by checking its version into terminal. - Output `git version x.y.z`
        ```terminal
        git --version
        ```
    
    - Now You'll need to Configure Your `Username` & `Email` through Your Terminal.
        ```terminal
        git config --global user.name Alice
        ```
    - Hit Enter ⌨
        ```terminal
        git config --global user.email alice@notexist.com
        ```
    - Hit Enter ⌨
    - You can Check Configured `Username` & `Email` via using following command. `query:name|email`
        ```terminal
        git config user.query
        ```
    - Congratulations!

- Make(OPTIONAL|If You Like)
    - Execute Command below into your terminal. Note: Password shall not be visible whilst Typing ~ Please Make Correct Blind Presses.
    ```terminal
    sudo apt-get install make
    ```

<br>

## Quickstart
```terminal
git clone https://github.com/theirrationalone/foundry-raffle.git
cd foundry-raffle
forge build
```

<br>

# Usage

## Deploy:

```
forge script script/DeployRaffle.s.sol
```

## Testing

We talk about 4 test tiers in the video. 

1. Unit
2. Integration
3. Forked
4. Staging
5. Fuzz Invariant Stateful Testing

This repo we cover #1, #2, #3 and #5.


```
forge test
```

or 

```
// Only run test functions matching the specified regex pattern.

forge test --match-test testFunctionName
--mt akin for --match-test
```

or

```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

```
forge coverage
```


# Deployment to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

3. Deploy

```
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

## Scripts

After deploying to a testnet or local net, you can run the scripts. 

Using cast deployed locally example: 

```
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.001 ether --private-key <PRIVATE_KEY>
```

or
```
forge script script/Interactions.s.sol:<SCRIPT_CONTRACT_NAME> --rpc-url sepolia  --private-key $PRIVATE_KEY  --broadcast
```

### addPerson

```
cast send <RAFFLE_CONTRACT_ADDRESS> "performUpkeep(string)" 0x0 --rpc-url $ANVIL_RPC_URL --private-key $PRIVATE_KEY
```

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`


# Formatting


To run code formatting:
```
forge fmt
```

<br>
<br>
<br>
<br>

# Thank you! :) 🏴‍☠️ 🛠
