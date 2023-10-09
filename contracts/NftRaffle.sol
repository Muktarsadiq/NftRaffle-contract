// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftRaffle {
    address public owner;
    uint256 public entryCost;
    address public nftAddress;
    uint256 public nftId;
    uint256 public totalEntries;
    bool public raffleStatus;

    mapping(address => uint256) public entryCount;
    mapping(address => uint256) private userBalances;
    address[] public players;
    address[] public playerSelector;

    event NewEntry(address player);
    event RaffleStarted();
    event RaffleEnded();
    event WinnerSelected(address winner);
    event EntryCostChange(uint256 newCost);
    event NftPriceSet(address nftAddress, uint256 nftId);
    event BalanceWithdrawn(address user, uint256 amount);

    constructor(uint256 _entryCost) {
        owner = msg.sender;
        entryCost = _entryCost;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier raffleInProgress() {
        require(raffleStatus, "Raffle has not started");
        _;
    }

    modifier raffleNotInProgress() {
        require(!raffleStatus, "Raffle is still running");
        _;
    }

    modifier hasEnoughBalance(uint256 _amount) {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        _;
    }

    modifier nftNotSet() {
        require(nftAddress == address(0), "NFT prize already set");
        _;
    }

    modifier isNftOwner() {
        require(
            IERC721(nftAddress).ownerOf(nftId) == owner,
            "Contract does not own the NFT"
        );
        _;
    }

    function startRaffle(address _nftContract, uint256 _tokenId)
        public
        onlyOwner
        nftNotSet
    {
        nftAddress = _nftContract;
        nftId = _tokenId;
        raffleStatus = true;
        emit RaffleStarted();
        emit NftPriceSet(_nftContract, _tokenId);
    }

    function buyEntry(uint256 _numberOfEntries)
        public
        payable
        raffleInProgress
    {
        uint256 cost = entryCost * _numberOfEntries;
        require(msg.value == cost, "Incorrect amount sent");

        entryCount[msg.sender] += _numberOfEntries;
        totalEntries += _numberOfEntries;

        if (!isPlayer(msg.sender)) {
            players.push(msg.sender);
        }

        for (uint256 i = 0; i < _numberOfEntries; i++) {
            playerSelector.push(msg.sender);
        }

        emit NewEntry(msg.sender);

        // Update the user's balance and contract's balance
        userBalances[msg.sender] += msg.value;
        userBalances[owner] += msg.value;
    }

    function isPlayer(address _player) public view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == _player) {
                return true;
            }
        }
        return false;
    }

    function endRaffle() public onlyOwner raffleInProgress {
        raffleStatus = false;
        emit RaffleEnded();
    }

    function selectWinner() public onlyOwner raffleNotInProgress {
        require(playerSelector.length > 0, "There are no players");
        require(nftAddress != address(0), "NFT prize is not set");

        uint256 winnerIndex = randomNumber() % playerSelector.length;
        address winner = playerSelector[winnerIndex];
        emit WinnerSelected(winner);

        // Perform effects first before interactions
        resetEntryCounts();
        delete playerSelector;
        delete players;
        nftAddress = address(0);
        nftId = 0;
        totalEntries = 0;

        // Transfer funds to the winner
        userBalances[winner] += userBalances[owner];
        userBalances[owner] = 0;
    }

    function randomNumber() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function resetEntryCounts() private onlyOwner {
        for (uint256 i = 0; i < players.length; i++) {
            entryCount[players[i]] = 0;
        }
    }

    function changeEntryCost(uint256 _newCost)
        public
        onlyOwner
        raffleNotInProgress
    {
        entryCost = _newCost;
        emit EntryCostChange(_newCost);
    }

    function withdrawBalance() public hasEnoughBalance(1 wei) {
        uint256 amount = userBalances[msg.sender];
        userBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit BalanceWithdrawn(msg.sender, amount);
    }

    function ownerWithdraw() public onlyOwner {
        uint256 balanceAmount = userBalances[owner];
        require(balanceAmount > 0, "No balance to withdraw");
        userBalances[owner] = 0;
        payable(owner).transfer(balanceAmount);
        emit BalanceWithdrawn(owner, balanceAmount);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getBalance() public view returns (uint256 amount) {
        return userBalances[owner];
    }

    function resetsContracts() public onlyOwner {
        delete playerSelector;
        delete players;
        raffleStatus = false;
        nftAddress = address(0);
        nftId = 0;
        entryCost = 0;
        totalEntries = 0;
        resetEntryCounts();
    }
}
