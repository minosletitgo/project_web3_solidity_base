#### EIP-712 被提出的原因

EIP-712 是以太坊一种结构化签名的方式。用户用私钥对一个未经过“结构化”的消息进行签名，是一串十六进制字节码，这种消息很难让签名人看懂，体验不好，而且会被一些作恶的应用或网站利用（例如让用户签一个操作把 token 授权给某个地址，然后资产就被盗取，而用户难以在签名时意识到）。例如下面这种签名，只能看懂地址和转账信息，但是 `Message` 中的字节码无法被人类读懂。

![eth_signData](https://eips.ethereum.org/assets/eip-712/eth_sign.png)

EIP-712 就是解决这种看不懂的情况，同时也提升用户体验，把消息结构化出来，告诉签名人要签的消息有哪些内容。

#### EIP-712 快速上手

EIP-712 结构化签名包含 3 个部分：

- `EIP712Domain`：保证离线签名只有在指定链的通过指定的合约（指定版本）才能被正确地通过验证。

    - `name`：签名域的用户可读名称，即 DApp 或 Protocol 的名称。
    - `version`：签名域的当前主要版本。不同版本的签名不兼容，这个一般取值为 `1`。
    - `chainId`：链 ID，用于验签时检查是否在签名者许可的那条区块链网络。
    - `verifyingContract`：验证签名的合约地址（例如，用户通过离线签名允许某合约使用自己 100 个 A token，验证签名的合约就是 A token 合约。

  举例如下：

  ```javascript
  const domain = {
        name: "Garen Test Safe Token",
        version: "1",
        chainId: "80001",		// e.g. Polygon Mumbai Testnet
        verifyingContract: "0x94B1424C3435757E611F27543eedB37bcD3BDEb4",
      };
  ```

- `types`：待被签名的数据的类型。根据业务逻辑的需要决定签署哪些字段或变量。如下的代码中，指定了签名中包含的 5 个数据，并分别指定数据类型。其中：

    - `nonce` 是防止重用签名的一个自增数，通过链上读取合约内的这个值（不需要发交易，静态调用即可），每当签名被验证通过（被使用掉了），这个值就会自增，以此达到防止一个离线签名被多次使用的问题，一般来说，这个字段是大多数离线签名所需的。

    - `deadline` 表示签名的有效期。

  ```JavaScript
  const types = {
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" }
        ],
      };
  ```

- `message`：待被签名的数据的值。应与 `types` 中指定的变量或字段一一对应，分别指定它们的值。

  ```JavaScript
  const message = {
        owner: owner,
        spender: spender,
        value: value,
        nonce: nonce,
        deadline: deadline,
      };
  ```

通过 Ethers.js 库可将这 3 个部分组装并通过浏览器中注入的钱包对象来让用户签名。用户即可在前端页面中看到例如如下面的签名界面：

![eth_signTypedData](https://github.com/GarenWoo/0124_MinimalProxy-ERC20Permit-ERC721Permit/raw/main/Task2_ERC2612AndERC721Permit/images/IMG2_SignMessage_ERC20Permit.png)

#### 使用 EIP-712 进行离线签名的示例代码

对于某个实现了 ERC2612（或 ERC20Permit，即合约中包含了验签方法）的 token，用户采用离线签名对某个地址进行授权一定的额度 `Value`，允许其作为 `Spender` 使用此用户的 token 。

点击访问[前端代码](https://github.com/GarenWoo/0119-0122_NFTMarketDapp/blob/main/src/App.tsx#L369-L435)，关键点解释如下：

```javascript
// 379 行：获取浏览器注入的钱包对象 `provider`
const provider = new ethers.BrowserProvider(window.ethereum)

// 380 行：从钱包对象 `provider` 获取 `signer`（这是一个包含私钥的对象，用于发起交易或者签名）
const signer = await provider.getSigner()

// 426 行：通过 `signer` 对信息（domain、types 和 message）进行签名
const signedMessage = await signer.signTypedData(domain, types, message);

// 428 行：使用签名信息生成 3 个参数 v, r, s（ESDCA 生成），用于后续的链上验签。
const signatureResult = ethers.Signature.from(signedMessage);
console.log("v: ", signatureResult.v);
console.log("r: ", signatureResult.r);
console.log("s: ", signatureResult.s);
```

[应用案例](https://github.com/GarenWoo/0124_MinimalProxy-ERC20Permit-ERC721Permit/blob/main/Task2_ERC2612AndERC721Permit/README.md#-1--%E7%A6%BB%E7%BA%BF%E7%AD%BE%E5%90%8D)
