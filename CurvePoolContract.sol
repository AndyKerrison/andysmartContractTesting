pragma solidity ^0.4.16;

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) constant public returns (uint256 balance);
}


//some sort of smart contract to hold & return eth
contract CurvePoolContract{
    address public _owner;
 
    mapping (address => uint256) public _etherDeposits;
    mapping (address => bool) public _isEthWithdrawn;
    mapping (address => bool) public _isTokensWithdrawn;
    
    address[] public _addressArray;
    uint256 public _totalAddresses;
      
    address public _sale;
    ERC20 public _token;
    
    bool public _depositsLocked;
    bool public _tokensReceived;
    bool public _contractOpen;
    bool public _pledgesEnabled;
    
    uint256 public _pledgesEndDate;
    
    uint256 public _transactionFee;
    
    uint256 public _totalEthContributed;
    uint256 public _totalEthUnspent;
    uint256 public _totalTokenBalance;
    
    function CurvePoolContract() public
    {
        _owner= msg.sender;  
    }
    
    modifier onlyOwner {
        require (msg.sender==_owner);
        _;
    }
    
    function getUserTokenBalance(address userAddress) constant public returns(uint256) 
    {
        //if we don't have tokens, you don't have tokens
        if (!_tokensReceived || _totalTokenBalance == 0) return 0;
        
        bool hasWithdrawn = _isTokensWithdrawn[userAddress];
        uint256 ethContributed = _etherDeposits[userAddress];
        
        if (hasWithdrawn || ethContributed == 0)
        {
            return 0;
        }
        
        return (ethContributed*_totalTokenBalance)/_totalEthContributed;
    }
    
    function getUserEtherBalance(address userAddress) constant public returns(uint256) 
    {
        bool hasWithdrawn = _isEthWithdrawn[userAddress];
        uint256 ethContributed = _etherDeposits[userAddress];
        
        if (hasWithdrawn || ethContributed == 0)
        {
            return 0;
        }
        
        return (ethContributed*_totalEthUnspent)/_totalEthContributed;
    }
       
    //set the sale address
    function setTransactionFee(uint256 transactionFee) public onlyOwner {
        if (transactionFee < 0)
            revert();
        
        _transactionFee = transactionFee;
    } 
    
    function setContractOpen() public onlyOwner {
        _contractOpen = true;
    } 
    
    function setDepositsLocked(bool locked) public onlyOwner {
        _depositsLocked = locked;
    }
    
    function setPledgesEnabled(bool locked) public onlyOwner {
        _pledgesEnabled = locked;
    } 
    
    function setPledgesEndDate(uint256 pledgesEndDate) public onlyOwner {
        _pledgesEndDate = pledgesEndDate;
    } 
    
    function setSaleAddress(address sale) public onlyOwner {
        _sale = sale;
    } 
    
    //set the token address
    function setTokenAddress(address token) public onlyOwner {
        _token = ERC20(token);
    } 
    
    //in case something goes wrong and we need to recover funds
    function emergencyEtherWithdraw() public onlyOwner {
        _owner.transfer(this.balance);
    }
    
    //in case something goes wrong and we need to recover funds
    function emerygencyTokenWithdraw() public onlyOwner {
        safeTokenTransferAll(_owner);
    } 
    
   
    function buyTokens() onlyOwner public returns(uint) {
        //prerequisites. Return instead of throwing in order to save gas
        if (_sale == 0x0) return 2; //must have a sale address
        
        if (_tokensReceived) return 3; //only retieve tokens once
        
        //in the future we may split into multiple purchases
        //LockDeposits(); 
        _depositsLocked = true;
        
        uint256 ethToSpend;
        
        //if (_maxEth > 0 && _totalEthUnspent > _maxEth)
        //{
        //    ethToSpend = _maxEth;
        //}
        //else
        //{
            ethToSpend = _totalEthUnspent;
        //}
        
        //calculate eth fees
		//transactionFee of 100 = 1%			
		uint256 ethFee = (ethToSpend * _transactionFee)/(100*100);
		
		ethToSpend -= ethFee;
		
		//withdraw operating fees
		_owner.transfer(ethFee);
        
        //use call to forward gas
        require(_sale.call.value(ethToSpend)());
                        
        //setTokensReceived();
        return 0; //success code
    }
    
    
    function setTokensReceived() public onlyOwner
    {
        _totalEthUnspent = this.balance;
        _tokensReceived = true;
        
        if (_token != ERC20(0x0))
        {
            _totalTokenBalance = _token.balanceOf(address(this));
        }
        else
        {
            _totalTokenBalance = 0;
        }
    }
    
    function setTokensAvailable() public onlyOwner
    {
        _depositsLocked = false;
    }
    
    function depositEther() internal
    {
        require(_contractOpen && !_depositsLocked && !_tokensReceived);
            
        _etherDeposits[msg.sender] += msg.value; //use SAFEADD?
        _addressArray.push(msg.sender);
        _totalAddresses++;
            
        _totalEthContributed = this.balance;
        _totalEthUnspent = this.balance;
    }
    
    function safeTokenTransfer(address target, uint256 value) internal returns(bool)
    {
        if (_token != ERC20(0x0))
        {
            return _token.transfer(target,value);
        }
        return true;
    }
    
    function safeTokenTransferAll(address target) internal
    {
        if (_token != ERC20(0x0))
        {
            uint256 allTokens = _token.balanceOf(address(this));
            _token.transfer(target, allTokens);
        }
    }
    
    //can only call this one before tokens have been purchased
    function withdrawEth(uint256 amount) public 
    {
        require(_contractOpen && !_tokensReceived && !_depositsLocked);
        
        //compare to how much eth the user put in
        uint256 ethContributed = _etherDeposits[msg.sender];
        
        require(amount <= ethContributed && amount > 0);
        assert(amount <= this.balance);
        
        _etherDeposits[msg.sender] -= amount;
        
        msg.sender.transfer(amount);
    }
    
    //withdraw all funds. Call only AFTER tokens are done
    function withdrawFunds() public 
    {
        require(_contractOpen && !_depositsLocked);
        
        uint256 ethOwed = getUserEtherBalance(msg.sender);
        uint256 userTokens = getUserTokenBalance(msg.sender);
        
        //return any ether
        if (ethOwed > 0)
        {
            _isEthWithdrawn[msg.sender] = true;
            
            assert(ethOwed <= this.balance);
            
            if (ethOwed > 0)
            {
                msg.sender.transfer(ethOwed);
            }    
        }
        
        //if tokens aren't done yet, update the total contribution balances
        if (!_tokensReceived)
        {
            _totalEthContributed = this.balance;
            _totalEthUnspent = this.balance;
        }
        
        //return any tokens
        if (_tokensReceived)
        {
            assert(userTokens <= _totalTokenBalance);
            
            if (userTokens > 0)
            {
				_isTokensWithdrawn[msg.sender] = true;
                require(safeTokenTransfer(msg.sender, userTokens));    
            }
        }
    }
    
    //default function. Donate ether.
    function() payable public {
        depositEther();
    }
    
}