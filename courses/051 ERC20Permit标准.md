#### 理解概念：
- ERC20Permit标准 是 ERC20 标准的一个扩展，旨在优化代币授权流程，减少用户的 gas 费用，并提高用户体验。
- ERC20Permit标准，是通过EIP-2612提案引入的。
- 在ERC20标准下，用户"授权"-"授权转账逻辑"，这个过程会经历2次链上交互；
- 在ERC20Permit标准下，用户"签名授权 + 转账逻辑"，这个过程只会经历1次链上交互；

　

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