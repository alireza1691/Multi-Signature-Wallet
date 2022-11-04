// SPDX-License-Identifier: MIT
/* Author: Alireza Haghshenas
/ github account : alireza1691
/ this contract maded for betting on footbal matches
*/
pragma solidity ^0.8.17;


contract Bet {
    

    // Before each match we can start betting phase that users can bet on own choices
    // Note that couple minutes before match deposit phase expires untill match finished
    event Launch(
        string matchName,
        address indexed creator,
        uint startAt,
        uint endAt
    );

    // In deposit phase user's choose that they want bet on (team1 win / draw / team2 win)
    // note that we just bettig on everythings that may happened in 90 minute (extra time and penalty doesn't matter)
    
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
        uint correctAnswer;
        uint256 endGameTime;
        uint team1pool;
        uint drawpool;
        uint team2pool;
        uint fee;
        uint leverage;
    }
    struct User {
        uint depositOn1;
        uint depositOnDraw;
        uint depositOn2;
    }
    address payable owner;
    uint public count;

    // If you want to use special token for paymant, you can add address of token this way:
    // IERC20 public immutable token;
    // constructor (address _token) {
    constructor () {
        owner = payable(msg.sender);
    }
   
    mapping(address => User) public Users;
    address payable [] public users;
    mapping(uint => Match) public Matches;
    // mapping(address => uint) public Answer;
    // mapping(address => uint) public Value;
    mapping(address => bool) public isCorrect;

    
    

    function launch(string calldata _name) external onlyOwner{
       
        // When match launched by owner , users can bet
        uint256 _startAt = block.timestamp;
        // Default macth betting period expires 12 weeks after launch, but this time changed by owner couple minutes before match begins
        uint256 _endAt = block.timestamp + 12 weeks;
        // Every time a new match begins, counted this match for Match array that details can input in own Macth array
        count += 1;
        Matches [count] = Match ({
            name: _name, // Just uses for name of match
            amount: 0, // It shows how many value depositted in contract for this match 
            startAt: _startAt,
            endAt: _endAt,
            correctAnswer: 9, // That's just a numer , this number later changed and show result of match
            // If this number changed to '0' means that team 1 wins the match, if changed to '1' means draw and for '2' means that team winned match
            endGameTime: _endAt + 180 minutes, // As a default an footbal match takes 90 minutes , but because of half time and extra time it takes more than 90 minutes
            // Then we set 180 minutes as a default , but when owner set match result , this time changed
            team1pool : 0, // Each pool shows that how many value (as a default ETH) depositted in contract for any case  
            drawpool: 0 , // This number uses for calculate reward of winners and also show leverage before Deposit
            team2pool: 0, // Note that after any new deposit one of these numbers changed and it can changes leverage
            fee: 0, // This number uses for calculate contract fee
            leverage: 1 // Leverage as a default equal to 1 , but deposits change this number and finaly reward of winners: deposit amount of every winner * leverage 
        });
        emit Launch(_name, msg.sender, _startAt, _endAt);
    }
        // This function shows leverage of any case(team1win / draw / team2win) that user can look at them before deposit
   
        function getLevegarges () view public returns(uint, uint, uint){
            Match storage _match = Matches[count];
            uint team1X;
            uint drawX;
            uint team2X;
                team1X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team1pool;
                drawX = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.drawpool;
                team2X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team2pool;
            return(team1X, drawX, team2X);    
        }
        function startBettingOnTeam1() payable external {
        Match storage _match = Matches[count];
        User storage _user = Users[msg.sender];
        require(block.timestamp >= _match.startAt, "not started");
        require(block.timestamp <= _match.endAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");

        uint _amount;
        _amount = msg.value;
        _match.team1pool += _amount;
        _match.amount += _amount;
        // Answer[msg.sender] = 0;
        // Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        users.push(payable(msg.sender));
        _user.depositOn1 += _amount;

        emit Deposit(count, msg.sender, _amount, "selected team1");
    }
    function startBettingOnDraw() payable external {
        Match storage _match = Matches[count];
        User storage _user = Users[msg.sender];
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
        // Answer[msg.sender] = 1;
        // Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        users.push(payable(msg.sender));
        _user.depositOnDraw += _amount;
        emit Deposit(count, msg.sender, _amount, "selected draw");
    }
    function startBettingOnTeam2() payable external {
        Match storage _match = Matches[count];
        User storage _user = Users[msg.sender];
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
        // Answer[msg.sender] = 2;
        // Value[msg.sender] += _amount;
        isCorrect[msg.sender] = false;
        users.push(payable(msg.sender));
        _user.depositOn2 += _amount;
        emit Deposit(count, msg.sender, _amount, "selected team 2");
    }

    function withdrawBeforeBegin(uint amount_, uint key) payable external{
        Match storage _match = Matches[count];
        User storage _user = Users[msg.sender];
        require(amount_ <= _user.depositOn1 + _user.depositOnDraw + _user.depositOn2, "more than your balance");
        require(block.timestamp <= _match.endAt, "now you cannot withdraw");
        require(key < 3, "key is not correct");
        uint team1X;
        uint drawX;
        uint team2X;
        team1X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team1pool;
        drawX = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.drawpool;
        team2X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team2pool;
        uint depositable;
          if ( key == 0 ) {
            require(_user.depositOn1 >= 0);
            depositable = ((_user.depositOn1 * team1X / 3));
            _match.team1pool -= depositable;
            _user.depositOn1 -= depositable;
        } else if( key == 1) {
            require(_user.depositOnDraw >= 0);
            depositable = ((_user.depositOnDraw * drawX / 3));
            _match.drawpool -= depositable;
            _user.depositOnDraw -= depositable;
        } else if( key == 2) {
            require(_user.depositOn2 >= 0);
            depositable = ((_user.depositOn2 * team2X / 3));
            _match.team2pool -= depositable;
            _user.depositOn2 -= depositable;
        }
        address payable who = payable(msg.sender);
        _match.amount -= depositable;
        who.transfer(depositable * 97 / 100);
        _match.fee += (depositable * 3 / 100);


            
    }



    function setEndAtRealTime () external onlyOwner{
        Match storage _match = Matches[count];
        _match.endAt = block.timestamp;
    }

    function setwinner(uint resultMatch) external onlyOwner{
        Match storage _match = Matches[count];
        require(resultMatch < 3 , "choise only must be one of the 0 , 1 , 2 numbers!!");
        require(block.timestamp >= _match.endAt, "not ended");
        require(address(this).balance != 0, "does not have any value");
        _match.correctAnswer = resultMatch;
        _match.endGameTime = block.timestamp;

        emit InputWinner(true);
    }

    function sendReward () external payable onlyOwner{
        Match storage _match = Matches[count];
        // User storage _user = Users[];
        require(block.timestamp > _match.endGameTime, "not ended");
        require(_match.amount >= 0 , "not value");


        for (uint i = 0; i < users.length; i++){

            if ( _match.correctAnswer == 0 ) {
                require(Users[users[i]].depositOn1 > 0);
                
                users[i].transfer(((Users[users[i]].depositOn1) * _match.leverage) * 97 / 100);
                Users[users[i]].depositOn1 = 0;
                Users[users[i]].depositOnDraw = 0;
                Users[users[i]].depositOn2 = 0;
                _match.fee += (((Users[users[i]].depositOn1) * _match.leverage) * 3 / 100);
            } else if(_match.correctAnswer == 1) {
                require(Users[users[i]].depositOnDraw > 0);

                users[i].transfer(((Users[users[i]].depositOnDraw) * _match.leverage) * 97 / 100);
                Users[users[i]].depositOn1 = 0;
                Users[users[i]].depositOnDraw = 0;
                Users[users[i]].depositOn2 = 0;
                _match.fee += (((Users[users[i]].depositOn1) * _match.leverage) * 3 / 100);
            } else if (_match.correctAnswer == 2) {
                require(Users[users[i]].depositOn2 > 0);

                users[i].transfer(((Users[users[i]].depositOn2) * _match.leverage) * 97 / 100);
                Users[users[i]].depositOn1 = 0;
                Users[users[i]].depositOnDraw = 0;
                Users[users[i]].depositOn2 = 0;
                _match.fee += (((Users[users[i]].depositOn1) * _match.leverage) * 3 / 100);
            }
            
           
        }

    }
    function claimThisMatchFee() payable external onlyOwner{
          Match storage _match = Matches[count];
        require(block.timestamp >= _match.endGameTime, "not ended");

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
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    
    receive() external payable {}


}