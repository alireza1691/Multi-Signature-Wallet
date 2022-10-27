// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC20.sol";

contract Bet {
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint startAt,
        uint endAt
    );
    event Pledge(uint indexed id, address indexed caller, uint amount, uint answerGuessed);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event SetWinner(uint winNumber);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign {
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
        bool answer;
        uint  correctAnswer;
        uint256  endGameTime;
        uint  team1pool;
        uint  drawpool;
        uint  team2pool;
    }
    address payable owner;

    // struct Transaction {
    //     address to;
    //     uint value;
    //     bytes data;
    //     bool executed;
    // }

    IERC20 public immutable token;
    constructor (address _token) {
        token = IERC20(_token);
        owner = payable(msg.sender);
    }

    // address[] public owners;
    // mapping(address => bool) public isOwner;
    // uint public required;
    uint public count;
    // uint public correctAnswer;
    // uint256 public endGameTime;
    // uint public team1pool;
    // uint public drawpool;
    // uint public team2pool;

    // Transaction[] public transactions;
    mapping(uint => Campaign) public campaigns;
    // mapping(uint => mapping(address => bool)) public approved;
    mapping(uint => mapping(address => uint)) public pledgedAmount;
    mapping(uint => mapping(address => uint)) public UserAnswer;

    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at < max duration");
        count += 1;
        campaigns[count] = Campaign ({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false,
            answer: false
        });
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }
    // function startBetting(uint _id, uint _amount, uint _answer) external {
    //     Campaign storage campaign = campaigns[_id];
    //     require(block.timestamp >= campaign.startAt, "not started");
    //     require(block.timestamp <= campaign.endAt, "ended");

    //     campaign.pledged += _amount;
    //     UserAnswer[_id][msg.sender] = _answer;
    //     pledgedAmount[_id][msg.sender] += _amount;
    //     token.transferFrom(msg.sender, address(this), _amount);

    //     emit Pledge(_id, msg.sender, _amount, _answer);
    // }
    function startBettingOnTeam1(uint _id, uint _amount, uint _answer) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.team1pool += _amount;
        campaign.pledged += _amount;
        UserAnswer[_id][msg.sender] = _answer;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount, _answer);
    }
    function startBettingOnDraw(uint _id, uint _amount, uint _answer) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.drawpool += _amount;
        campaign.pledged += _amount;
        UserAnswer[_id][msg.sender] = _answer;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount, _answer);
    }
    function startBettingOnTeam2(uint _id, uint _amount, uint _answer) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.team2pool += _amount;
        campaign.pledged += _amount;
        UserAnswer[_id][msg.sender] = _answer;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount, _answer);
    }
    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "now is late for unpledge");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    function setwinner(uint _id, uint resultMatch) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == owner, "just owner can");
        require(block.timestamp >= campaign.endAt, "not ended");
        campaign.correctAnswer = resultMatch;
        campaign.endGameTime = block.timestamp;
    }

    function calculate(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        // require(block.timestamp >= campaign.endAt, "not ended");
        // require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "already claimed");
        uint total;
        total = campaign.team1pool + campaign.drawpool + campaign.team2pool;
        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    function getRewardForWinners(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.endGameTime, "not ended");
        require(campaign.pledged < campaign.goal, "pledged < goal");
        require(UserAnswer[_id][msg.sender] == campaign.correctAnswer, "You lose because of wrong guess");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);
    }
    // function claimLoserFunds(uint _id) external {
    //     Campaign storage campaign = campaigns[_id];
    //     require(msg.sender == campaign.creator, "not creator");
    //     // require(block.timestamp >= campaign.endAt, "not ended");
    //     // require(campaign.pledged >= campaign.goal, "pledged < goal");
    //     require(!campaign.claimed, "already claimed");

    //     campaign.claimed = true;
    //     token.transfer(msg.sender, campaign.pledged);

    //     emit Claim(_id);
    // }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    
    // receive() external payable {
    //     emit Deposit(msg.sender, msg.value);
    // }


}