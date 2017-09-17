pragma solidity ^0.4.13;

contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract AKSale
{
    ERC20 public _token;
        
    function AKSale(address token)
    {
        _token = ERC20(token);
    }
           
    function() payable
    {
        //someone sent eth, give them some tokens
        uint256 tokenCount = _token.balanceOf(address(this));
                
        //1 eth = 100 tokens (+2dp)
        uint256 allowance = (msg.value * 10000)/(1 ether);
        require(tokenCount > allowance);
        _token.transfer(msg.sender, allowance);
    }
}