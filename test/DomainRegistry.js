// Подключаем необходимые библиотеки и модули Hardhat
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DomainRegistry", function () {
  let domainRegistry;
  let owner;
  let user1;
  let user2;

  // Инициализируем контракт и аккаунты перед каждым тестом
  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const DomainRegistry = await ethers.getContractFactory("DomainRegistry");
    domainRegistry = await DomainRegistry.deploy();
    await domainRegistry.deployed();
  });

  it("should allow reserving a domain", async function () {
    const domainName = "example.com";
    const initialDeposit = ethers.utils.parseEther("1");

    await domainRegistry.connect(user1).reserveDomain(domainName, initialDeposit);

    const controller = await domainRegistry.getDomainController(domainName);
    const deposit = await domainRegistry.getDomainDeposit(domainName);

    expect(controller).to.equal(user1.address);
    expect(deposit).to.equal(initialDeposit);
  });

  it("should allow changing deposit by the domain controller", async function () {
    const domainName = "example.com";
    const initialDeposit = ethers.utils.parseEther("1");
    const newDeposit = ethers.utils.parseEther("2");

    await domainRegistry.connect(user1).reserveDomain(domainName, initialDeposit);
    await domainRegistry.connect(user1).changeDeposit(domainName, newDeposit);

    const deposit = await domainRegistry.getDomainDeposit(domainName);

    expect(deposit).to.equal(newDeposit);
  });

  it("should allow transferring domain control", async function () {
    const domainName = "example.com";
    const initialDeposit = ethers.utils.parseEther("1");

    await domainRegistry.connect(user1).reserveDomain(domainName, initialDeposit);
    await domainRegistry.connect(user1).transferDomainControl(domainName, user2.address);

    const controller = await domainRegistry.getDomainController(domainName);

    expect(controller).to.equal(user2.address);
  });

  it("should allow releasing a domain by the domain controller", async function () {
    const domainName = "example.com";
    const initialDeposit = ethers.utils.parseEther("1");

    await domainRegistry.connect(user1).reserveDomain(domainName, initialDeposit);
    const initialBalanceUser1 = await ethers.provider.getBalance(user1.address);

    await domainRegistry.connect(user1).releaseDomain(domainName);

    const controller = await domainRegistry.getDomainController(domainName);
    const finalBalanceUser1 = await ethers.provider.getBalance(user1.address);

    expect(controller).to.equal(ethers.constants.AddressZero);
    expect(finalBalanceUser1.sub(initialBalanceUser1)).to.equal(initialDeposit);
  });

  it("should not allow transferring domain control to an invalid address", async function () {
    const domainName = "example.com";
    const initialDeposit = ethers.utils.parseEther("1");

    await domainRegistry.connect(user1).reserveDomain(domainName, initialDeposit);

    await expect(domainRegistry.connect(user1).transferDomainControl(domainName, ethers.constants.AddressZero))
      .to.be.revertedWith("Invalid controller address");
  });
});
