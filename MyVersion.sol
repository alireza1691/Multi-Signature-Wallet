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
    event Deposit(uint indexed id, address indexed caller, uint amount, string betOn);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event CancelBeforStart(uint id);
    event InputWinner(bool inputed);
    event ClaimReward(bool eligibate,address indexed caller, uint amount);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Match {
        address creator;
        uint amount;
        uint256 startAt;
        uint256 endAt;
        bool claimed;
        uint  correctAnswer;
        uint256  endGameTime;
        uint  team1pool;
        uint  drawpool;
        uint  team2pool;
    }
    address payable owner;
    uint public leverage = 1;
    uint public count;


    IERC20 public immutable token;
    constructor (address _token) {
        token = IERC20(_token);
        owner = payable(msg.sender);
    }
    //  constructor () {
    //     owner = payable(msg.sender);
    // }   


    mapping(uint => Match) public campaigns;
    // mapping(uint => mapping(address => bool)) public approved;
    // mapping(uint => mapping(address => uint)) public pledgedAmount;
    // mapping(uint => mapping(address => uint256)) public UserAnswer;
    mapping(address => uint) public Answer;
    mapping(address => uint) public Value;
    mapping(address => bool) public isCorrect;

    function launch(
        // uint32 _startAt,
        // uint32 _endAt
    ) external {
        uint256 _startAt;
        uint256 _endAt;
        _startAt = block.timestamp;
        _endAt = block.timestamp + 3 minutes;
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at < max duration");
        count += 1;
        campaigns [count] = Match ({
            creator: msg.sender,
            amount: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false,
            correctAnswer: 9,
            endGameTime: _endAt + 180 minutes,
            team1pool : 0,
            drawpool: 0 ,
            team2pool: 0
        });
        emit Launch(count, msg.sender, _startAt, _endAt);
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
    function startBettingOnTeam1( uint _amount) external {
        Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "time to bet was over");

        uint256 userBalance;
        userBalance = (msg.sender).balance;
        require(userBalance >= _amount);
        token.transferFrom(msg.sender, address(this), _amount);

        campaign.team1pool += _amount;
        campaign.amount += _amount;
        Answer[msg.sender] = 0;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        team1X = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.team1pool;

        emit Deposit(count, msg.sender, _amount, "selected team1");
    }
    function startBettingOnDraw(uint _amount) external {
     Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "time to bet was over");

        uint256 userBalance;
        userBalance = (msg.sender).balance;
        require(userBalance >= _amount);
        token.transferFrom(msg.sender, address(this), _amount);

        campaign.drawpool += _amount;
        campaign.amount += _amount;
        Answer[msg.sender] = 1;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        drawX = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.drawpool;

        emit Deposit(count, msg.sender, _amount, "selected draw");
    }
    function startBettingOnTeam2(uint _amount) external {
        Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "time to bet was over");

        uint256 userBalance;
        userBalance = (msg.sender).balance;
        require(userBalance >= _amount);
        token.transferFrom(msg.sender, address(this), _amount);

        campaign.team2pool += _amount;
        campaign.amount += _amount;
        Answer[msg.sender] = 2;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        team2X = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.team2pool ;

        emit Deposit(count, msg.sender, _amount, "selected team 2");
    }

    function setwinner(uint resultMatch) external {
        Match storage campaign = campaigns[count];
        require(resultMatch < 3, "choise only must be one of the 0 , 1 , 2 numbers!!");
        require(msg.sender == owner, "just owner can");
        require(block.timestamp >= campaign.endAt, "not ended");
        require(address(this).balance != 0, "does not have any value");
        campaign.correctAnswer = resultMatch;
        campaign.endGameTime = block.timestamp;

        emit InputWinner(true);
    }

    function CheckAndGetReward() external {
        Match storage campaign = campaigns[count];
        require(Value[msg.sender] > 0, "you haven't any value in this contract");
        require(!campaign.claimed, "claimed");
        require(Answer[msg.sender] == campaign.correctAnswer, "you are not eligibate!");

        if ( campaign.correctAnswer == 0 ) {
            leverage = team1X;
        } else if( campaign.correctAnswer == 1) {
            leverage = drawX;
        } else if( campaign.correctAnswer == 2) {
            leverage = team2X;
        }
        uint bal = ((Value[msg.sender]) * leverage);
        
        Value[msg.sender] = 0;
        token.transfer(msg.sender, bal);
        campaign.amount -= bal;
        emit ClaimReward(true, msg.sender, bal);
    }

    function refund() external {
        Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.endGameTime, "not ended");
        require(msg.sender == owner, " owner can refund ");

        uint pool = campaign.amount;
        token.transfer(msg.sender, pool);

        emit Refund(count, msg.sender, pool);

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