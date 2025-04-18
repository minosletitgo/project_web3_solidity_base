#### 基本信息：
- 创建者：Hayden Adams
- 发布日期：2018年11月2日，部署在以太主网。
- 主要功能：自动做市商机制、只支持ETH和ERC-20代币之间的交易对、流动性池、工厂合约和交易对合约。
- 编写语言：Vyper。
- 源码地址：https://github.com/Uniswap/v1-contracts

　

#### 影响：
- Uniswap是一个基于以太坊的去中心化交易所协议。
- Uniswap V1 的发布不仅为用户提供了去中心化交易的新途径，还启发了许多其他去中心化交易所的创建，如 SushiSwap、Curve 和 Bancor 等。
- 尽管 V1 版本的功能相对有限，但它为后续版本的发展奠定了坚实的基础。

　

#### 相关故事：
- https://blog.uniswap.org/uniswap-history
- 2017年6月22日，Vitalik发表文章《On Path Independencen》。
- 2017年7月6日，Hayden Adams被西门子公司解雇，其朋友Karl Floersch劝说其关注以太坊，并学习智能合约的开发。
- 2018年11月2日，Uniswap V1部署到以太坊主网。
- 名字来源：由Vitalik提议，有独角兽单词(Unicorn)联想到。
![](../images/PixPin_20250418_162715.png "")

　

#### 核心合约：
- ```uniswap_factory.vy```
- ```uniswap_exchange.vy```

　

#### 一些关键点：
- 只允许创建 ETH 和 ERC20 代币之间的交易对。
- 每次用户进行swap交易的时候，会收取0.3%的手续费，完全分配给流动性提供者(即，平台方不会从交易手续费中直接获利)。
- 没有针对大额交易的滑点保护机制(或，补偿机制)。