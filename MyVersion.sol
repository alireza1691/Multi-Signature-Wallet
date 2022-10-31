// SPDX-License-Identifier: MIT
/* Author: Alireza Haghshenas
/ github account : alireza1691
/ this contract maded for betting on footbal matches
*/
pragma solidity ^0.8.17;


contract Bet {
    

    // Before each match we can start betting phase that users can bet on own choices
    event Launch(
        string matchName,
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
    event SendRewrd(string indexed matchName);

    struct Match {
        string name;
        uint amount;
        uint256 startAt;
        uint256 endAt;
        bool expired;
        uint  correctAnswer;
        uint256  endGameTime;
        uint  team1pool;
        uint  drawpool;
        uint  team2pool;
        uint  fee;
        uint  leverage;
    }
    address payable owner;
    uint public count;


    // IERC20 public immutable token;
    // constructor (address _token) {
    constructor () {
        owner = payable(msg.sender);
    }
    //  constructor () {
    //     owner = payable(msg.sender);
    // }   

    address payable [] public users;
    mapping(uint => Match) public Matches;
    // mapping(uint => mapping(address => bool)) public approved;
    // mapping(uint => mapping(address => uint)) public pledgedAmount;
    // mapping(uint => mapping(address => uint256)) public UserAnswer;
    mapping(address => uint) public Answer;
    mapping(address => uint) public Value;
    mapping(address => bool) public isCorrect;

    function sendReward () external payable onlyOwner{
        Match storage _match = Matches[count];
        require(block.timestamp > _match.endGameTime, "not ended");
        require(_match.amount >= 0 , "not value");
        if ( _match.correctAnswer == 0 ) {
            _match.leverage = team1X;
        } else if( _match.correctAnswer == 1) {
            _match.leverage = drawX;
        } else if( _match.correctAnswer == 2) {
            _match.leverage = team2X;
        }
        


        for (uint i = 0; i < users.length; i++){
            uint amount = ((((Value[users[i]]) * _match.leverage)* 97 ) / 100);
            if (Answer[users[i]] == _match.correctAnswer) {
                
                users[i].transfer(amount);
                
            } else { continue;
            }
           
        }
    }

    function launch(string calldata _name) external onlyOwner{
       
        uint256 _startAt = block.timestamp;
        uint256 _endAt = block.timestamp + 12 weeks;
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        count += 1;
        Matches [count] = Match ({
            name: _name,
            amount: 0,
            startAt: _startAt,
            endAt: _endAt,
            expired: false,
            correctAnswer: 9,
            endGameTime: _endAt + 180 minutes,
            team1pool : 0,
            drawpool: 0 ,
            team2pool: 0,
            fee: 0,
            leverage: 1
        });
        emit Launch(_name, msg.sender, _startAt, _endAt);
    }
    uint internal team1X;
    uint internal drawX;
    uint internal team2X;
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
        function getLevegarges () public {
            Match storage _match = Matches[count];
                team1X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team1pool;
                drawX = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.drawpool;
                team2X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team2pool;
        }
        function startBettingOnTeam1() payable external {
        Match storage _match = Matches[count];
        require(block.timestamp >= _match.startAt, "not started");
        require(block.timestamp <= _match.endAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");

        uint _amount;
        _amount = msg.value;
        // uint256 userBalance;
        // userBalance = (msg.sender).balance;
        // require(userBalance >= _amount);
        // token.transferFrom(msg.sender, address(this), _amount);

        _match.team1pool += _amount;
        _match.amount += _amount;
        Answer[msg.sender] = 0;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        users.push(payable(msg.sender));

        emit Deposit(count, msg.sender, _amount, "selected team1");
    }
    function startBettingOnDraw() payable external {
     Match storage _match = Matches[count];
        require(block.timestamp >= _match.startAt, "not started");
        require(block.timestamp <= _match.endAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");

        uint _amount;
        _amount = msg.value;
        // uint256 userBalance;
        // userBalance = (msg.sender).balance;
        // require(userBalance >= _amount);
        // token.transferFrom(msg.sender, address(this), _amount);

        _match.drawpool += _amount;
        _match.amount += _amount;
        Answer[msg.sender] = 1;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        users.push(payable(msg.sender));
        emit Deposit(count, msg.sender, _amount, "selected draw");
    }
    function startBettingOnTeam2() payable external {
        Match storage _match = Matches[count];
        require(block.timestamp >= _match.startAt, "not started");
        require(block.timestamp <= _match.endAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");

        uint _amount;
        _amount = msg.value;
        // uint256 userBalance;
        // userBalance = (msg.sender).balance;
        // require(userBalance >= _amount);
        // token.transferFrom(msg.sender, address(this), _amount);msg.sender, address(this), _amount);

        _match.team2pool += _amount;
        _match.amount += _amount;
        Answer[msg.sender] = 2;
        Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        users.push(payable(msg.sender));
        emit Deposit(count, msg.sender, _amount, "selected team 2");
    }
    function setEndAtRealTime () external onlyOwner{
        Match storage _match = Matches[count];
        _match.endAt = block.timestamp;
    }

    function setwinner(uint resultMatch) external {
        Match storage _match = Matches[count];
        require(resultMatch < 3, "choise only must be one of the 0 , 1 , 2 numbers!!");
        require(msg.sender == owner, "just owner can");
        require(block.timestamp >= _match.endAt, "not ended");
        require(address(this).balance != 0, "does not have any value");
        _match.correctAnswer = resultMatch;
        _match.endGameTime = block.timestamp;
        team1X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team1pool;
        drawX = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.drawpool;
        team2X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team2pool;

        emit InputWinner(true);
    }

    function CheckAndGetReward() payable external {
        Match storage _match = Matches[count];
        require(Value[msg.sender] > 0, "you haven't any value in this contract");
        require(Answer[msg.sender] == _match.correctAnswer, "you are not eligibate!");
        require(isCorrect[msg.sender] == true);

        if ( _match.correctAnswer == 0 ) {
            _match.leverage = team1X;
        } else if( _match.correctAnswer == 1) {
            _match.leverage = drawX;
        } else if( _match.correctAnswer == 2) {
            _match.leverage = team2X;
        }
        uint amountToLeverage = (Value[msg.sender] * _match.leverage);
        uint claimable = (((amountToLeverage) * 97 ) / 100);
        uint _fee = amountToLeverage - claimable;
        address _to = payable(msg.sender);
        Value[msg.sender] = 0;
        isCorrect[msg.sender] = false;
        (bool sent, bytes memory data) = _to.call{value: claimable}("");
        require(sent, "Failed to send Ether");
        _match.amount -= claimable;
        _match.fee += _fee;
        emit ClaimReward(true, msg.sender, claimable, data);
    }
    function claimFee() payable external {
          Match storage _match = Matches[count];
        require(block.timestamp >= _match.endGameTime, "not ended");
        require(msg.sender == owner, " owner can refund ");

        uint claimable = _match.fee;
        (bool sent, bytes memory data) = owner.call{value: claimable}("");
        require(sent, "Failed to send Ether");

        emit ClaimFee(count, msg.sender, claimable, data);
    }

    function refund() payable external {
        Match storage _match = Matches[count];
        require(block.timestamp >= _match.endGameTime, "not ended");
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