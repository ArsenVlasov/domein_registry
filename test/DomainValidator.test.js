const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DomainValidator", function () {
    let domainValidatorWrapper;
    
    beforeEach(async function () {
        domainValidatorWrapper = await ethers.deployContract("DomainValidatorWrapper");
    });

    describe("stripProtocol", function () {
    it("should remove the protocol from the domain", async function () {
        const result = await domainValidatorWrapper.stripProtocol("https://example.com");
        expect(result).to.equal("example.com");
    });

    it("should return the same domain if no protocol", async function () {
        const result = await domainValidatorWrapper.stripProtocol("example.com");
        expect(result).to.equal("example.com");
    });
});

    describe("splitDomain", function () {
        it("should split the domain correctly", async function () {
            const result = await domainValidatorWrapper.splitDomain("sub.example.com");
            expect(result).to.deep.equal(["sub", "example", "com"]);
        });
    });

    describe("getParentDomain", function () {
        it("should get the parent domain correctly", async function () {
            expect(await domainValidatorWrapper.getParentDomain("sub.example.com")).to.equal("example.com");
            expect(await domainValidatorWrapper.getParentDomain("example.com")).to.equal("");
        });
    });

    describe("isValidDomain", function () {
        it("should validate correct domain", async function () {
            expect(await domainValidatorWrapper.isValidDomain("example.com")).to.be.true;
            expect(await domainValidatorWrapper.isValidDomain("sub.example.com")).to.be.true;
        });

        it("should return false for invalid domain", async function () {
            expect(await domainValidatorWrapper.isValidDomain(".example.com")).to.be.false;
            expect(await domainValidatorWrapper.isValidDomain("example.com.")).to.be.false;
            expect(await domainValidatorWrapper.isValidDomain("example..com")).to.be.false;
            expect(await domainValidatorWrapper.isValidDomain("ex@mple.com")).to.be.false;
        });
    });

});
