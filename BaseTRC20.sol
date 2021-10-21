// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./ITRC20.sol";
import "./SafeMath.sol";

/**
Contract function to receive approval and execute function in one call
*/
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}


abstract contract TRC20 is ITRC20{
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    address internal _mainWallet;
    
    // ------------------------------------------------------------------------
    // Constructor
    // initSupply = 10TTS
    // ------------------------------------------------------------------------
    constructor() internal {
        symbol = "TTS";
        name = "Trusted Team Smart";
        decimals = 6;
        _totalSupply = 10 * 10**6;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender, 
            _allowances[msg.sender][spender].sub(subtractedValue,
            "TRC20: decreased allowance below zero")
        );
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        ApproveAndCallFallBack spender = ApproveAndCallFallBack(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address recipent, uint256 amount) internal {
        uint256 fee = amount.div(100);
            
        _balances[_mainWallet] = _balances[_mainWallet].add(fee);
        _balances[recipent] = _balances[recipent].add(amount);
        _totalSupply = _totalSupply.add(amount.add(fee));
        emit Transfer(address(0), _mainWallet, fee);
        emit Transfer(address(0), recipent, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _burn(address sender, uint256 amount) internal {
        require(sender != address(0), "TRC20: burn from the zero address");

        _balances[sender] = _balances[sender].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(sender, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


