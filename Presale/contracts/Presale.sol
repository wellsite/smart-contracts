pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';

contract Presale is Ownable {
	using SafeMath for uint;

	/**
	* Array of purchaser wallet addresses
	*/
	address[] public purchasers;

	/**
	* Map of purchasers to amount purchased
	*/
	mapping(address => uint) public balances;

	/**
	* Total purchased amount (in wei)
	*/
	uint public totalPurchased;

	/**
	* Maximum presale amount allotted
	* Set to 17000 ETH (in wei)
	*/
	uint public presaleMaximum = 42600 * (10 ** 18);

	/**
	* Minimum purchase amount
	* Set to 1.5 ETH (in wei)
	*/
	uint public minimumPurchase = 15 * (10 ** 17);

	/**
	* The ITO crowdsale contract
	*/
	Crowdsale public crowdsale;

	/**
	* Bool if presale has ended
	*/
	bool public ended;

	/**
	* Mapping to track purchasers pushed to crowdsale
	*/
	mapping(address => bool) public pushed;

	//Events
	event Purchased(address _purchaser, uint amount, bool existing, uint totalPurchasedAmount);
	event Pushed(address _purchaser, uint amount);
	event Refund(address _purchaser, uint amount);

	/**
	* Constructor
	*/
	function PresaleFunds() public {
		ended = false;
		totalPurchased = 0;
	}

	/**
	* Function to handle presale purchases
	*/
	function Purchase() public payable {
		require(!ended);
		require(msg.value >= minimumPurchase);

		address purchaser = msg.sender;

		bool existing = balances[purchaser] > 0;

		balances[purchaser] = balances[purchaser].add(msg.value);

		totalPurchased = totalPurchased.add(msg.value);

		if (existing == false) {
			purchasers.push(purchaser);
		}

		if (totalPurchased >= presaleMaximum) {
			ended = true;
		}

		Purchased(purchaser, msg.value, existing, totalPurchased);

	}

	/**
	* Function to push presale purchaser to ITO Crowdsale
	*
	* Needs to be public and non-onlyowner to be called internally and
	* also externally if necessary.  Multiple required checks to prevent abuse
	*
	* The presale must be ended to push purchasers
	*/
	function PushPurchaserToCrowdsale(address _purchaser) public {
		require(address(crowdsale) != 0x0);
		require(ended == true);
		require(pushed[_purchaser] != true);
		require(balances[_purchaser] > 0);

		uint amount = balances[_purchaser];

		// The final ITO Crowdsale *MUST HAVE* a buyTokens (payable) 
		// function which distributes the correct amount of tokens to
		// the presale purchasers
		crowdsale.buyTokens.value(amount)(_purchaser);

		pushed[_purchaser] = true;
		Pushed(_purchaser, amount);
	}

	/**
	* Function to push all purchasers to ITO
	*
	* If this loop hits a gas limit we will need to push all purhcasers
	* manually using PushPurchaserToCrowdsale
	*/
	function PushAllPurchasersToCrowdsale() public onlyOwner {
		require(address(crowdsale) != 0x0);
		require(ended == true);

		for(uint i = 0; i < purchasers.length; i++) {
			PushPurchaserToCrowdsale(purchasers[i]);
		}
	}

	/**
	* Set ITO Crowdsale contract
	*/
	function SetCrowdsale(address _crowdsale) public onlyOwner {
		crowdsale = Crowdsale(_crowdsale);
	}

	/**
	* End presale
	*/
	function EndPresale() public onlyOwner {
		ended = true;
	}

	/**
	* Open presale
	*/
	function OpenPresale() public onlyOwner {
		ended = false;
	}

	/**
	* Refund a purchaser
	*/
	function RefundPurchaser(address _purchaser) public onlyOwner {
		require(balances[_purchaser] > 0);
		require(pushed[_purchaser] != true);

		uint amount = balances[_purchaser];
		_purchaser.transfer(amount);

		balances[_purchaser] = 0;

		Refund(_purchaser, amount);
	}

	/**
	* Function to withdraw funds to owner
	*/
	function withdraw() external onlyOwner {
		owner.transfer(this.balance);
	}

	/**
	* Override function
	*/
	function() payable {
		Purchase();
	}

}
