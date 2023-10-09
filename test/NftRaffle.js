const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("NftRaffle", function () {
  let owner;
  let participant;
  let raffleContract;

  beforeEach(async function () {
    [owner, participant] = await ethers.getSigners();

    const NftRaffle = await ethers.getContractFactory("NftRaffle");
    raffleContract = await NftRaffle.deploy(100);

  });

  it("Should start a raffle", async function () {
    await raffleContract.connect(owner).startRaffle(participant.address, 1);
    const status = await raffleContract.raffleStatus();
    const nftAddress = await raffleContract.nftAddress();
    const nftId = await raffleContract.nftId();

    expect(status).to.equal(true);
    expect(nftAddress).to.equal(participant.address);
    expect(nftId).to.equal(1);
  });

  it("Should allow participants to buy entries", async function () {
    await raffleContract.connect(owner).startRaffle(participant.address, 1);

    const initialBalance = await ethers.provider.getBalance(participant.address);
    await raffleContract.connect(participant).buyEntry(2, { value: 200 }); // Assuming entry cost is 100

    const finalBalance = await ethers.provider.getBalance(participant.address);
    const entryCount = await raffleContract.entryCount(participant.address);
    const totalEntries = await raffleContract.totalEntries();

    expect(finalBalance).to.be.lessThan(initialBalance);
    expect(entryCount).to.equal(2);
    expect(totalEntries).to.equal(2);
  });

  it("Should not allow participants to start a raffle", async function () {
    await expect(
      raffleContract.connect(participant).startRaffle(participant.address, 1)
    ).to.be.revertedWith("Only owner can call this function");
  });

  it("Should not allow starting a new raffle while the previous one is running", async function () {
    // Start the first raffle
    await raffleContract.connect(owner).startRaffle(participant.address, 1);

    // Attempt to start a new raffle while the previous one is running
    await expect(
      raffleContract.connect(owner).startRaffle(participant.address, 2)
    ).to.be.revertedWith("NFT prize already set");
  });

  it("Should not allow ending a raffle when it has not started", async function () {
    await expect(raffleContract.connect(owner).endRaffle()).to.be.revertedWith(
      "Raffle has not started"
    );
  });

  it("Should not allow selecting a winner when the raffle is still running", async function () {
    await raffleContract.connect(owner).startRaffle(participant.address, 1);

    await expect(
      raffleContract.connect(owner).selectWinner()
    ).to.be.revertedWith("Raffle is still running");
  });

  it("Should not allow selecting a winner when there are no players", async function () {
    // Attempt to select a winner when there are no players
    await expect(raffleContract.connect(owner).selectWinner()).to.be.revertedWith(
      "There are no players"
    );
  });


  it("Should not allow selecting a winner when the NFT prize is not set", async function () {
    // Attempt to select a winner without setting the NFT prize
    await expect(raffleContract.connect(owner).selectWinner()).to.be.revertedWith(
      "There are no players"
    );

    // Ensure that the contract's state is unchanged (raffleStatus remains false)
    const raffleStatus = await raffleContract.raffleStatus();
    expect(raffleStatus).to.equal(false);
  });



  it("Should not allow participants to buy entries if the raffle has not started", async function () {
    await expect(
      raffleContract.connect(participant).buyEntry(1, { value: 100 })
    ).to.be.revertedWith("Raffle has not started");
  });

  it("Should not allow participants to buy entries with an incorrect amount", async function () {
    await raffleContract.connect(owner).startRaffle(participant.address, 1);

    await expect(
      raffleContract.connect(participant).buyEntry(1, { value: 50 })
    ).to.be.revertedWith("Incorrect amount sent");
  });

  it("Should not allow participants to withdraw zero balance", async function () {
    // Assuming the participant has a non-zero balance
    const initialBalance = await ethers.provider.getBalance(participant.address);

    // Ensure the participant's balance is initially greater than zero
    expect(initialBalance).to.be.gt(0);

    // Attempt to withdraw the balance
    await expect(raffleContract.connect(participant).withdrawBalance()).to.be.revertedWith(
      "Insufficient balance"
    );
  });

  it("Should not allow the owner to withdraw zero balance", async function () {
    await expect(raffleContract.connect(owner).ownerWithdraw()).to.be.revertedWith(
      "No balance to withdraw"
    );
  });


});
