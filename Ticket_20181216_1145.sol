pragma solidity >=0.4.22 <0.6.0;

library SafeMath
{
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a+b;
        assert (c>=a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(a>=b);
        return (a-b);
    }

    function mul(uint256 a,uint256 b)internal pure returns (uint256)
    {
        if (a==0)
        {
        return 0;
        }
        uint256 c = a*b;
        assert ((c/a)==b);
        return c;
    }

    function div(uint256 a,uint256 b)internal pure returns (uint256)
    {
        return a/b;
    }
}

contract Owned
{
    address public owner;
    constructor() internal
    {
        owner = msg.sender;
    }

    modifier onlyowner()
    {
    	require(msg.sender==owner);
        _;
    }
}

contract Ticket is Owned
{
	enum Stage
	{
        Open,
        Regist,
        Refund,
        Pause,
        Auction
    }
	
	function NextStage()onlyowner() public
    {

        if (stage==Stage.Regist)
        {
             stage=Stage.Pause;
        }
        
        if (stage==Stage.Refund)
        {
             stage=Stage.Pause;
        }
    }
	
	Stage public stage;
    using SafeMath for *;
    string constant public name = "Tickets";

    uint256 public Price;
    address public owner;

	uint256 public TicketsRelease;
	uint256 public PersonalLimtit;
	uint256 internal distributed;
    constructor() public
    {
        owner = msg.sender;
		stage= Stage.Open;
		PersonalLimtit = 2;
		registCount = 0;
		distributed = 0;
    }
    
    function OwnerSet(uint256 Tprice,uint256 ticketsRelease) onlyowner() public
	{
		require(stage==Stage.Open);
		Price = Tprice;
		TicketsRelease = ticketsRelease;
		stage= Stage.Regist;
	}
	// Save the registed adress
	mapping (uint256 => address) public registTable;
	mapping (address => uint256) public PersonalRegistCount;
	mapping (address => uint[]) public Personalindex;
	
	uint256 public registCount;
	
	 // Mapping from Ticket ID to owner
	mapping (uint256 => address) public TicketOwner;
	// Mapping from owner to number of owned Ticket
	mapping (address => uint256) public ownedTicketsCount;
	uint[] public WinnerIndexList;
	
	function Register(uint256 ticketCount) payable public
	{	
	    uint256 askedTicket;
	    uint256 MarginCount;
		require(stage!=Stage.Open,"Stage : open");
		require(stage!=Stage.Pause,"Stage : Pause");
		askedTicket = PersonalRegistCount[msg.sender] + ticketCount;
		require(askedTicket<=PersonalLimtit,"PersonalLimtit exceed");
		MarginCount = ticketCount.mul(Price);
		require(msg.value>=MarginCount,"Input Amount not enough");
		for(uint i=0; i<ticketCount; i++)
        {
			registTable[registCount] = msg.sender;
			Personalindex[msg.sender].push(registCount);
			PersonalRegistCount[msg.sender] ++;
			registCount ++;
        } 
	}
	
	function log2(uint x) internal returns (uint y){
       assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
	}
	
	function rightShift(uint x,uint y) pure internal returns (uint256) {
        return x>>y;
    }

    function leftShift(uint x,uint y) pure internal returns (uint256) {
        return x<<y;
    }

	mapping (address => uint[]) public PersonalTicketindex;

	function draw(uint256 WinnerCount) onlyowner public
	{
	    require((TicketsRelease-distributed)>=WinnerCount);
		uint256 rndIndex;
		rndIndex = log2(registCount);
		if (rndIndex == 0)
		{
		    rndIndex =1;
		}
		uint256 numberDrawed;
		uint256 Rndvalue;
		
		Rndvalue = rand;
		
		address winner;
		uint256 loopCount;
		
		loopCount =  256.div(rndIndex);
		uint currentDistributed;
		currentDistributed = 0;
		for(uint i=0; i<loopCount; i++)
        {
			
			numberDrawed = rightShift(Rndvalue,(256).sub(rndIndex));
		    numberDrawed = numberDrawed%registCount;
		    
			Rndvalue = leftShift(Rndvalue,rndIndex);
	    	winner = registTable[numberDrawed];
	    
	    	
			if (TicketOwner[numberDrawed]==address(0))
			{
			    TicketOwner[numberDrawed] = winner;
				WinnerIndexList.push(numberDrawed);
				PersonalTicketindex[winner].push(numberDrawed);
			    ownedTicketsCount[winner]++;
			    distributed ++;
			    currentDistributed++;
				
			}
			if (currentDistributed >=WinnerCount)
			{
			    break;
			}
        }
	}
	
	function Quit(uint256 ticketCount) public 
	{	
	    require(PersonalRegistCount[msg.sender]>=ticketCount);
	    require(ticketCount>0);
	    
	   uint ownerIndex;
	    for(uint j=1; j<=ticketCount; j++)
        {
	        ownerIndex  =  Personalindex[msg.sender][PersonalRegistCount[msg.sender].sub(j)];
	        registTable[ownerIndex] = address(0);
            registCount = registCount.sub(1);
            delete Personalindex[msg.sender][PersonalRegistCount[msg.sender].sub(j)];
            
        }
        PersonalRegistCount[msg.sender] = PersonalRegistCount[msg.sender].sub(ticketCount);
        uint transferAmount;
        transferAmount = ticketCount.mul(Price);
        (msg.sender).transfer(transferAmount);
	}
	
	uint[] public ToAuctionArray;
	mapping (uint256 => address) public ToAuctionOwner;
	function TransferToAuction(uint256 TransferCount) public
	{
	    require(ownedTicketsCount[msg.sender]>=TransferCount,"Not enough Tickekt to transfer");
	    require(TransferCount>0);
	    
	    uint ownerIndex;
	    for(uint j=1; j<=TransferCount; j++)
        {
	        ownerIndex  =  PersonalTicketindex[msg.sender][ownedTicketsCount[msg.sender].sub(j)];
	        TicketOwner[ownerIndex] = address(0);
	        ownedTicketsCount[msg.sender].sub(1);
            delete PersonalTicketindex[msg.sender][ownedTicketsCount[msg.sender].sub(j)];
            ToAuctionArray.push(ownerIndex);
            ToAuctionOwner[ownerIndex] = msg.sender;
        }
        ownedTicketsCount[msg.sender] = ownedTicketsCount[msg.sender].sub(TransferCount);
	}

	struct Foo
	{
        uint TickeIndex;
        bool filled;
    }
	mapping (address => Foo[]) public personalBidsArray;
	
	struct Bid
	{
        uint BidAmount;
        //第幾次出價
        uint BidIndex;
        address bidder;
    }
    
    //list all bid
	Bid[] public BidsList;
	
	function Bids() public payable
	{
	 
	    require(msg.value >0);
	    
	    Foo memory foo;
	    foo.TickeIndex = msg.value;
	    foo.filled = false;
	    personalBidsArray[msg.sender].push(foo);
	    Bid memory bids;
	    bids.BidAmount = msg.value;
	    bids.bidder = msg.sender;
	    bids.BidIndex = personalBidsArray[msg.sender].length.sub(1);
	    BidsList.push(bids);
	    
	}   
	
	function CancelBid(uint256 CancelIndex) public 
	{
	 
	    require(personalBidsArray[msg.sender][CancelIndex].TickeIndex>0);
	    uint256 AmountTransfer = personalBidsArray[msg.sender][CancelIndex].TickeIndex;
	    personalBidsArray[msg.sender][CancelIndex].TickeIndex = 0;
	    (msg.sender).transfer(AmountTransfer);
	}
	
	Bid[] public ResultList;
	
	function AuctionGo() public onlyowner 
	{
	    uint CurrentHighest;
	    uint tempIndex;
	    for(uint i=0; i<ToAuctionArray.length; i++)
        {
            CurrentHighest = 0;
            //find the highest bid
            for(uint j=0; j<BidsList.length; j++)
            {
                if (BidsList[j].BidAmount>CurrentHighest)
                {
                    if (personalBidsArray[BidsList[j].bidder][BidsList[j].BidIndex].filled != true)
                    {
                        CurrentHighest = BidsList[j].BidAmount;
                        tempIndex = j;
                    }
                }
            }
            
             if (CurrentHighest>0)
             {
                 personalBidsArray[BidsList[tempIndex].bidder][BidsList[tempIndex].BidIndex].filled = true;
                 ResultList.push(BidsList[tempIndex]);
            
             }
             else
             {
                 break;
                 
             }
        }
        
	}  
	mapping (address => uint256) public Benefit;
	
    function Distribute() public onlyowner 
	{
	    uint lowest =  ResultList[ResultList.length-1].BidAmount;
        
       for(uint i=0; i<ResultList.length; i++)
        {
            TicketOwner[ToAuctionArray[i]] = ResultList[i].bidder;
            ownedTicketsCount[ResultList[i].bidder]++;
            uint currentHigh;
            currentHigh =  personalBidsArray[ResultList[i].bidder][ResultList[i].BidIndex].TickeIndex;
            personalBidsArray[ResultList[i].bidder][ResultList[i].BidIndex].TickeIndex = personalBidsArray[ResultList[i].bidder][ResultList[i].BidIndex].TickeIndex.sub(lowest).mul(95).div(100);
            Benefit[ToAuctionOwner[ToAuctionArray[i]]] = lowest;
        }
	}
	
	function Redeem() public  
	{
	    require(personalBidsArray[msg.sender].length>0);
	    uint TotalTransfer;
	    TotalTransfer = 0;
	    for(uint i=0; i<personalBidsArray[msg.sender].length;i++)
	    {
	        TotalTransfer = TotalTransfer + personalBidsArray[msg.sender][i].TickeIndex;
	        personalBidsArray[msg.sender][i].TickeIndex = 0;
	    }
	    TotalTransfer = TotalTransfer.add(Benefit[msg.sender]);
	    Benefit[msg.sender] = 0;
	    (msg.sender).transfer(TotalTransfer);
        
	}
	
	function Bidlength() view public returns (uint256) 
	{
	    return BidsList.length;
	}
}
