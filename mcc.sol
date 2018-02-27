pragma solidity ^0.4.11;

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
interface ERC20Interface {
    // Get the total token supply
    function totalSupply() constant returns (uint256 _totalSupply);
    
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);
    
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);
    
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns (bool success);
    
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MiscCryptoCoin is ERC20Interface {
	uint256 _totalSupply = 100000000; //actually just one million, due to decimals

	string public constant symbol = "MCC";
	string public constant name = "Misc Crypto Coin v3";
	uint8 public constant decimals = 2;
	uint256 public _transferEnableTime;
	
	address public owner;
	address public _saleContractAddress;
	
	mapping(address=>uint256) balances;
	
	mapping(address=>mapping(address=>uint256)) allowed;
	
	function MiscCryptoCoin() {
	    owner = msg.sender;
	    balances[owner] = _totalSupply;
	}
	
	function setTransferEnableTime(uint256 transferEnableTime)
	{
		require(owner == msg.sender);
		_transferEnableTime = transferEnableTime;
	}
	
	function setSaleContractAddress(address saleContractAddress)
	{
		require(owner == msg.sender);
		_saleContractAddress = saleContractAddress;
	}
	
	// Get the total token supply
	function totalSupply() constant returns(uint256 balance){
	    return _totalSupply;
	}
	
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }
    
    modifier onlyWhenAllowed() {
        if( now < _transferEnableTime) {
            require( msg.sender == _saleContractAddress || msg.sender == owner );
        }
        _;
    }
    
    // Send _value amount of tokens to address _to
    function transfer(address to, uint256 value) onlyWhenAllowed returns (bool success){
        if (balances[msg.sender] >= value
            && value > 0
            && balances[to] + value > balances[to]){
                balances[msg.sender] -= value;
                balances[to] += value;
                Transfer(msg.sender, to, value);
                return true;
        }
        else{
            return false;
        }
    }
    
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) onlyWhenAllowed returns (bool success){
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(_from, _to, _value);
                return true;
        } else {
            return false;
        }
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}