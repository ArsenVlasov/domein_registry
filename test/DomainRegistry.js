const { expect } = require("chai");

describe("DomainRegistry", function () {
  let DomainRegistry, domainRegistry, owner, addr1, addr2;
  const initialDeposit = ethers.parseEther("1");

  beforeEach(async () => {
    DomainRegistry = await ethers.getContractFactory("DomainRegistry");
    [owner, addr1, addr2] = await ethers.getSigners();
    domainRegistry = await DomainRegistry.deploy(initialDeposit);
  });

  it("Should deploy properly", async function () {
    expect(await domainRegistry.getTotalReservedDomains()).to.equal(0);
  });

  describe("Domain negative actions", function () {
    it("Should revert when trying to reserve a domain with no initial deposit", async function () {
      await expect(domainRegistry.connect(addr1).reserveDomain("example", { value: ethers.parseEther("0") }))
        .to.be.revertedWith("Insufficient deposit amount");
    });

    it("Should reserve a domain and emit the correct event", async function () {
      await expect(domainRegistry.connect(addr1).reserveDomain("example", { value: initialDeposit }))
        .to.emit(domainRegistry, 'DomainReserved')
        .withArgs("example", addr1.address, initialDeposit);
    });

    it("Should revert when trying to reserve an already reserved domain", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example", { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).reserveDomain("example", { value: initialDeposit }))
        .to.be.revertedWith("Domain already reserved");
    });

    it("Should revert when the domain name contains a dot", async function () {
      await expect(domainRegistry.connect(addr1).reserveDomain("example.com", { value: initialDeposit }))
        .to.be.revertedWith("Domain name must be a top-level domain");
    });
  });

  describe("Domain Actions", function () {
    const domainName = "example";

    beforeEach(async () => {
      await domainRegistry.connect(addr1).reserveDomain(domainName, { value: initialDeposit });
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

  describe("Negative Tests", function () {
    it("Should revert when non-controller tries to change deposit", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example", { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).changeDeposit("example", initialDeposit))
        .to.be.revertedWith("Only the domain controller can execute it");
    });

    it("Should revert when non-controller tries to transfer domain control", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example", { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).transferDomainControl("example", addr1.address))
        .to.be.revertedWith("Only the domain controller can execute it");
    });

    it("Should revert when non-controller tries to release domain", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example", { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).releaseDomain("example"))
        .to.be.revertedWith("Only the domain controller can execute it");
    });
  });
});
