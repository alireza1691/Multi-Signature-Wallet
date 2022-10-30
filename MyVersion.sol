// SPDX-License-Identifier: MIT
/* Author: Alireza Haghshenas
/ github account : alireza1691
/ this contract maded for betting on footbal matches
*/
pragma solidity ^0.8.17;



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
    event ClaimReward(bool eligibate,address indexed caller, uint amount, bytes indexed _data);
    event ClaimFee(uint indexed id, address indexed caller, uint amount, bytes indexed _data);

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
        uint  fee;
    }
    address payable owner;
    uint public leverage = 1;
    uint public count;


    // IERC20 public immutable token;
    // constructor (address _token) {
    constructor () {
        // token = IERC20(_token);
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
        _endAt = block.timestamp + 4 weeks;
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
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
            team2pool: 0,
            fee: 0
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
    // function startBettingOnTeam1( uint _amount) external {
        function showLevegarges () public returns(uint, uint, uint, string memory) {
            Match storage campaign = campaigns[count];
                team1X = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.team1pool;
                drawX = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.drawpool;
                team2X = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.team2pool;

            return(team1X , drawX, team2X, "note that these numbers may changed, because they depended on demand for choices");
        }
        function startBettingOnTeam1() payable external {
        Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");

        uint _amount;
        _amount = msg.value;
        // uint256 userBalance;
        // userBalance = (msg.sender).balance;
        // require(userBalance >= _amount);
        // token.transferFrom(msg.sender, address(this), _amount);

        campaign.team1pool += _amount;
        campaign.amount += _amount;
        Answer[msg.sender] = 0;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;

        emit Deposit(count, msg.sender, _amount, "selected team1");
    }
    function startBettingOnDraw() payable external {
     Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");

        uint _amount;
        _amount = msg.value;
        // uint256 userBalance;
        // userBalance = (msg.sender).balance;
        // require(userBalance >= _amount);
        // token.transferFrom(msg.sender, address(this), _amount);

        campaign.drawpool += _amount;
        campaign.amount += _amount;
        Answer[msg.sender] = 1;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        emit Deposit(count, msg.sender, _amount, "selected draw");
    }
    function startBettingOnTeam2() payable external {
        Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");

        uint _amount;
        _amount = msg.value;
        // uint256 userBalance;
        // userBalance = (msg.sender).balance;
        // require(userBalance >= _amount);
        // token.transferFrom(msg.sender, address(this), _amount);msg.sender, address(this), _amount);

        campaign.team2pool += _amount;
        campaign.amount += _amount;
        Answer[msg.sender] = 2;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        emit Deposit(count, msg.sender, _amount, "selected team 2");
    }
    function setEndAtRealTime () external onlyOwner{
        Match storage campaign = campaigns[count];
        campaign.endAt = block.timestamp;
    }

    function setwinner(uint resultMatch) external {
        Match storage campaign = campaigns[count];
        require(resultMatch < 3, "choise only must be one of the 0 , 1 , 2 numbers!!");
        require(msg.sender == owner, "just owner can");
        require(block.timestamp >= campaign.endAt, "not ended");
        require(address(this).balance != 0, "does not have any value");
        campaign.correctAnswer = resultMatch;
        campaign.endGameTime = block.timestamp;
        team1X = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.team1pool;
        drawX = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.drawpool;
        team2X = (campaign.team1pool + campaign.drawpool + campaign.team2pool) / campaign.team2pool;

        emit InputWinner(true);
    }

    function CheckAndGetReward() payable external {
        Match storage campaign = campaigns[count];
        require(Value[msg.sender] > 0, "you haven't any value in this contract");
        require(Answer[msg.sender] == campaign.correctAnswer, "you are not eligibate!");

        if ( campaign.correctAnswer == 0 ) {
            leverage = team1X;
        } else if( campaign.correctAnswer == 1) {
            leverage = drawX;
        } else if( campaign.correctAnswer == 2) {
            leverage = team2X;
        }
        uint amountToLeverage = (Value[msg.sender] * leverage);
        uint claimable = (((amountToLeverage) * 97 ) / 100);
        uint _fee = amountToLeverage - claimable;
        address _to = payable(msg.sender);
        Value[msg.sender] = 0;
        (bool sent, bytes memory data) = _to.call{value: claimable}("");
        require(sent, "Failed to send Ether");
        campaign.amount -= claimable;
        campaign.fee += _fee;
        emit ClaimReward(true, msg.sender, claimable, data);
    }
    function claimFee() payable external {
          Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.endGameTime, "not ended");
        require(msg.sender == owner, " owner can refund ");

        uint claimable = campaign.fee;
        (bool sent, bytes memory data) = owner.call{value: claimable}("");
        require(sent, "Failed to send Ether");

        emit ClaimFee(count, msg.sender, claimable, data);
    }

    function refund() payable external {
        Match storage campaign = campaigns[count];
        require(block.timestamp >= campaign.endGameTime, "not ended");
        require(msg.sender == owner, " owner can refund ");

        uint pool = address(this).balance;
        (bool sent,) = owner.call{value: pool}("");
        require(sent, "Failed to send Ether");

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


    
    receive() external payable {}


}