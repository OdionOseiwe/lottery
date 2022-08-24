// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// a person comes to buy a ticket for the right price and the lottery have a set time
/// and the owner comes to start the lottery and a random number is gotten at random to get
/// the winner the money is send to the winner when the owner calls the  announceWinner function

contract Lottery {
    address owner;
    uint32 timePeriod;
    uint32 ticketPrice;
    address[] players;
    bool start;
    bool finish;

    mapping(address => uint) playersDetails;

    constructor() {
        owner = msg.sender;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    ///  custom error

    /// finished lottery
    error finished();

    /// pay the complete money na
    error pay();

    /// @dev events

    event boughtTicket(address indexed buyer, uint amount);
    event AnnounceWinner(address winner, uint winningPrice);

    function startLottery(uint32 _ticketPrice) external OnlyOwner {
        ticketPrice = _ticketPrice;
        timePeriod = uint32(block.timestamp + 2 minutes);
        start = true;
    }

    function buyAticket() external payable {
        require(block.timestamp <= timePeriod, "finished");
        if (finish == true) {
            revert finished();
        }
        if (msg.value != ticketPrice) {
            revert pay();
        }
        playersDetails[msg.sender] = msg.value;
        players.push(msg.sender);
        emit boughtTicket(msg.sender, msg.value);
    }

    function randomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function winnerNumber() public view returns (uint) {
        uint index = randomNumber() % players.length;
        return index;
    }

    function calculateWinnerPrice() public view returns (uint) {
        uint bal = address(this).balance;
        return (bal * 75) / 100;
    }

    function announceWinner() external OnlyOwner {
        require(block.timestamp >= timePeriod, "not finished");
        require(start == true, "neva started");
        if (finish == true) {
            revert finished();
        }
        uint index = winnerNumber();
        uint winningPrice = calculateWinnerPrice();
        address winner = players[index];
        playersDetails[winner] = 0;
        (bool sent, ) = payable(winner).call{value: winningPrice}("");
        require(sent, "failed");
        finish = true;
        emit AnnounceWinner(winner, winningPrice);
    }

    function withdraw() external OnlyOwner {
        uint ownerMoney = address(this).balance - calculateWinnerPrice();
        (bool sent, ) = payable(owner).call{value: ownerMoney}("");
        require(sent, "failed");
    }

    receive() external payable {}
}
