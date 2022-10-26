// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC20.sol";

contract MultiSigWallet {
    // event Launch(
    //     uint id,
    //     address indexed creator,
    //     uint goal,
    //     uint startAt,
    //     uint endAt
    // );
    event Deposit(uint indexed id, address indexed caller, uint amount);
    event Withdraw(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign {
        address creator;
        // uint goal;
        uint pledged;
        // uint32 startAt;
        // uint32 endAt;
        bool claimed;
    }

    // struct Transaction {
    //     address to;
    //     uint value;
    //     bytes data;
    //     bool executed;
    // }


    constructor (address _token) {
        token = IERC20(_token);
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    // uint public required;
    uint public count;

    Transaction[] public transactions;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => bool)) public approved;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    // function launch() external {
    //     count += 1;
    //     campaigns[count] = Campaign ({
    //         creator: msg.sender,
    //         goal: _goal,
    //         pledged: 0,
    //         startAt: _startAt,
    //         endAt: _endAt,
    //         claimed: false
    //     });
    //     emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    // }
    function deposit(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        // require(block.timestamp >= campaign.startAt, "not started");
        // require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Deposit(_id, msg.sender, _amount);
    }
    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        // require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Withdraw(_id, msg.sender, _amount);
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        // require(block.timestamp >= campaign.endAt, "not ended");
        // require(campaign.pledged < campaign.goal, "pledged < goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);
    }
    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        // require(block.timestamp >= campaign.endAt, "not ended");
        // require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "already claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }


    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }


}