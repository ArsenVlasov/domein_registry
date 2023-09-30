const { expect } = require("chai");

describe("DomainRegistry", function () {
  let DomainRegistry, domainRegistry, owner, addr1, addr2;
  const initialDeposit = ethers.parseEther("1");

  beforeEach(async () => {
    DomainRegistry = await ethers.getContractFactory("DomainRegistry");
    [owner, addr1, addr2] = await ethers.getSigners();
    domainRegistry = await DomainRegistry.deploy(); // Это уже ожидает успешного развертывания
});

  it("Should deploy properly", async function () {
    expect(await domainRegistry.totalDomains()).to.equal(0);
    expect(await domainRegistry.totalReservedDomains()).to.equal(0);
  });

  describe("reserveDomain", function () {
    it("Should reserve a domain and emit the correct event", async function () {
      await expect(domainRegistry.connect(addr1).reserveDomain("example", initialDeposit, { value: initialDeposit }))
        .to.emit(domainRegistry, 'DomainReserved')
        .withArgs("example", addr1.address, initialDeposit);
    });

    it("Should revert when trying to reserve an already reserved domain", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example", initialDeposit, { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).reserveDomain("example", initialDeposit, { value: initialDeposit }))
        .to.be.revertedWith("Domain already reserved");
    });

    it("Should revert when the domain name contains a dot", async function () {
      await expect(domainRegistry.connect(addr1).reserveDomain("example.com", initialDeposit, { value: initialDeposit }))
        .to.be.revertedWith("Domain name must be a top-level domain");
    });
  });

  describe("Domain Actions", function () {
    const domainName = "example";

    beforeEach(async () => {
      await domainRegistry.connect(addr1).reserveDomain(domainName, initialDeposit, { value: initialDeposit });
    });

    it("Should change deposit and emit the correct event", async function () {
      const newDeposit = ethers.parseEther("2");
      await expect(domainRegistry.connect(addr1).changeDeposit(domainName, newDeposit, { value: newDeposit }))
        .to.emit(domainRegistry, 'DepositChanged')
        .withArgs(domainName, newDeposit);
    });

    it("Should transfer domain control and emit the correct event", async function () {
      await expect(domainRegistry.connect(addr1).transferDomainControl(domainName, addr2.address))
        .to.emit(domainRegistry, 'DomainControlTransferred')
        .withArgs(domainName, addr2.address);
    });

    it("Should release domain, refund deposit and emit the correct event", async function () {
      await expect(domainRegistry.connect(addr1).releaseDomain(domainName))
        .to.emit(domainRegistry, 'DomainReleased')
        .withArgs(domainName, addr1.address, initialDeposit);
    });
  });

  describe("Owner Actions", function () {
    it("Should allow the owner to withdraw funds", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example", initialDeposit, { value: initialDeposit });
      
      const balanceBefore = await ethers.provider.getBalance(owner.address); // Исправлено здесь
      const contractBalance = await ethers.provider.getBalance(domainRegistry.address);
      
      const tx = await domainRegistry.connect(owner).withdrawFunds();
      const txCost = (await tx.wait()).gasUsed.mul(tx.gasPrice);
      const balanceAfter = await ethers.provider.getBalance(owner.address); // Исправлено здесь
      
      expect(balanceAfter.sub(balanceBefore).add(txCost)).to.equal(contractBalance);
    });
  });
});
