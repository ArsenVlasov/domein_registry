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

  describe("Negative reserve domain operations", function () {
    it("Should revert when trying to reserve a domain with no initial deposit", async function () {
      await expect(domainRegistry.connect(addr1).reserveDomain("example.com", { value: ethers.parseEther("0") }))
        .to.be.revertedWith("Insufficient deposit amount");
    });

    it("Should revert when trying to reserve an already reserved domain", async function () {
      await domainRegistry.connect(addr1).reserveDomain("solidity.org", { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).reserveDomain("solidity.org", { value: initialDeposit }))
        .to.be.revertedWith("Domain already reserved");
    });

    it("Should revert when trying to reserve domain without parent reserving previosly", async function () {
      await expect(domainRegistry.connect(addr2).reserveDomain("abc.dot.com.org", { value: initialDeposit }))
        .to.be.revertedWith("Parent domain must exist");
    });
  });

  describe("Domain Actions", function () {
    const domainName = "example.com";

    beforeEach(async () => {
      await domainRegistry.connect(addr1).reserveDomain(domainName, { value: initialDeposit });
    });

    it("Should reserve a domain and emit the correct event", async function () {
      await expect(domainRegistry.connect(addr1).reserveDomain("friends.ua", { value: initialDeposit }))
        .to.emit(domainRegistry, 'DomainReserved')
        .withArgs("friends.ua", addr1.address, initialDeposit);
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

  describe("Negative operations between clients", function () {
    it("Should revert when non-controller tries to change deposit", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example.com", { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).changeDeposit("example.com", initialDeposit))
        .to.be.revertedWith("Only the domain controller can execute it");
    });

    it("Should revert when non-controller tries to transfer domain control", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example.com", { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).transferDomainControl("example.com", addr1.address))
        .to.be.revertedWith("Only the domain controller can execute it");
    });

    it("Should revert when non-controller tries to release domain", async function () {
      await domainRegistry.connect(addr1).reserveDomain("example.com", { value: initialDeposit });
      await expect(domainRegistry.connect(addr2).releaseDomain("example.com"))
        .to.be.revertedWith("Only the domain controller can execute it");
    });
  });


  describe("Reserving parent and child domens", function() {
    const domainName1 = "business.com";
    const domainName2 = "new.business.com";
  
    it("Should allow reserving parent domen and then child domen", async function() {
      await expect(domainRegistry.connect(addr1).reserveDomain(domainName1, { value: initialDeposit }))
        .to.emit(domainRegistry, 'DomainReserved')
        .withArgs(domainName1, addr1.address, initialDeposit);

      await expect(domainRegistry.connect(addr1).reserveDomain(domainName2, { value: initialDeposit }))
        .to.emit(domainRegistry, 'DomainReserved')
        .withArgs(domainName2, addr1.address, initialDeposit);
    });

    it("Should not allow reserving child domen and then parent domen. Only after parent domen reserving", async function() {
      await expect(domainRegistry.connect(addr1).reserveDomain(domainName2, { value: initialDeposit }))
        .to.be.revertedWith("Parent domain must exist");

      await expect(domainRegistry.connect(addr1).reserveDomain(domainName1, { value: initialDeposit }))
        .to.emit(domainRegistry, 'DomainReserved')
        .withArgs(domainName1, addr1.address, initialDeposit);

      await expect(domainRegistry.connect(addr1).reserveDomain(domainName2, { value: initialDeposit }))
        .to.emit(domainRegistry, 'DomainReserved')
        .withArgs(domainName2, addr1.address, initialDeposit);
    });
  });

  describe("Relising parent and child domens", function() {
    const domainName1 = "business.com";
    const domainName2 = "new.business.com";
  
    beforeEach(async () => {
      await domainRegistry.connect(addr1).reserveDomain(domainName1, { value: initialDeposit });
      await domainRegistry.connect(addr1).reserveDomain(domainName2, { value: initialDeposit });
    });

    it("Should allow relising child domen and then parent domen", async function() {
      await expect(domainRegistry.connect(addr1).releaseDomain(domainName2))
        .to.emit(domainRegistry, 'DomainReleased')
        .withArgs(domainName2, addr1.address, initialDeposit);

      await expect(domainRegistry.connect(addr1).releaseDomain(domainName1))
        .to.emit(domainRegistry, 'DomainReleased')
        .withArgs(domainName1, addr1.address, initialDeposit);
    });

    it("Should not allow relising child domen and then parent domen. Only after child domen relising", async function() {
      await expect(domainRegistry.connect(addr1).releaseDomain(domainName1))
        .to.be.revertedWith("Remove child domains first");

      await expect(domainRegistry.connect(addr1).releaseDomain(domainName2))
        .to.emit(domainRegistry, 'DomainReleased')
        .withArgs(domainName2, addr1.address, initialDeposit);

      await expect(domainRegistry.connect(addr1).releaseDomain(domainName1))
        .to.emit(domainRegistry, 'DomainReleased')
        .withArgs(domainName1, addr1.address, initialDeposit);
      
    });
  });
});
