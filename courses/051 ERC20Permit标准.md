#### 理解概念：
- ERC20Permit标准 是 ERC20 标准的一个扩展，旨在优化代币授权流程，减少用户的 gas 费用，并提高用户体验。
- ERC20Permit标准，是通过EIP-2612提案引入的。
- 在ERC20标准下，用户"授权"-"授权转账逻辑"，这个过程会经历2次链上交互；
- 在ERC20Permit标准下，用户"签名授权 + 转账逻辑"，这个过程只会经历1次链上交互；
- ERC20Permit标准 也俗称 ERC2612标准。

　

##### ERC20标准示例：
- 1.用户向链上发起调用```ERC20Token.approve```，gas费消耗一次(21000 + X + Y + ...)
- 2.用户向链上发起调用```ThirdPartyContract.transferFromUser```，gas费消耗一次(21000 + X + Y + ...)
```
// ERC20 合约实现部分
pragma solidity ^0.8.0;

contract ERC20Token {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "Insufficient allowance");
        allowance[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        return true;
    }
}

// 第三方调用方合约
contract ThirdPartyContract {
    ERC20Token public token;

    constructor(address tokenAddress) {
        token = ERC20Token(tokenAddress);
    }

    function transferFromUser(address user, uint256 amount) external {
        token.transferFrom(user, address(this), amount); // 执行转账
    }
}

```

　

##### ERC20Permit标准示例：
- 1.用户在本地离线生成签名 (v, r, s)，不产生链上交易和 gas 费，这个过程是线下(前端)与钱包(如，MetaMask)交互，进而生成签名数据(包含deadline与nonce，能够预防重入与保持时效)。
- 2.用户持有签名数据，向链上发起调用```ThirdPartyContract.transferWithPermit```，gas费消耗一次(21000 + X + Y + ...)
```
// ERC20-Permit 合约实现部分
pragma solidity ^0.8.0;

contract ERC20PermitToken {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("ERC20PermitToken")),
            keccak256(bytes("1")),
            chainId,
            address(this)
        ));
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        ));

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Permit: invalid signature");

        allowance[owner][spender] = value;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "Insufficient allowance");
        allowance[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        return true;
    }
}

// 第三方调用方合约
contract ThirdPartyContract {
    ERC20PermitToken public token;

    constructor(address tokenAddress) {
        token = ERC20PermitToken(tokenAddress);
    }

    function transferWithPermit(
        address owner,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        token.permit(owner, address(this), amount, deadline, v, r, s); // 使用 permit 进行链上验证
        token.transferFrom(owner, address(this), amount); // 执行转账
    }
}
```

##### 使用```Foundry```的脚本模块，模拟链下生成```r、s、v```
- 合约名称，略有出入。
```
    function testPermitAndSpend() public {
        // 准备 permit 数据
        address spenderAddress = address(spender);
        uint256 amount = 100 * 1e18; // 尝试授权 100 个
        assertGe(
            token.balanceOf(owner),
            amount,
            "balanceOf Owner Is Not Enough !"
        );

        console.log("owner balanceOf = ", token.balanceOf(owner) / 1e18);
        console.log(
            "spender balanceOf = ",
            token.balanceOf(address(spender)) / 1e18
        );

        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        // 构造 EIP-712 消息
        bytes32 permitTypehash = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
        bytes32 structHash = keccak256(
            abi.encode(
                permitTypehash,
                owner,
                spenderAddress,
                amount,
                nonce,
                deadline
            )
        );

        console.log("step ...........1");

        // 获取 DOMAIN_SEPARATOR
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        console.log("step ...........2");

        // 链下签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        console.log("step ...........3");

        // 验证签名
        address recoveredSigner = ECDSA.recover(digest, v, r, s);
        assertEq(recoveredSigner, owner, "Invalid signature");

        console.log("step ...........4");

        // 调用 SpenderContract 的 spendWithPermit
        vm.prank(address(this)); // 模拟第三方调用
        spender.spendWithPermit(
            owner,
            spenderAddress,
            amount,
            deadline,
            v,
            r,
            s
        );

        console.log("step ...........5");

        // 验证授权和转移
        assertEq(
            token.allowance(owner, spenderAddress),
            0,
            "Allowance should be consumed"
        );

        console.log("owner balanceOf = ", token.balanceOf(owner) / 1e18);
        console.log(
            "spender balanceOf = ",
            token.balanceOf(address(spender)) / 1e18
        );

        vm.stopPrank();

        console.log("step ...........6");
    }
```

　

##### 以下贴出OpenZepplin所维护的```IERC20Permit.sol```与```ERC20Permit.sol```
```
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;
interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
```
```
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.20;

import {IERC20Permit} from "./IERC20Permit.sol";
import {ERC20} from "../ERC20.sol";
import {ECDSA} from "../../../utils/cryptography/ECDSA.sol";
import {EIP712} from "../../../utils/cryptography/EIP712.sol";
import {Nonces} from "../../../utils/Nonces.sol";

abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712, Nonces {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    error ERC2612ExpiredSignature(uint256 deadline);

    error ERC2612InvalidSigner(address signer, address owner);

    constructor(string memory name) EIP712(name, "1") {}

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}
```

　

##### 其他说明：
- ```permit```函数机制的存在，不仅保证了用户授权额度(即使交给第三方合约来执行)的安全性，还通过 ```gasless``` 操作提升了用户体验。
- ```nonce```值：在链下时需要向合约交互一次，才能获取得到(gas费用几乎为0，因为是只读view)，这样才符合链下与链上的签名解析一致。

##### 从小白码代码的层面，粗暴看```permit```逻辑
```
    // 如果 permit 函数，被阉割成下面的形式。
    // 那么，上一层第三方合约，将可以胡乱随意的操控用户的授权额度。
    function permit(
        address owner,
        address spender,
        uint256 value
    ) public virtual {
        _approve(owner, spender, value);
    }
```
 
