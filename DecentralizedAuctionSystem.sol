// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract DecentralizedAuctionSystem {

    struct Auction {
        address seller;
        string itemName;
        uint minimumBid;
        uint highestBid;
        address highestBidder;
        uint endTime;
        bool ended;
        bool fundsWithdrawn;
    }

    // Stores all auctions using a unique auction ID
    mapping(uint => Auction) public auction;
    uint public auctionCount;

    // Stores participant bids for each auction
    mapping(uint => mapping(address => uint)) public participantsList;

    // ---- --- ----
    mapping(uint => mapping(address => uint)) public pendingReturns;

    function createAuction(
        string memory _itemName,
        uint _minimumBid,
        uint _endtime
    ) public {
        require(_minimumBid > 0, "Minimum bid must be greater than zero");
        require(_endtime > 0, "Duration must be greater than zero");

        uint auctionId = auctionCount;

        auction[auctionId].seller = msg.sender;
        auction[auctionId].itemName = _itemName;
        auction[auctionId].minimumBid = _minimumBid;
        auction[auctionId].endTime = block.timestamp + _endtime;

        auctionCount++;
    }

    function placeBid(uint auctionId) public payable {
        require(msg.value > 0, "Amount must be greater than zero");
        require(auctionId < auctionCount, "Auction does not exist");
        require(!auction[auctionId].ended, "Auction has ended");
        require(
            block.timestamp < auction[auctionId].endTime,
            "Auction deadline passed"
        );
        require(
            msg.sender != auction[auctionId].seller,
            "Seller cannot bid"
        );
        require(
            msg.value >= auction[auctionId].minimumBid,
            "Bid is below minimum"
        );
        require(
            msg.value > auction[auctionId].highestBid,
            "Bid must be higher than current highest bid"
        );

        // Refund Logic 
        if(auction[auctionId].highestBidder != address(0))  {
            // Here I am Doing += I am updating the value here in the previous bid of the smae person
            pendingReturns[auctionId][auction[auctionId].highestBidder] += auction[auctionId].highestBid;
        }   
        //
        auction[auctionId].highestBid = msg.value;
        auction[auctionId].highestBidder = msg.sender;

        participantsList[auctionId][msg.sender] = msg.value;
    }
    // 
        function withdrawRefund(uint auctionId) public {
            require(auctionId < auctionCount, "Auction does not exist");
            // check
            uint amount = pendingReturns[auctionId][msg.sender];
            require(amount > 0, "Amount Should be greater then zero");
            //Effect
            pendingReturns[auctionId][msg.sender] = 0;
            // Interaction 
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "Transfer is fiald");
        }

        // endAuction 
       function endAuction(uint auctionId) public {
         // Checks
        require(auctionId < auctionCount, "Auction does not exist");
        require(!auction[auctionId].ended, "Auction already ended");

        require(
            block.timestamp >= auction[auctionId].endTime,
                "Auction is still going on" );

        // Effects
        auction[auctionId].ended = true;
    }
    //
    function withdrawFunds(uint auctionId) public {
    // Checks
    require(auctionId < auctionCount, "Auction does not exist");
    require(msg.sender == auction[auctionId].seller, "Only seller can withdraw");
    require(auction[auctionId].ended, "Auction is not ended yet");
    require(!auction[auctionId].fundsWithdrawn, "Funds already withdrawn");

    uint amount = auction[auctionId].highestBid;
    require(amount > 0, "No winning bid");

    // Effects
    auction[auctionId].fundsWithdrawn = true;

    // Interaction
    (bool success,) = payable(msg.sender).call{value: amount}("");
    require(success, "Transfer failed");
}
}