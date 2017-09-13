pragma solidity ^0.4.13;

contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract KyberDummyCrowdSale
{
    ERC20 public _token;
    
    mapping(bytes32=>uint) public proxyPurchases;
    
    function KyberDummyCrowdSale(address token)
    {
        _token = ERC20(token);
    }
    
    event ProxyBuy( bytes32 indexed _proxy, address _recipient, uint _amountInWei );
    function proxyBuy( bytes32 proxy, address recipient ) payable returns(uint){
        uint amount = buy( recipient );
        
        //proxyPurchases[proxy] = proxyPurchases[proxy].add(amount);
        uint256 c = proxyPurchases[proxy] + amount;
        assert(c >= amount);
        proxyPurchases[proxy] = c;
        
        ProxyBuy( proxy, recipient, amount );

        return amount;
    }
    
    
    function buy( address recipient ) payable returns(uint){
        uint256 tokenCount = _token.balanceOf(address(this));
        
        //1 eth = 200 tokens
        uint256 allowance = (msg.value * 20000)/(1 ether);
        require(tokenCount > allowance);
        _token.transfer(recipient, allowance);
        return 2000;
    }
    
    function() payable
    {
        //someone sent eth, give them some tokens
        uint256 tokenCount = _token.balanceOf(address(this));
                
        //1 eth = 100 tokens
        uint256 allowance = (msg.value * 10000)/(1 ether);
        require(tokenCount > allowance);
        _token.transfer(msg.sender, allowance);
    }
}