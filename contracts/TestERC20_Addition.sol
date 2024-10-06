// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Receiver {
    function onERC20Received(address from, uint256 value, bytes calldata data) external returns (bytes4);
}

contract ERC20 is IERC20 {
    string private _name;
    string private _symbol;
    uint8 constant private _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name, string memory symbol, uint256 initSupply) {
        _name = name;
        _symbol = symbol;
        _totalSupply = initSupply * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        require(account != address(0), "ERC20: balance query for the zero address");
        return _balances[account];
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[msg.sender] >= value, "ERC20: transfer amount exceeds balance");

        // Checks-Effects-Interactions pattern
        _balances[msg.sender] -= value; // Effects
        _balances[to] += value; // Effects

        emit Transfer(msg.sender, to, value); // Interactions

        // Call the receiver contract if `to` is a contract
        if (isContract(to)) {
            bytes memory data;
            require(
                IERC20Receiver(to).onERC20Received(msg.sender, value, data) == IERC20Receiver(to).onERC20Received.selector,
                "ERC20: transfer to non ERC20Receiver implementer"
            );
        }

        return true;
    }   

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= value, "ERC20: transfer amount exceeds balance");
        require(_allowances[from][msg.sender] >= value, "ERC20: transfer amount exceeds allowance");

        // Checks-Effects-Interactions pattern
        _balances[from] -= value; // Effects
        _balances[to] += value; // Effects
        _allowances[from][msg.sender] -= value; // Effects

        emit Transfer(from, to, value); // Interactions

        // Call the receiver contract if `to` is a contract
        if (isContract(to)) {
            bytes memory data;
            require(
                IERC20Receiver(to).onERC20Received(from, value, data) == IERC20Receiver(to).onERC20Received.selector,
                "ERC20: transfer to non ERC20Receiver implementer"
            );
        }

        return true;
    }
    
    function approve(address spender, uint256 value) external override returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        // Remove balance check to comply with ERC20 standard
        _allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }   

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
