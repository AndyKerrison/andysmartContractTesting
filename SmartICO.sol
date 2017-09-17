pragma solidity ^0.4.16;

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}


//some sort of smart contract to hold & return eths
contract AKBuy{
    address public _owner;
 
    mapping (address => uint256) public _etherDeposits;
    mapping (address => uint256) public _tokensOwed;
    address[] public _addressArray;
    uint256 public _totalAddresses;
      
    address public _sale;
    uint256 public _saleStartTime;
    uint256 public _tokenTransferEnableTime;
    uint256 public _maxGwei;
    uint256 public _maxEth;
    ERC20 public _token;
    
    bool public _depositsLocked;
    bool public _tokensReceived;
    
    uint256 public _totalEthContributed;
    uint256 public _totalEthUnspent;
    uint256 public _totalTokenBalance;
    
    function AKBuy()
    {
        _owner= msg.sender;  
    }
    
    
    function getUserTokenBalance(address userAddress) constant returns(uint256) 
    {
        //if we don't have tokens, you don't have tokens
        if (!_tokensReceived || _totalTokenBalance == 0) return 0;
        
        uint256 ethContributed = _etherDeposits[userAddress];
        uint256 userTokens = _tokensOwed[userAddress];
        
        //if the tokensOwed hasn't been set, but we did make a contribution, do the calculation
        if (userTokens == 0 && ethContributed > 0)
        {
            userTokens = (ethContributed*_totalTokenBalance)/_totalEthContributed;
            
            //apply 1% fee
            userTokens = userTokens*99/100;            
        }
        
        return userTokens;
    }
    
    
    //set the sale address
    function setSaleAddress(address sale) {
        if (msg.sender != _owner)
            revert();
        
        _sale = sale;
    } 
    
    //set the token address
    function setTokenAddress(address token) {
        if (msg.sender != _owner)
            revert();
        
        _token = ERC20(token);
    } 
    
    function setTokenTransferEnableTime(uint256 tokenTransferEnableTime) {
        if (msg.sender != _owner)
            revert();
        
        _tokenTransferEnableTime = tokenTransferEnableTime;
    } 
    
    //set the start time
    function setSaleStartTime(uint256 saleStartTime) {
        if (msg.sender != _owner)
            revert();
        
        _saleStartTime = saleStartTime;
    } 
    
    function setMaxGwei(uint256 maxGwei) {
        if (msg.sender != _owner)
            revert();
        
        _maxGwei = maxGwei;
    }
    
    function setMaxEth(uint256 maxEth) {
        if (msg.sender != _owner)
            revert();
        
        _maxEth = maxEth * 1 ether;
    } 
    
    function setPurchaseFailed() {
        if (msg.sender != _owner)
            revert();
        
        setTokensReceived();
    } 
    
    
    //in case something goes wrong and we need to recover funds
    function emergencyEtherWithdraw() {
        if (msg.sender != _owner)
            revert();
        
        _owner.transfer(this.balance);
    }
    
    //in case something goes wrong and we need to recover funds
    function emerygencyTokenWithdraw(){
        if (msg.sender != _owner)
            revert();
            
        safeTokenTransferAll(_owner);
    } 
    
    //resets everything except the sale address and token
    function resetMe() {
        if (msg.sender != _owner)
            revert();
            
        _tokensReceived = false;
        _depositsLocked = false;
        
        _saleStartTime = 0;
        _maxGwei= 0;
        _maxEth = 0;
        _totalEthUnspent = 0;
        _totalTokenBalance = 0;
        _totalEthContributed = 0;
        
        //DANGER this may run out of gas or exceed block gas limit if there are enough addresses
        for (uint256 i = _totalAddresses; i > 0; i--) {
            address toClear = _addressArray[i-1];
            _etherDeposits[toClear] = 0;
            _tokensOwed[toClear] = 0;
        }
        
        //clear the array for next use
        _totalAddresses = 0;
        _addressArray.length = 0;
        
        //remove any remaining tokens
        safeTokenTransferAll(_owner);
        
        //send any balance back to owner
        if (this.balance > 0)
        {
            _owner.transfer(this.balance);
        }
    }
    
    
    function buyTokens() returns(uint)
    {
        //prerequisites. Return instead of throwing in order to save gas
        
        if (_saleStartTime == 0 || now < _saleStartTime) return 1; //must have a sale start time defined, and in the past
        
        if (_sale == 0x0) return 2; //must have a sale address
        
        if (_tokensReceived) return 3; //only retieve tokens once
        
        if (_maxGwei > 0 && msg.gas > (_maxGwei*1000000000)) return 4; //if we set a max gwei, then obey it
        
        //in the future we may split into multiple purchases
        //LockDeposits(); 
        _depositsLocked = true;
        
        uint256 ethToSpend;
        
        if (_maxEth > 0 && _totalEthUnspent > _maxEth)
        {
            ethToSpend = _maxEth;
        }
        else
        {
            ethToSpend = _totalEthUnspent;
        }
        
        //use call to forward gas
        require(_sale.call.value(ethToSpend)());
        
        setTokensReceived();
        return 0; //success code
    }
    
    
    
    //final system will lock in these values when either:
    //1)all ether on contract has been spent
    //2)crowdsale has finished (how to detect this?)
    function setTokensReceived() internal
    {
        _tokensReceived = true;
        _totalEthUnspent = this.balance;
        
        if (_token != ERC20(0x0))
        {
            _totalTokenBalance = _token.balanceOf(address(this));
        }
        else
        {
            _totalTokenBalance = 0;
        }
        
        _depositsLocked = false;
    }
    
    function depositEther() internal
    {
        require(!_depositsLocked && !_tokensReceived);
            
        _etherDeposits[msg.sender] += msg.value; //use SAFEADD?
        _addressArray.push(msg.sender);
        _totalAddresses++;
            
        _totalEthContributed = this.balance;
        _totalEthUnspent = this.balance;
    }
    
    function safeTokenTransfer(address target, uint256 value) internal returns(bool)
    {
        if (_token != ERC20(0x0) && now >= _tokenTransferEnableTime)
        {
            return _token.transfer(target,value);
        }
        return true;
    }
    
    function safeTokenTransferAll(address target) internal
    {
        if (_token != ERC20(0x0) && now >= _tokenTransferEnableTime)
        {
            uint256 allTokens = _token.balanceOf(address(this));
            _token.transfer(target, allTokens);
        }
    }
    
    function withdrawFunds() internal
    {
        require(!_depositsLocked);
                
                
        //how much eth the user put in
        uint256 ethContributed = _etherDeposits[msg.sender];
        
        //must set the tokens owed here, as the withdraw will clear the ethContributed by this user to 0
        uint256 userTokens = getUserTokenBalance(msg.sender);
        _tokensOwed[msg.sender] = userTokens;
        
        
        //return any ether
        if (ethContributed > 0)
        {
            _etherDeposits[msg.sender] = 0;
            
            //this simplifies to ethContributed if no eth was used, and nothing if it was all spent
            uint256 refund = (ethContributed*_totalEthUnspent)/_totalEthContributed;
            
            assert(refund <= this.balance);
            
            if (refund > 0)
            {
                msg.sender.transfer(refund);
            }    
        }
        
        //if tokens aren't done yet, update the total contribution balances
        if (!_tokensReceived)
        {
            _totalEthContributed = this.balance;
            _totalEthUnspent = this.balance;
        }
        
        //return any tokens
        if (_tokensReceived && now >= _tokenTransferEnableTime)
        {
            assert(userTokens <= _totalTokenBalance);
            
            if (userTokens > 0)
            {
				_tokensOwed[msg.sender] = 0;
                require(safeTokenTransfer(msg.sender, userTokens));    
            }
        }
    }
    
    //default function. Donate or retrieve ether, or trigger the purchase
    function() payable {
        if (msg.value > 1 finney)
        {
            depositEther();
        }
        else if (msg.value <= 1 finney)
        {
            //if we send a zero balance request after the sale start time but before success/fail, try to purchase
            if (_saleStartTime > 0 && now >= _saleStartTime && !_tokensReceived)
            {
                buyTokens();
            }
            else //otherwise, treat it as a withdraw request
            {
                withdrawFunds();
            }
        }
    }
    
}