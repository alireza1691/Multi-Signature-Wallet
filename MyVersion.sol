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
        uint startAt
    );

    // In deposit phase user's choose that they want bet on (team1 win / draw / team2 win)
    // note that we just bettig on everythings that may happened in 90 minute (extra time and penalty doesn't matter)
    
    event Deposit(address indexed caller, uint amount, string betOn);

    // Withdraw uses for withdraw any value that user wanted to claim form values that before deposited in contract
    // Note that user can withdraw before match starts
    event Withdraw(address indexed caller, uint amount, string indexed formWhere);

    // If some problem happened about match and onwer want to cancel match with this function can
    // Send back user's deposited amounts and cancel match 
    event CancelBeforStart(string indexed name, uint valueForReturnToUsers);

    // When match just ended (in 90 minutes + couple minutes extra time) owner inputed which one of 3 case happened
    // Uint amount inputes for set winner, 0 for team 1 win ,1 for draw , 2 for team 2 win
    event InputWinner(bool inputed);

    // This function called by owner and find winners, calculate rewards with leverage and send rewards to them
    // For example if one user deposited 1 ETH on team 1, then team 1 won the match and leverage was 4,contract send 1 * 4 = 4 ETH to user
    event SendRewrd(string indexed matchName);

    // This function called by owner and by this function claim fees 
    event ClaimFee(uint indexed id, address indexed caller, uint amount, bytes indexed _data);

    // These are every thing about a match that we need

    struct Match {           // Name of game
        uint value;               // All of amounted that deposited in contract (team1pool + team2pool + drawpool)
        uint256 startBetAt;               // After this time user can deposit
        uint256 endBetAt;               // After this time user can't deposit. this time set by owner couple minutes before start match
        uint correctAnswer;               // Correct answer must be one of 0,1,2 i'll explain it when we set this amount
        uint256 endMatchTime;               // When match finished and we know which one(0,1,2) happened
        uint team1pool;               // Shows how many value deposited on "team 1 win"
        uint drawpool;               // Shows how many value deposited on "draw"
        uint team2pool;               // Shows how many value deposited on "team 2 win"
        uint fee;               // fee of deposit,withdraw and send reward transactions that belongs to contract onwer
        uint leverage1;           // Calculate leverage for winners 
        uint leverageDraw;
        uint leverage2;
    }

    // Each user can deposit on each case and also withdraw , these are shows how manu value deposited on each pool
    struct User {
        uint depositOn1;
        uint depositOnDraw;
        uint depositOn2;
    }
    address payable owner;
    uint public countMatches;               // After each match we create new structure for new match and this amoun counted matches

    // If you want to use special token for paymant, you can add address of token this way:
    // IERC20 public immutable token;
    // constructor (address _token) {
    constructor () {
        owner = payable(msg.sender);
    }
   
    mapping(address => User) public Users;               // This mapping uses for finding user values on each pool
    address payable [] public users;               // User's pushed in array as a 'payable' address , because after match we want to send reward to winners
    mapping(uint => Match) public Matches;               // This mapping uses for each match , count matches gonna use for this mapping

    
    

    function launch() external onlyOwner{
       
        // When match launched by owner , users can bet
        uint256 _startAt = block.timestamp;
        // Default macth betting period expires 12 weeks after launch, but this time changed by owner couple minutes before match begins
        uint256 _endAt = block.timestamp + 12 weeks;
        // Every time a new match begins, counted this match for Match array that details can input in own Macth array
        countMatches += 1;
        Matches [countMatches] = Match ({
            value: 0, // When match just started, value is equal zero
            startBetAt: _startAt,
            endBetAt: _endAt,
            correctAnswer: 9, // That's just a numer , this number later changed and show result of match
            // If this number changed to '0' means that team 1 wins the match, if changed to '1' means draw and for '2' means that team winned match
            endMatchTime: _endAt + 180 minutes, // As a default an footbal match takes 90 minutes , but because of half time and extra time it takes more than 90 minutes
            // Then we set 180 minutes as a default , but when owner set match result , this time changed
            team1pool : 0, // Each pool shows that how many value (as a default ETH) deposited in contract for any case  
            drawpool: 0 , // This number uses for calculate reward of winners and also show leverage before Deposit
            team2pool: 0, // Note that after any new deposit one of these numbers changed and it can changes leverage
            fee: 0, 
            leverage1: 3,// Leverage as a default equal to 1 , but deposits change this number and finaly reward of winners: deposit amount of every winner * leverage 
            leverageDraw: 3,
            leverage2: 3
        });
        emit Launch( _startAt);
    }
        // This function shows leverage of any case(team1win / draw / team2win) that user can look at them before deposit
   
        function getLevegarges () view public returns(uint, uint, uint){
            Match storage _match = Matches[countMatches];
            return(_match.leverage1, _match.leverageDraw, _match.leverage2);    
        }
        function SetNewLeverages(uint team1, uint draw, uint team2) private {
            Match storage _match = Matches[countMatches];
            _match.leverage1 = (team1 + draw + team2) / team1;
            _match.leverageDraw = (team1 + draw + team2) / draw;
            _match.leverage2 = (team1 + draw + team2) / team2;
        }    


        // By this function user only can deposit on team 1
        function BetOn1() payable external {
        Match storage _match = Matches[countMatches];
        User storage _user = Users[msg.sender];         
        require(block.timestamp >= _match.startBetAt, "not started"); 
        require(block.timestamp <= _match.endBetAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");
        require(msg.value < msg.sender.balance, "bigger than your balance");

        uint _amount = msg.value * 97 / 100;
        _match.team1pool += _amount;
        _match.value += _amount;
        users.push(payable(msg.sender));
        _user.depositOn1 += _amount;
        _match.fee += msg.value * 3 / 100;

        // SetNewLeverages(_match.team1pool, _match.drawpool, _match.team2pool);

       
        
        emit Deposit(msg.sender, _amount, "Deposited on team1");

        
    }


    // By this function user only can deposit on Draw
    function BetOnDraw() payable external {
        Match storage _match = Matches[countMatches];
        User storage _user = Users[msg.sender];         
        require(block.timestamp >= _match.startBetAt, "not started"); 
        require(block.timestamp <= _match.endBetAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");
        require(msg.value < msg.sender.balance, "bigger than your balance");

        uint _amount = msg.value * 97 / 100;
        _match.drawpool += _amount;
        _match.value += _amount;
        users.push(payable(msg.sender));
        _user.depositOnDraw += _amount;
        _match.fee += msg.value * 3 / 100;

        // SetNewLeverages(_match.team1pool, _match.drawpool, _match.team2pool);


        emit Deposit(msg.sender, _amount, "Deposited on draw");
    }

    // By this function user only can deposit on team 2
    function BetOn2() payable external {
        Match storage _match = Matches[countMatches];
        User storage _user = Users[msg.sender];         
        require(block.timestamp >= _match.startBetAt, "not started"); 
        require(block.timestamp <= _match.endBetAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");
        require(msg.value < msg.sender.balance, "bigger than your balance");

        uint _amount = ( msg.value * 97 / 100 );
        _match.team2pool += _amount;
        _match.value += _amount;
        users.push(payable(msg.sender));
        _user.depositOn2 += _amount;
        _match.fee += msg.value * 3 / 100;
        // SetNewLeverages(_match.team1pool, _match.drawpool, _match.team2pool);


        emit Deposit(msg.sender, _amount, "Deposit on team 2");
    }

    
    // By this function user can withdaw amount in each pool that deposited before
    // Note that withdrawble amount maybe not eqal with deposited amout
    // Because it depended on each pool value, for exaple if you deposited 
    function withdrawFrom1(uint amount_) payable external{
        Match storage _match = Matches[countMatches];
        User storage _user = Users[msg.sender];
        require(_user.depositOn1 >= 0, "not enough balance");
        require(block.timestamp <= _match.endBetAt, "now you cannot withdraw"); 
        uint amountInEth = amount_ * 10 ** 18;
        uint PercentPool = (amountInEth)/ (_match.team1pool * 2);   
        uint PoolLeverage = (_match.team1pool * 3) / (_match.team1pool + _match.drawpool + _match.team2pool ) ;
        require((amountInEth ) < _user.depositOn1, "bigger than your balance");
        _match.team1pool -= amountInEth;
        _user.depositOn1 -= amountInEth;

        address payable who = payable(msg.sender);
        _match.value -= amountInEth;
        who.transfer((amountInEth * PoolLeverage * 97 / 100) - PercentPool);
        _match.fee += (amount_ * 3 / 100);
 
        emit Withdraw(msg.sender, amountInEth, "withdrawed from team 1 pool");


            
    }
    function withdrawFromDraw(uint amount_) payable external{
       Match storage _match = Matches[countMatches];
        User storage _user = Users[msg.sender];
        require(_user.depositOn1 >= 0, "not enough balance");
        require(block.timestamp <= _match.endBetAt, "now you cannot withdraw"); 
        uint amountInEth = amount_ * 10 ** 18;
        uint PercentPool = (amountInEth)/ (_match.drawpool * 2);   
        uint PoolLeverage = (_match.drawpool * 3) / (_match.team1pool + _match.drawpool + _match.team2pool ) ;
        require((amountInEth ) < _user.depositOnDraw , "bigger than your balance");
        _match.drawpool -= amountInEth;
        _user.depositOnDraw -= amountInEth;

        address payable who = payable(msg.sender);
        _match.value -= amountInEth;
        who.transfer((amountInEth * PoolLeverage * 97 / 100) - PercentPool);
        _match.fee += (amount_ * 3 / 100);
       
        emit Withdraw(msg.sender, amount_, "pool draw withdrawed");
       
    }
    function withdrawFrom2(uint amount_) payable external{
        Match storage _match = Matches[countMatches];
        User storage _user = Users[msg.sender];
        require(_user.depositOn2 >= 0, "not enough balance");
        require(block.timestamp <= _match.endBetAt, "now you cannot withdraw"); 
        uint amountInEth = amount_ * 10 ** 18;
        uint PercentPool = (amountInEth)/ (_match.team2pool * 2);   
        uint PoolLeverage = (_match.team2pool * 3) / (_match.team1pool + _match.drawpool + _match.team2pool ) ;
        require((amountInEth ) < _user.depositOn2 , "bigger than your balance");
        _match.team2pool -= amountInEth;
        _user.depositOn2 -= amountInEth;

        address payable who = payable(msg.sender);
        _match.value -= amountInEth;
        who.transfer((amountInEth * PoolLeverage * 97 / 100) - PercentPool);
        _match.fee += (amount_ * 3 / 100);
 
        emit Withdraw(msg.sender, amount_, "withdrawed from team2 pool");


            
    }
    
    function cancellMatch()external onlyOwner {
        Match storage _match = Matches[countMatches];

        for (uint i = 0; i < users.length; i++){
            uint userBalance;
            userBalance = Users[users[i]].depositOn1 + Users[users[i]].depositOnDraw + Users[users[i]].depositOn2;
            
            users[i].transfer((userBalance)  * 97 / 100);
            Users[users[i]].depositOn1 = 0;
            Users[users[i]].depositOnDraw = 0;
            Users[users[i]].depositOn2 = 0;
            _match.value -= userBalance;
            _match.fee += (userBalance * 3 / 100);

        
        }
        countMatches ++;
    }



    function setStopBetTillFinish () external onlyOwner{
        Match storage _match = Matches[countMatches];
        _match.endBetAt = block.timestamp;
    }

    function setwinner(uint resultMatch) external onlyOwner{
        Match storage _match = Matches[countMatches];
        require(resultMatch < 3 , "choise only must be one of the 0 , 1 , 2 numbers!!");
        require(block.timestamp >= _match.endBetAt, "Not used stop bet before match!!");
        require(address(this).balance != 0, "does not have any value");
        _match.correctAnswer = resultMatch;
        _match.endMatchTime = block.timestamp;

        emit InputWinner(true);
    }

    function sendReward () external payable onlyOwner{
        Match storage _match = Matches[countMatches];
        // User storage _user = Users[];
        require(block.timestamp > _match.endMatchTime, "not ended");
        require(_match.value >= 0 , "not value");
        uint amount;
        uint team1X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team1pool;
        uint drawX = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.drawpool;
        uint team2X = (_match.team1pool + _match.drawpool + _match.team2pool) / _match.team2pool;


            for (uint i = 0; i < users.length; i++){
            
            
            if (_match.correctAnswer == 0) {
                // require(Users[users[i]].depositOn1 > 0, "not value");
                amount = Users[users[i]].depositOn1 * team1X ;
                users[i].transfer(amount * 97 / 100);
                _match.fee += (amount * 3 / 100);
                
            } else if ( _match.correctAnswer == 1) {
                // require(Users[users[i]].depositOnDraw > 0, "not value");
                users[i].transfer(amount);
                amount = Users[users[i]].depositOnDraw * drawX ;
                users[i].transfer(amount * 97 / 100);
                _match.fee += (amount * 3 / 100);

            } else if ( _match.correctAnswer ==2) {
                // require(Users[users[i]].depositOn2 > 0, "not value");
                users[i].transfer(amount);
                amount = Users[users[i]].depositOn2 * team2X ;
                users[i].transfer(amount * 97 / 100);
                _match.fee += (amount * 3 / 100);
            }
           
        }
            
           

    }
    function claimThisMatchFee() payable external onlyOwner{
          Match storage _match = Matches[countMatches];
        require(block.timestamp >= _match.endMatchTime, "not ended");

        uint claimable = _match.fee;
        (bool sent, bytes memory data) = owner.call{value: claimable}("");
        require(sent, "Failed to send Ether");

        emit ClaimFee(countMatches, msg.sender, claimable, data);
    }

    function refund() payable external {
        Match storage _match = Matches[countMatches];
        require(block.timestamp >= _match.endMatchTime, "not ended");
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