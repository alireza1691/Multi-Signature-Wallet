//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PurchaseAgreement {
    uint public price;
    address payable public seller;
    address payable public buyer;

    enum State { Created, Locked, Release, Inactive}
    State public state;

    constructor() payable {
        seller = payable(msg.sender);
        price = msg.value / 2;
        state = State.Created
    }

    error InvalidState();
    error OnlyBuyer();
    error OnlySeller();

    modifier inState(State state_) {
        if(state != state_) {
            revert InvalidState();
        }
        _;
    }
    modifier onlyBuyer() {
        if(msg.sender != buyer) {
            revert OnlyBuyer();
        }
        _;
    }
    modifier onlySeller() {
        if(msg.sender != seller) {
            revert onlySeller();
        }
        _;
    }


    function confirmPurchase() external inState(State.Created) payable {
        require(msg.value == (2 * price), "please send 2x the price")
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    function confirmReceived() external onlyBuyer inState(State.Locked) {
        state = State.Release;
        buyer.transfer(value);
    }

    function paySeller() external onlySeller inState(State.Release) {
        state = State.Inactive;
        seller.transfer(3 * price);
    }

    function abort() external onlySeller inState(State.Created){
        state = State.Inactive;
        seller.transfer(address(this).balance)
    }
}