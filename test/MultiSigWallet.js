const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Contract", () => {

    beforeEach(async () => {
        [addr1, addr2, addr3, addr4] = await ethers.getSigners();
        owners = [addr1.address, addr2.address, addr3.address];
        numConfirmationsRequired = owners.length;

        const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
        multiSigWallet = await MultiSigWallet.deploy(owners, numConfirmationsRequired);
        await multiSigWallet.deployed();
    });

    describe("Check initial state", () => {
        it("Check initial vaules", async () => {
            await Promise.all(owners.map(async owner => {
                const isOwner = await multiSigWallet.isOwner(owner);
                expect(isOwner).to.equal(true);
            }));

            const numConfirmations = await multiSigWallet.numConfirmationsRequired();
            expect(numConfirmations).to.equal(numConfirmationsRequired);
        });

        it("Should fail for not being an owner (submitTransaction)", async () =>  {
            await expect(
                multiSigWallet.connect(addr4).submitTransaction(ethers.constants.AddressZero, 0, ethers.constants.HashZero)
            ).to.be.rejectedWith("MultiSigWallet: caller is not the owner");
        });

        it("Should submit a new transaction (submitTransaction)", async () => {
            const value = 33;
            const data = "0x0000000000000000000000000000000000000000000000000000000000033333"
            const to = "0x3333300000000000000000000000000000000000"

            await expect(
                multiSigWallet.connect(addr1).submitTransaction(to, value, data)
            ).to.emit(multiSigWallet, "SubmitTransaction")
            .withArgs(addr1.address, 0, to, value, data);
        });

        it("Shoudl faul for not being an owner (confirmTransaction", async () => {
            await expect(
                multiSigWallet.connect(addr4).confirmTransaction(1)
            ).to.be.rejectedWith("MultiSigWallet: caller is not the owner");
        })

        it("Should submit a new transaction (confirmTransaction)", async () => {
            const value = 33;
            const data = "0x0000000000000000000000000000000000000000000000000000000000033333"
            const to = "0x3333300000000000000000000000000000000000";
            const txIndex = 0;

            await expect(
                multiSigWallet.connect(addr1).submitTransaction(to, value, data)
            ).to.emit(multiSigWallet, "SubmitTransaction")
            .withArgs(addr1.address, txIndex, to, value, data);

            await expect(
                multiSigWallet.connect(addr2).confirmTransaction(0)
            ).to.emit(multiSigWallet, "ConfirmTransaction")
            .withArgs(addr2.address, txIndex);
        });
    });
});