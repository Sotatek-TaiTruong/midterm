const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("SwapContract", function () {
    let SwapContract, swapContract, TokenA, TokenB, tokenA, tokenB, owner, addr1, addr2, treasury;

    beforeEach(async function () {
        [owner, addr1, addr2, treasury] = await ethers.getSigners();
        TokenA = await ethers.getContractFactory("ERC20Mock");
        TokenB = await ethers.getContractFactory("ERC20Mock");

        tokenA = await TokenA.deploy("TokenA", "TKA", ethers.utils.parseEther("1000"));
        tokenB = await TokenB.deploy("TokenB", "TKB", ethers.utils.parseEther("1000"));

        SwapContract = await ethers.getContractFactory("SwapContract");
        swapContract = await upgrades.deployProxy(SwapContract, [treasury.address, 5], { initializer: 'initialize' });

        await tokenA.transfer(addr1.address, ethers.utils.parseEther("100"));
        await tokenB.transfer(addr2.address, ethers.utils.parseEther("100"));
    });

    it("Should create a swap request", async function () {
        await tokenA.connect(addr1).approve(swapContract.address, ethers.utils.parseEther("10"));
        await swapContract.connect(addr1).createSwapRequest(addr2.address, ethers.utils.parseEther("10"), tokenA.address, tokenB.address);

        const swapRequest = await swapContract.swapRequests(1);
        expect(swapRequest.requester).to.equal(addr1.address);
        expect(swapRequest.approver).to.equal(addr2.address);
        expect(swapRequest.amount).to.equal(ethers.utils.parseEther("10"));
        expect(swapRequest.status).to.equal(0);
    });

    it("Should approve a swap request and transfer tokens", async function () {
        await tokenA.connect(addr1).approve(swapContract.address, ethers.utils.parseEther("10"));
        await swapContract.connect(addr1).createSwapRequest(addr2.address, ethers.utils.parseEther("10"), tokenA.address, tokenB.address);

        await tokenB.connect(addr2).approve(swapContract.address, ethers.utils.parseEther("10"));
        await swapContract.connect(addr2).approveSwapRequest(1);

        const swapRequest = await swapContract.swapRequests(1);
        expect(swapRequest.status).to.equal(1);

        const balanceA_addr1 = await tokenA.balanceOf(addr1.address);
        const balanceB_addr1 = await tokenB.balanceOf(addr1.address);
        const balanceA_addr2 = await tokenA.balanceOf(addr2.address);
        const balanceB_addr2 = await tokenB.balanceOf(addr2.address);

        expect(balanceA_addr1).to.equal(ethers.utils.parseEther("90"));
        expect(balanceB_addr1).to.equal(ethers.utils.parseEther("95"));
        expect(balanceA_addr2).to.equal(ethers.utils.parseEther("95"));
        expect(balanceB_addr2).to.equal(ethers.utils.parseEther("90"));

        const balanceTreasuryA = await tokenA.balanceOf(treasury.address);
        const balanceTreasuryB = await tokenB.balanceOf(treasury.address);

        expect(balanceTreasuryA).to.equal(ethers.utils.parseEther("0.5"));
        expect(balanceTreasuryB).to.equal(ethers.utils.parseEther("0.5"));
    });

    it("Should reject a swap request and refund tokens", async function () {
        await tokenA.connect(addr1).approve(swapContract.address, ethers.utils.parseEther("10"));
        await swapContract.connect(addr1).createSwapRequest(addr2.address, ethers.utils.parseEther("10"), tokenA.address, tokenB.address);

        await swapContract.connect(addr2).rejectSwapRequest(1);

        const swapRequest = await swapContract.swapRequests(1);
        expect(swapRequest.status).to.equal(2);

        const balanceA_addr1 = await tokenA.balanceOf(addr1.address);
        expect(balanceA_addr1).to.equal(ethers.utils.parseEther("100"));
    });

    it("Should cancel a swap request and refund tokens", async function () {
        await tokenA.connect(addr1).approve(swapContract.address, ethers.utils.parseEther("10"));
        await swapContract.connect(addr1).createSwapRequest(addr2.address, ethers.utils.parseEther("10"), tokenA.address, tokenB.address);

        await swapContract.connect(addr1).cancelSwapRequest(1);

        const swapRequest = await swapContract.swapRequests(1);
        expect(swapRequest.status).to.equal(3);

        const balanceA_addr1 = await tokenA.balanceOf(addr1.address);
        expect(balanceA_addr1).to.equal(ethers.utils.parseEther("100"));
    });
});
