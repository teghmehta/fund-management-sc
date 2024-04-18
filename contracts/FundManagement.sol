// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./FundManagementToken.sol";

/**
 * @title FundManagement
 * @dev Digital Fund Management
 */
contract FundManagement {

    address public admin;

    struct Spending {
        string purpose; // Purpose of spending
        uint amt; // ETH amt to spend
        address receiver; // Receiver of Spending
        bool executed; // If spending has been executed
        mapping(address => bool) approvals; // Mapping of stakeholders to vote bool
        uint approversCount; // Number of stakeholders who have approved spending
    }

    // min amt ETH to deposit to become a stakeholder
    uint public minBuy = 0.1 ether;

    // mapping of stakeholder address to amount deposited
    // (stakeholder => amount)
    mapping(address => uint) public stakeholders;

    // spending: mapping of id to spending
    // (id => spending)
    mapping(uint => Spending) public spending;

    uint public tokensMintedThusFar = 0;

    uint public spendingCount;

    // spendingMinVoterPercent: percentage of votes needed from total tokens to pass a spending request. The number should be rounded down
    // (spendingId => percentage)
    uint public spendingMinVoterPercent = 75;

    // shareToken: address of share token
    address public shareToken;

    // Events
    event Deposit(address newStakeHolder, uint depositAmt);

    event Vote(address voter, bool vote);

    event NewSpending(address receiver, uint spendingAmt);

    event SpendingExecuted(address executor, uint spendingId);

    // Functions
    /**
     * @dev Constructor
     * @param _admin address of admin
     */
    constructor(address _admin) {
        admin = _admin;
        shareToken = address(new FundManagementToken());
    }

    /**
     * @dev Deposit ETH to staleholders account
     * @param depositAmt amount of ETH to deposit
     */
    function deposit(uint depositAmt) public payable {
        require(msg.value == depositAmt, "Deposit amount does not match msg.value");
        require(depositAmt >= minBuy, "Deposit amount is less than minBuy");
        stakeholders[msg.sender] += depositAmt;
        emit Deposit(msg.sender, depositAmt);
        uint tokensToMint = depositAmt / minBuy;
        tokensMintedThusFar += tokensToMint;
        FundManagementToken(shareToken).transfer(msg.sender, tokensToMint);
    }

    /**
     * @dev Admin creates a new spending request
     * @param _receiver address of receiver,
     * @param spendingAmt amount of ETH to spend
     * @param _purpose purpose of spending
     */
    function createSpending(address _receiver, uint spendingAmt, string memory _purpose) public {
        require(msg.sender == admin, "Only admin can create spending request");
        Spending storage s = spending[spendingCount++];
        s.purpose = _purpose;
        s.amt = spendingAmt;
        s.receiver = _receiver;
        s.executed = false;
        s.approversCount = 0;
        emit NewSpending(_receiver, spendingAmt);
    }


    /**
     * @dev Stakeholders adds an approval vote to a spending request
     * @param spendingId id of spending request
     * @param vote bool of vote
     */
    function approveSpending(uint spendingId, bool vote) public {
        require(stakeholders[msg.sender] > 0, "Only stakeholders can vote");
        Spending storage s = spending[spendingId];
        require(s.approvals[msg.sender] == false, "Stakeholder has already voted");
        s.approvals[msg.sender] = vote;
        if (vote) {
            s.approversCount += (stakeholders[msg.sender] / minBuy);
        }
        emit Vote(msg.sender, vote);
    }


    /**
     * @dev Send money to address if there are enough approvals
     * @param spendingId id of spending request
     */
    function executeSpending(uint spendingId) public {
        require(msg.sender == admin, "Only admin can execute spending request");
        Spending storage spendingRequest = spending[spendingId];
        require(spendingRequest.executed == false, "Spending request has already been executed");
        require(spendingRequest.approversCount >= (tokensMintedThusFar * spendingMinVoterPercent / 100), "Not enough approvals to execute spending request");
        spendingRequest.executed = true;
        payable(spendingRequest.receiver).transfer(spendingRequest.amt);
        emit SpendingExecuted(msg.sender, spendingId);
    }
}
