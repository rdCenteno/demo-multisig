async function main() {
    const [deployer, addr1, addr2] = await ethers.getSigners();
    const owners = [deployer.address, addr1.address, addr2.address];
    const numConfirmations = 2;
    console.log(
        "Deploying the contracts with the account:",
        await deployer.getAddress()
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");

    const multiSigWallet = await MultiSigWallet.deploy(owners, numConfirmations);
    await multiSigWallet.deployed();

    console.log("Contract address:", multiSigWallet.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
