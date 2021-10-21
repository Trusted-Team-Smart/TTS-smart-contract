// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./ITRC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./BaseTRC20.sol";

contract TTSToken is TRC20, Ownable {
    using SafeMath for uint256;
    
    ITRC20 public USDC_contract;

    uint256 public currentCoef = 100000; // /10000000


    event Sell(address indexed seller, uint256 TTSAmount, uint256 USDCAmount, uint256 price);
    event Buy(address indexed buyer, uint256 TTSAmount, uint256 USDCAmount, uint256 price);

    constructor(address mainWallet, address USDC) public {
        _mainWallet = mainWallet;
        USDC_contract = ITRC20(USDC);
    }
    
    //pays USDC gets TTS
    function buyToken(address _to, uint256 USDCAmount) public returns(uint256 TTSAmount,  uint256 price) {
        price = getSellPrice();
        if (currentCoef > 0)
            price = price.mul(10000000 + currentCoef).div(10000000);
        USDC_contract.transferFrom(msg.sender, address(this), USDCAmount);
        
        TTSAmount = USDCAmount.mul(1e24).div(price);

        if (TTSAmount > 0) {
            _mint(_to, TTSAmount);   
            emit Buy(_to, TTSAmount, USDCAmount, price);
        }
        return (TTSAmount, price);
    }

    function changeMainWallet(address mainWallet) public onlyOwner {
        require(mainWallet != address(0), "new mainWallet is the zero address");
        _mainWallet = mainWallet;
    }

    function setCoef(uint256 coef) public onlyOwner {
        require(coef <= 1000000);
        currentCoef = coef;
    }
    
    //pays TTS gets USDC
    function sellToken(address _to, uint256 amount) public returns(uint256 USDCAmount,  uint256 price) {
        price = getSellPrice();
        _burn(msg.sender, amount);
        USDCAmount = amount.mul(price).div(1e24);
        USDC_contract.transfer(_to, USDCAmount);

        emit Sell(_to, amount, USDCAmount, price);

        return (USDCAmount, price);
    }
    
    // decimals : 24
    function getSellPrice() public view returns(uint256 price) {
        uint256 balance = getUSDCBalance().mul(1e24);
        return balance.div(_totalSupply.sub(balanceOf(address(this))));
    }
 
    function getUSDCBalance() public view returns (uint256) {
        return USDC_contract.balanceOf(address(this));
    }

    
    function getBuyPrice() public view returns (uint256 price) {
        return getSellPrice().mul(10000000 + currentCoef).div(10000000);
    }
}