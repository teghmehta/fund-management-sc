const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("FundManagment", () => {
  let token, a1, a2, a3;

  beforeEach(async () => {
    [a1, a2, a3] = await ethers.getSigners();
    const contract = await ethers.getContractFactory("FundManagement");
    token = await contract.deploy(a1.address);
  });

  describe("Create Spending Request", () => {
    it("Test Create Spending", async () => {
      await token
        .connect(a1)
        .createSpending(
          a3.address,
          ethers.utils.parseUnits("100000000000000000", 0),
          "give me all your money"
        );
      const spending = await token.spending(0);
      expect(spending.amt).to.equal(ethers.utils.parseUnits("100000000000000000", 0));
      assert.equal(spending.receiver, a3.address);
      assert.equal(spending.purpose, "give me all your money");
    });
  });

  describe("Approve Spending Request", () => {
    beforeEach(async () => {
      await token
        .connect(a1)
        .createSpending(
          a3.address,
          ethers.utils.parseUnits("100000000000000000", 0),
          "give me all your money"
        );
      await token
        .connect(a2)
        .deposit(ethers.utils.parseUnits("100000000000000000", 0), {
          value: ethers.utils.parseUnits("100000000000000000", 0),
        });
      await token
        .connect(a3)
        .deposit(ethers.utils.parseUnits("100000000000000000", 0), {
          value: ethers.utils.parseUnits("100000000000000000", 0),
        });
    });

    it("Test stakeholder is able to vote", async () => {
      await token.connect(a2).approveSpending(0, true);
      const spending = await token.spending(0);
      assert.equal(spending.approversCount, 1);
    });
  });

  describe("Execute Spending Requests", () => {
    beforeEach(async () => {
      await token
        .connect(a1)
        .createSpending(
          a3.address,
          ethers.utils.parseUnits("100000000000000000", 0),
          "Execute"
        );
      await token
        .connect(a2)
        .deposit(ethers.utils.parseUnits("100000000000000000", 0), {
          value: ethers.utils.parseUnits("100000000000000000", 0),
        });
      await token
        .connect(a3)
        .deposit(ethers.utils.parseUnits("100000000000000000", 0), {
          value: ethers.utils.parseUnits("100000000000000000", 0),
        });
    });

    it("Test Spending with majority voting", async () => {
      await token.connect(a2).approveSpending(0, true);
      await token.connect(a3).approveSpending(0, true);
      await token.connect(a1).executeSpending(0);

      const spending = await token.spending(0);
      assert.equal(spending.executed, true);
    });
  });
});