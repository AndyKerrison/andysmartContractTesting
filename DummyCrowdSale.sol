pragma solidity ^0.4.16;

contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract DummyCrowdSale
{
    ERC20 public _token;
    
    mapping(bytes32=>uint) public proxyPurchases;
    
    function DummyCrowdSale(address token)
    {
        _token = ERC20(token);
    }
    
    function proxyBuy(address recipient ) payable returns(uint){
        //uint amount = buy( recipient );
        //proxyPurchases[proxy] = proxyPurchases[proxy].add(2000);
        //ProxyBuy( proxy, recipient, amount );
        
        uint256 tokenCount = _token.balanceOf(address(this));
        require(tokenCount > 2000);
        _token.transfer(recipient, 2000);
        return 2000;
    }
    
    function() payable
    {
        //someone sent eth, give them some tokens
        uint256 tokenCount = _token.balanceOf(address(this));
        require(tokenCount > 1000);
        _token.transfer(msg.sender, 1000);
    }
}