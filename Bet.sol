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

    // struct Match {           // Name of game
    //     uint value;               // All of amounted that deposited in contract (team1pool + team2pool + drawpool)
    //     uint256 startBetAt;               // After this time user can deposit
    //     uint256 endBetAt;               // After this time user can't deposit. this time set by owner couple minutes before start match
    //     uint correctAnswer;               // Correct answer must be one of 0,1,2 i'll explain it when we set this amount
    //     uint256 endMatchTime;               // When match finished and we know which one(0,1,2) happened
    //     uint team1pool;               // Shows how many value deposited on "team 1 win"
    //     uint drawpool;               // Shows how many value deposited on "draw"
    //     uint team2pool;               // Shows how many value deposited on "team 2 win"
    //     uint fee;               // fee of deposit,withdraw and send reward transactions that belongs to contract onwer
    //     uint leverage1 ;           // Calculate leverage for winners 
    //     uint leverageDraw;
    //     uint leverage2;
    // }

    // Each user can deposit on each case and also withdraw , these are shows how manu value deposited on each pool
    struct User {
        uint depositOn1;
        uint depositOn2;
        uint depositOn3;
    }
    address payable owner;
    uint public countMatches;               // After each match we create new structure for new match and this amoun counted matches
    

    uint private value;
    uint private num1pool;
    uint private num2pool;
    uint private num3pool;
    uint private lev1 ;
    uint private lev2 ;
    uint private lev3 ;
    uint private startPeriodAt;
    uint private endPeriodAt;
    uint private resultShownAt;
    uint private fee = 1;
    uint private answer;
    uint private sendRewardTime;

    // If you want to use special token for paymant, you can add address of token this way:
    // IERC20 public immutable token;
    // constructor (address _token) {
    constructor () {
        owner = payable(msg.sender);
    }
   
    mapping(address => User) public Users;               // This mapping uses for finding user values on each pool
    address payable [] public users;               // User's pushed in array as a 'payable' address , because after match we want to send reward to winners
    // mapping(uint => Match) public Matches;               // This mapping uses for each match , count matches gonna use for this mapping

    
    

    function launch() external payable onlyOwner{

        require( msg.value > 0.3 ether, "at least 0.3 eth deposit 0.3 eth by owner");
        startPeriodAt = block.timestamp;
        endPeriodAt = block.timestamp + 24 weeks;
        resultShownAt = block.timestamp + 48 weeks ;
        sendRewardTime = block.timestamp + 1000000 weeks;
        uint depositAmount = msg.value;
        uint eachPool = depositAmount / 3;
        num1pool += eachPool;
        num2pool += eachPool;
        num3pool += eachPool;
        updateVariables(num1pool, num2pool, num3pool);
        
        
        emit Launch( startPeriodAt);
    }
        // This function shows leverage of any case(team1win / draw / team2win) that user can look at them before deposit
   
    function getDetails () view public returns(uint, uint, uint, uint, uint, uint, uint){
        return(lev1, lev2, lev3, num1pool, num2pool, num3pool, value);    
    }
    function setFee (uint newFee) external onlyOwner {
        require(newFee < 15 && newFee >= 0 ,"fee must be between 0.85 and 0.99");
        fee = newFee;
    }
    function updateVariables (uint _pool1, uint _pool2, uint _pool3) internal {
        value = _pool1 + _pool2 + _pool3;
        lev1 = value / _pool1;
        lev2 = value / _pool2;
        lev3 = value / _pool3;

    }
         


        // By this function user only can deposit on team 1
    function BetOn1() payable external {        
        require(block.timestamp >= startPeriodAt, "not started"); 
        require(block.timestamp <= endPeriodAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");
        require(msg.value < msg.sender.balance, "bigger than your balance");
        users.push(payable(msg.sender));
        User storage _user = Users[msg.sender];

        uint _amount = msg.value ;
        num1pool += _amount;
        
        _user.depositOn1 += _amount * (100 - fee) / 100;
        
        updateVariables(num1pool, num2pool, num3pool);
        
        
        emit Deposit(msg.sender, _amount, "Deposited on pool1");

        
    }


    // By this function user only can deposit on Draw
    function BetOn2() payable external { 
        require(block.timestamp >= startPeriodAt, "not started"); 
        require(block.timestamp <= endPeriodAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");
        require(msg.value < msg.sender.balance, "bigger than your balance");
        users.push(payable(msg.sender));
        User storage _user = Users[msg.sender]; 

        uint _amount = msg.value ;
        num2pool += _amount;
        
        
        _user.depositOn2 += _amount * (100 - fee) / 100;
        updateVariables(num1pool, num2pool, num3pool);
        
        emit Deposit(msg.sender, _amount, "Deposited on pool2");
    }

    // By this function user only can deposit on team 2
    function BetOn3() payable external {        
        require(block.timestamp >= startPeriodAt, "not started"); 
        require(block.timestamp <= endPeriodAt, "time to bet was over");
        require(msg.value > 0.01 ether, "too smal amount");
        require(msg.value < msg.sender.balance, "bigger than your balance");
        users.push(payable(msg.sender));
        User storage _user = Users[msg.sender]; 

        uint _amount = msg.value ;
        num3pool += _amount;
        
        _user.depositOn3 += _amount * (100 - fee) / 100;
        updateVariables(num1pool, num2pool, num3pool);

        emit Deposit(msg.sender, _amount, "Deposit on pool3");
    }

    
    // By this function user can withdaw amount in each pool that deposited before
    // Note that withdrawble amount maybe not eqal with deposited amout
    // Because it depended on each pool value, for exaple if you deposited 
    function withdrawFrom1(uint amount_) payable external{
        User storage _user = Users[msg.sender];
        require(_user.depositOn1 >= 0, "your balance equal '0'");
        require(block.timestamp < endPeriodAt, "now you cannot withdraw"); 
        uint amountInEth = amount_ * 10 ** 18;
        uint PercentPool = amountInEth/ (num1pool * 2);   
        require((amountInEth ) <= _user.depositOn1, "bigger than your balance");
        num1pool -= amountInEth;
        _user.depositOn1 -= amountInEth;

        address payable who = payable(msg.sender);
        who.transfer((amountInEth * (100 - fee) / 100) - PercentPool);

        updateVariables(num1pool, num2pool, num3pool);
 
        emit Withdraw(msg.sender, amountInEth, "withdrawed from pool1");


            
    }
    function withdrawFrom2(uint amount_) payable external{
        User storage _user = Users[msg.sender];
        require(_user.depositOn2 >= 0, "your balance equal '0'");
        require(block.timestamp < endPeriodAt, "now you cannot withdraw"); 
        uint amountInEth = amount_ * 10 ** 18;
        uint PercentPool = amountInEth/ (num2pool * 2);   
        require((amountInEth ) < _user.depositOn2, "bigger than your balance");
        num2pool -= amountInEth;
        _user.depositOn2 -= amountInEth;

        address payable who = payable(msg.sender);
        who.transfer((amountInEth * (100 - fee) / 100) - PercentPool);

        updateVariables(num1pool, num2pool, num3pool);

        emit Withdraw(msg.sender, amount_, "withdrawed from pool2");
       
    }
    function withdrawFrom3(uint amount_) payable external{
        User storage _user = Users[msg.sender];
        require(_user.depositOn3 >= 0, "your balance equal '0'");
        require(block.timestamp < endPeriodAt, "now you cannot withdraw"); 
        uint amountInEth = amount_ * 10 ** 18;
        uint PercentPool = amountInEth/ (num3pool * 2);   
        require((amountInEth ) < _user.depositOn3, "bigger than your balance");
        num3pool -= amountInEth;
        _user.depositOn3 -= amountInEth;

        address payable who = payable(msg.sender);
        who.transfer((amountInEth * (100 - fee) / 100) - PercentPool);

        updateVariables(num1pool, num2pool, num3pool);
 
        emit Withdraw(msg.sender, amount_, "withdrawed from team3 pool");


            
    }
    
    function cancellMatch()external onlyOwner {

        for (uint i = 0; i < users.length; i++){
            uint userBalance;
            userBalance = Users[users[i]].depositOn1 + Users[users[i]].depositOn2 + Users[users[i]].depositOn3;
            
            users[i].transfer((userBalance)  * (100 - fee) / 100);
            Users[users[i]].depositOn1 = 0;
            Users[users[i]].depositOn2 = 0;
            Users[users[i]].depositOn3 = 0;

        }
        sendRewardTime = block.timestamp;
        
        num1pool = 0;
        num2pool = 0;
        num3pool = 0;
        updateVariables(num1pool, num2pool, num3pool);
    }



    function setEndPeriod () external onlyOwner{
        endPeriodAt = block.timestamp;
    }

    function setwinner(uint resultMatch) external onlyOwner{
        require(resultMatch < 4 && resultMatch > 0, "choise only must be one of the 1 , 2 , 3 numbers!!");
        require(block.timestamp > endPeriodAt, "you can not set winer before end period!!");
        answer = resultMatch;
        resultShownAt = block.timestamp;

        emit InputWinner(true);
    }

    function sendReward () external payable onlyOwner{
        require(block.timestamp > resultShownAt, "result not showned!");
        require(address(this).balance != 0 , "there is not value in contract");


            for (uint i = 0; i < users.length; i++){
            uint amount;
            
            if (answer == 1) {
                // require(Users[users[i]].depositOn1 > 0, "not value");
                amount = Users[users[i]].depositOn1 * lev1 ;
                users[i].transfer(amount * (100 - fee) / 100);
                Users[users[i]].depositOn1 = 0;
                
            }
            if ( answer == 2) {
                // require(Users[users[i]].depositOnDraw > 0, "not value");
                amount = Users[users[i]].depositOn2 * lev2 ;
                users[i].transfer(amount * (100 - fee) / 100);
                Users[users[i]].depositOn2 = 0;
        
            }
            if ( answer == 3) {
                // require(Users[users[i]].depositOn2 > 0, "not value");
                amount = Users[users[i]].depositOn3 * lev3 ;
                users[i].transfer(amount * (100 - fee) / 100);
                Users[users[i]].depositOn3 = 0;
            }

            sendRewardTime = block.timestamp;
           
        }
            
           

    }
    function claimFirstValuePlusFee() payable external onlyOwner{
        require(block.timestamp >= sendRewardTime, "user's reward not sended yet!");



        (bool sent, bytes memory data) = address(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        emit ClaimFee(countMatches, msg.sender, msg.value, data);
    }

    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    
    receive() external payable {}


}