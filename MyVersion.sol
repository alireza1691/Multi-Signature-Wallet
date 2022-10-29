// SPDX-License-Identifier: MIT
/* Author: Alireza Haghshenas
/ github account : alireza1691
/ this contract maded for betting on footbal matches
*/
pragma solidity ^0.8.17;

//af first we need a token as a payment , then we deploy our ERC20 token
import "./IERC20.sol";

contract Bet {
    
    event Launch(
        uint id,
        address indexed creator,
        uint startAt,
        uint endAt
    );
    event Pledge(uint indexed id, address indexed caller, uint amount, string answerGuessed);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event SetWinner(uint winNumber);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign {
        address creator;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
        uint  correctAnswer;
        uint256  endGameTime;
        uint  team1pool;
        uint  drawpool;
        uint  team2pool;
    }
    address payable owner;
    uint public leverage;


    IERC20 public immutable token;
    constructor (address _token) {
        token = IERC20(_token);
        owner = payable(msg.sender);
    }

    // address[] public owners;
    // mapping(address => bool) public isOwner;
    // uint public required;
    uint public count;

    mapping(uint => Campaign) public campaigns;
    // mapping(uint => mapping(address => bool)) public approved;
    mapping(uint => mapping(address => uint)) public pledgedAmount;
    mapping(uint => mapping(address => uint256)) public UserAnswer;
    mapping(uint => bool) public isCorrect;

    function launch(
        uint32 _startAt,
        uint32 _endAt
    ) external {
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at < max duration");
        count += 1;
        campaigns [count] = Campaign ({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false,
            correctAnswer: 9,
            endGameTime: _endAt + 180 minutes,
            team1pool : 0,
            drawpool: 0 ,
            team2pool: 0
        });
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }
    uint public team1X;
    uint public drawX;
    uint public team2X;
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
    function startBettingOnTeam1(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.team1pool += _amount;
        campaign.pledged += _amount;
        UserAnswer[_id][msg.sender] = 0;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        isCorrect[_id] = false;

        emit Pledge(_id, msg.sender, _amount, "team1");
    }
    function startBettingOnDraw(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.drawpool += _amount;
        campaign.pledged += _amount;
        UserAnswer[_id][msg.sender] = 1;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        isCorrect[_id] = false;

        emit Pledge(_id, msg.sender, _amount, "draw");
    }
    function startBettingOnTeam2(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.team2pool += _amount;
        campaign.pledged += _amount;
        UserAnswer[_id][msg.sender] = 2;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        isCorrect[_id] = false;

        emit Pledge(_id, msg.sender, _amount, "team2");
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

    function CheckAndCalculate(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        // require(block.timestamp >= campaign.endAt, "not ended");
        // require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "already claimed");
        uint total;
        uint WhatUserGuessed;
        uint WhatIsCorrectAnswer;
        total = campaign.team1pool + campaign.drawpool + campaign.team2pool;
        team1X = total / campaign.team1pool;
        drawX = total / campaign.drawpool;
        team2X = total / campaign.team2pool;
        WhatIsCorrectAnswer = campaign.correctAnswer;
        WhatUserGuessed = UserAnswer[_id][msg.sender];

        if ( WhatIsCorrectAnswer == WhatUserGuessed) {
            isCorrect[_id] = true;
        }
        if ( campaign.correctAnswer == 0 ) {
            leverage = team1X;
        } else if( campaign.correctAnswer == 1) {
            leverage = drawX;
        } else if( campaign.correctAnswer == 2) {
            leverage = team2X;
        }
     
        token.transfer(msg.sender, campaign.pledged);
    }

    function getRewardForWinners(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.endGameTime, "not ended");
        require(isCorrect[_id] == true, "pledged < goal");
        require(UserAnswer[_id][msg.sender] == campaign.correctAnswer, "You lose because of wrong guess");
        require(pledgedAmount[_id][msg.sender] >= 0, "empty");

        uint bal = ((pledgedAmount[_id][msg.sender]) * leverage);
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Claim(_id);
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