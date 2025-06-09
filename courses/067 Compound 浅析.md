#### 借贷
- 传统领域的借贷：本质上是将房子、车、土地等非流动性资产作为抵押，借出钱这种能够高度流动的资产。
- ```DeFi```领域的借贷：抵押的资产和借出的资产，都属于高流动性的资产。
- ```DeFi```领域的借贷为什么吸引用户：```DeFi```借贷产品有着高额的抵押利率以及```DeFi```市场前期巨额的收益率吸引了较高的市场资金。
- 比如，```Compound```的流动性挖矿模式，用户就算借款也能得到挖矿的平台币奖励，这奖励扣减掉借款利息后净收益还是正的，所以才吸引了众多用户参与其中。
- ```Compound、Aave、Maker```是传统借贷协议的代表。

#### ```DeFi```借贷市场的需求
- 满足交易活动的资金需求：包括套利、杠杆、做市等交易活动（这是最主要的刚需）。
- 获得被动收入：主要满足那些长期持有数字资产又希望能够产生额外收益的投资者。
- 获得一定的流动性资金：主要是矿工或一些行业内的初创企业存在一些短期性流动资金的需求。

#### 金融常识
- 存款年利率（```Supply Annual Percentage Rate，APR```）：指一年内存款利息与本金的比率，是银行按照固定周期（通常为一年）计算利息的标准。
- 存款年利率，它是一个实际且稳定的数值(用于底层计算)，通常用于银行定期存款等固定收益产品中。
- 存款年化收益率（```Supply Annual Percentage Yield，APY```）：将某一投资在较短时间段内的收益率换算成一年期的理论收益率。
- 存款年化收益率，它是一种理论值(用于展示给用户观看)，假设投资收益率在整个年度内保持不变，但实际上可能会因市场波动而变化。
- 单利（```Simple Interest```）：仅以本金为基数计算利息，利息不会加入本金产生新的利息。
  - $利息和 = 本金 × (1 + 利率 * 期限)$
  - $利息 = 本金 × 利率 × 期限$
- 复利（Compound Interest）：不仅本金计息，往期产生的利息也会加入本金，在下一期一起计息，即 “利滚利”。
  - $利息和 = 本金 × (1 + 利率)^{期限}$
  - $利息 = 本金 × [(1 + 利率)^{期限} - 1]$
  - 这里的"期限"，指"利息计算的时间周期"，如"本金 10000 元，年利率 5%，存 3 年，按复利计算"，3 就是期限。

#### ```Compound```介绍功能
```
    名称 Compound：
        强调将各种资产汇集（词汇用意：复合，组合在一起）到一个资金池中进行借贷运作。
    
    支持的市场(Market，也就是链)：
        当前 Compound 只支持以太坊，和以太坊兼容链（Arbitrum, Optimism, Base, Polygon等，总共 17 条链）
        每一条链上的若干代币（如，以太坊的 USDT、USDC、WBTC等）
        
    资产存入：
        用户可以将资产存入 Compound 协议，存入资产的用户会收到相应的 cToken。
        这些 cToken 可以随时赎回为底层资产，赎回时会包括存款期间累计的利息。
        
    资产借出：
        用户可以使用他们存入的资产作为抵押，从 Compound 协议中借出其他资产。
        借款的利息是根据借贷市场的利率模型动态确定的。
        借款人必须维持足够的抵押品以避免清算。
        
    清算机制：
        如果借款人的抵押品价值下跌到一定比例（清算阈值）以下，清算人可以触发清算过程。
        在清算过程中，部分或全部抵押品将被出售给清算人，以偿还债务。
        
    去中心化治理：
        Compound 协议通过治理代币 COMP 实现去中心化治理。
        COMP 持有者可以提议、投票和执行对协议的更改，包括利率模型的调整、新资产的引入等。                   
```

#### ```Compound``` - 资金利用率
- 解释：表示资金池被借出的比例，直接影响"借款利率"与"存款利率"。
- ```TotalCash```：资金池中未借出的流动性资产。
- ```TotalBorrows```：已借出的资产总额。
- ```Reserves```：协议保留的储备金（从利息中抽取）。
- $UtilizationRate(资金利用率) = \frac{TotalBorrows}{TotalCash + TotalBorrows - Reserves}$
- 代码：```contracts/JumpRateModel.sol```
```
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns (uint) {
        if (borrows == 0) {
            return 0;
        }
        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }
```

#### ```Compound``` - 借款利率(```BorrowRate```)
- 解释："借款利率"通常采用"分段利率模型"。
- 借款人支付利息：按实时 ```BorrowRate``` 累积债务（每秒复利）。
- ```Kink```：代表"低利用率阶段"阈值。
- ```BaseRate```：最低基础利率（如 0%）。
- ```Multiplier_low```：低利用率时的利率敏感系数（如 10%）。
- ```Multiplier_high```：高利用率时的加速系数（如 50%）。
- 当 ```UtilizationRate ≤ Kink``` 时，代表"资金利用率过低"，"借款利率"会自动降低（鼓励"借款"），"存款利率"也会自动降低（抑制"存款"）。
- $BorrowRate(借款利率) = BaseRate + UtilizationRate × Multiplierlow$
- 当 ```UtilizationRate > Kink``` 时，利率跳跃式上升，代表"资金利用率过高"，"借款利率"会自动升高（抑制"借款"），"存款利率"也会自动升高（鼓励"存款"）。
- $BorrowRate(借款利率) = BaseRate + Kink × Multiplier_low + (UtilizationRate - Kink) × Multiplierhigh$
- 代码：```contracts/JumpRateModel.sol```
```
    function getBorrowRate(uint cash, uint borrows, uint reserves) public view returns (uint) {
        uint util = utilizationRate(cash, borrows, reserves);
        if (util <= kink) {
            return baseRatePerBlock.add(util.mul(multiplierPerBlock).div(1e18));
        } else {
            uint normalRate = baseRatePerBlock.add(kink.mul(multiplierPerBlock).div(1e18));
            uint excessUtil = util.sub(kink);
            return normalRate.add(excessUtil.mul(jumpMultiplierPerBlock).div(1e18));
        }
    }
    
    baseRatePerBlock：基础利率（按区块计算，非年化）。
    multiplierPerBlock：低利用率阶段的利率乘数（对应 Multiplier_low）。
    jumpMultiplierPerBlock：高利用率阶段的利率乘数（对应 Multiplier_high）。
    kink：资金利用率阈值（如 0.8e18 表示 80%）。
```

#### ```Compound``` - 存款利率(```SupplyRate```)
- 解释："存款利率"是"借款利率"的“派生值”（协议会截留一部分利息作为"储备金"）。
- ```ReserveFactor```：储备因子（如 10%），表示协议保留的利息比例，也称"储备金比例"。
- $SupplyRate(存款利率) = UtilizationRate × BorrowRate × (1 - ReserveFactor)$
- 代码：```contracts/CToken.sol```
```
    function supplyRatePerBlock() external view returns (uint) {
        uint borrowRate = getBorrowRatePerBlock();
        uint util = utilizationRate(
            getCashPrior(),
            totalBorrows,
            totalReserves
        );
        return util.mul(borrowRate).mul(1e18 - reserveFactorMantissa).div(1e36);
    }
    
    reserveFactorMantissa：储备因子（如 0.1e18 表示 10%）。
    1e36：精度调整（因 util 和 borrowRate 均为 1e18 精度）。
```

#### ```Compound``` - 汇率(也称为"兑换率")(```ExchangeRate```)
- 解释：1 个 ```cToken``` 可以兑换多少底层资产（例如：1 ```cDAI``` = 1.02 ```DAI```）。
- 存款时：用户存入 ```X```枚 底层资产，获得 ```X / exchangeRate``` 枚 ```cToken```。
- 取款时：用户用 ```Y``` 枚 ```cToken``` 兑换 ```Y * exchangeRate```枚 底层资产。
- ```TotalCash```：资金池中未借出的流动性资产。
- ```TotalBorrows```：已借出的资产总额。
- ```TotalReserve```：储备金。
- ```totalSupply```：```cToken``` 的总供应量（所有用户持有的 ```cToken``` 数量之和）。
- $ExchangeRate(汇率) = \frac{TotalCash + TotalBorrows − TotalReserve}{totalSupply}$
- 公式本质是 ```（池子总资产 - 储备金）/ cToken 总量```，确保 ```cToken``` 始终锚定底层资产的价值。
- 代码：```contracts/CToken.sol```
```
    function exchangeRateStoredInternal() internal view returns (uint) {
        uint _totalSupply = totalSupply; // cToken 总供应量
        if (_totalSupply == 0) {
            return initialExchangeRateMantissa; // 初始汇率（部署时设定）
        } else {
            uint totalCash = getCash(); // 资金池中未借出的底层资产
            uint totalBorrows = totalBorrowsCurrent(); // 已借出的资产（含利息）
            uint totalReserves = totalReserves; // 协议储备金
            uint totalSupplyPlusReserves = _totalSupply.add(totalReserves);
            
            // 汇率 = (总现金 + 总借款 - 总储备) / cToken总供应量
            return (totalCash.add(totalBorrows).sub(totalReserves)).mul(1e18).div(_totalSupply);
        }
    }
    
    totalSupply：cToken 的总供应量（所有用户持有的 cToken 数量之和）。
    getCash()：资金池中可立即提取的底层资产余额。
    totalBorrowsCurrent()：借款人未偿还的本金 + 累计利息。
    totalReserves：协议保留的储备金（从利息中抽取）。
    initialExchangeRateMantissa：初始汇率（如 1e18 表示 1 cToken = 1 底层资产）。
```

#### ```Compound``` - 抵押率(```Collateral Factor```)
- 解释：用户抵押的资产价值中可以用于借款的最大比例。
- 例如，ETH 的抵押率为 75%，则每抵押价值 100 USD 的 ETH，最多可借出 75 USD 的其他资产。
- $可借出金额 = 抵押数量 × 资产价格(来自预言机) × Collateral Factor$
- 设置：每种资产的抵押因子通过治理提案设置，体现治理权限。
- 示例：不同资产不同（如 ```ETH 75%，WBTC 70%```）
- 代码：```contracts/Comptroller.sol```
```
    function _setCollateralFactor(CToken cToken, uint256 newCollateralFactorMantissa) internal returns (uint) {
        // 检查新的抵押因子是否有效（不超过80%）
        if (newCollateralFactorMantissa > collateralFactorMaxMantissa) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }
        
        // 更新市场信息
        Market storage market = markets[address(cToken)];
        market.collateralFactorMantissa = newCollateralFactorMantissa;
        
        // 事件通知
        emit NewCollateralFactor(cToken, newCollateralFactorMantissa);
        
        return uint(Error.NO_ERROR);
    }
```

#### ```Compound``` - 健康因子(```Health Factor```)
- 解释：衡量用户的抵押资产价值与债务价值的安全边际。当 ```Health Factor < 1``` 时，触发清算。
- $Health Factor(健康因子) = \frac{抵押物总价值 × Collateral Factor}{债务总价值}$
- 抵押物总价值：所有抵押资产的价值总和。
- 债务总价值：所有借款资产的价值总和（按当前价格计算）。
- 代码：```contracts/Comptroller.sol```
```
    function getAccountLiquidity(address user) public view returns (uint, uint, uint) {
        uint totalCollateralValue;
        uint totalBorrowValue;
    
        // 计算抵押物总价值（乘以抵押率）
        for each (cToken in userCollaterals) {
            uint collateralFactor = markets[address(cToken)].collateralFactorMantissa;
            uint assetValue = cToken.balanceOf(user) * oracle.getPrice(cToken.underlying());
            totalCollateralValue += assetValue * collateralFactor / 1e18;
        }
    
        // 计算债务总价值
        for each (borrowedCToken in userBorrows) {
            uint debt = borrowedCToken.borrowBalanceStored(user);
            uint assetPrice = oracle.getPrice(borrowedCToken.underlying());
            totalBorrowValue += debt * assetPrice / 1e18;
        }
    
        // 健康因子 = totalCollateralValue / totalBorrowValue
        if (totalBorrowValue == 0) {
            return (0, 0, type(uint).max); // 无债务，健康因子无限大
        }
        uint healthFactor = totalCollateralValue * 1e18 / totalBorrowValue; // 精度 1e18
        return (0, 0, healthFactor);
    }
```

#### ```Compound``` - 清算(```Liquidate```)
- 解释：指当借款人的 健康因子（```Health Factor```）低于 1 时，其他用户（清算人）可以代为偿还部分债务，并以折扣价获取抵押品的过程。
- 参与者：```Compound``` 通过经济激励明确鼓励外部清算人参与。
  - 激励一：折价购买抵押品：清算人可以用借款代币（如 ```USDC```）按折扣价购买借款人的抵押品（如 ```ETH```），折扣比例通常为 ```8%~10%```（即 “清算奖励”）。
  - 激励二：获得 ```COMP``` 代币奖励：清算行为还可能额外获得协议发放的 ```COMP``` 治理代币，进一步提高清算人的收益。
  - 这种双激励机制使得清算成为有利可图的套利机会，吸引专业套利者和机器人持续监控市场(监控账单的"健康因子")，确保抵押不足的账户能被及时清算。
  - 也有可能发生极端情况，即"清算人不足，坏账风险上升，可能触发治理干预或协议损失。"
- 清算流程：```Comptroller.sol```（风险控制） + ```CToken.sol```（具体清算操作）
- 清算人调用 ```liquidateBorrow```
```
    function liquidateBorrow(
        address borrower,   // 被清算的借款人地址
        uint repayAmount,   // 清算人偿还的债务金额（底层资产单位）
        CToken cTokenCollateral  // 清算人想接收的抵押品对应的 cToken
    ) external payable {
        // 检查抵押品是否合法
        require(cTokenCollateral.comptroller == comptroller, "Comptroller mismatch");
    
        // 更新借款人和抵押品的利息（关键！）
        accrueInterest();
        cTokenCollateral.accrueInterest();
    
        // 调用 Comptroller 的 liquidateBorrowAllowed 进行风险检查
        uint err = comptroller.liquidateBorrowAllowed(
            address(this),
            cTokenCollateral,
            msg.sender,
            borrower,
            repayAmount
        );
        require(err == uint(Error.NO_ERROR), "Liquidation denied");
    
        // 执行清算逻辑
        liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
    }
```
- 风险检查（```Comptroller.sol```）
```
    function liquidateBorrowAllowed(
        address cTokenBorrowed,   // 被清算的债务资产（如 cUSDC）
        address cTokenCollateral, // 抵押品资产（如 cETH）
        address liquidator,
        address borrower,
        uint repayAmount
    ) external returns (uint) {
        // 检查市场是否已上线
        require(markets[cTokenBorrowed].isListed && markets[cTokenCollateral].isListed, "Market not listed");
    
        // 检查借款人当前的健康因子是否 < 1
        (uint err, , uint shortfall) = getAccountLiquidityInternal(borrower);
        require(err == uint(Error.NO_ERROR), "Liquidity calc failed");
        require(shortfall > 0, "Borrower not liquidatable"); // shortfall > 0 表示健康因子 < 1
    
        // 检查清算人偿还金额不超过债务的 50%
        uint borrowBalance = CToken(cTokenBorrowed).borrowBalanceStored(borrower);
        require(repayAmount <= borrowBalance * liquidationCloseFactorMantissa / 1e18, "Too much repay");
    
        return uint(Error.NO_ERROR);
    }
```
- 执行清算（```CToken.sol - liquidateBorrowFresh```）
```
    function liquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint repayAmount,
        CToken cTokenCollateral
    ) internal {
        // 1. 清算人将债务代币转给协议（如偿还 USDC）
        doTransferIn(liquidator, repayAmount); // 从清算人地址转移底层资产到合约
    
        // 2. 减少借款人的债务
        accountBorrows[borrower].principal -= repayAmount;
        totalBorrows -= repayAmount;
    
        // 3. 计算清算人可获得的抵押品数量（含折扣）
        uint seizeTokens = comptroller.liquidateCalculateSeizeTokens(
            address(this),
            address(cTokenCollateral),
            repayAmount
        );
    
        // 4. 将抵押品从借款人转给清算人（扣除协议保留的清算奖励）
        cTokenCollateral.seize(liquidator, borrower, seizeTokens);
    }
```
- 计算抵押品数量（```Comptroller.sol```）
```
    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount
    ) public view returns (uint) {
        // 获取两种资产的价格（通过预言机）
        uint priceBorrowed = oracle.getUnderlyingPrice(cTokenBorrowed); // 债务资产价格（如 USDC = 1e18）
        uint priceCollateral = oracle.getUnderlyingPrice(cTokenCollateral); // 抵押品价格（如 ETH = 2000e18）
    
        // 计算抵押品价值 = (偿还金额 × 债务价格 × 清算折扣) / 抵押品价格
        uint seizeTokens = repayAmount * priceBorrowed * liquidationIncentiveMantissa / priceCollateral;
    
        return seizeTokens;
    }
```

#### 界面显示利率相关
- 存款年化收益率（```Supply APY```），```APY```是复利后的实际收益，高于简单```APR```(单利)。
- 显示：在存款页面的资产列表中，每个可存款资产旁会显示当前的年化收益率（例如：```DAI 3.2%```）
  - $Supply APY = (1 + supplyRatePerBlock)^{blocksPerYear} - 1$
  - ```supplyRatePerBlock```：每区块存款利率。
  - ```blocksPerYear ```：按以太坊区块时间估算（约 2,102,400 个区块/年）。
- 借款年利率（```Borrow APR```）
- 显示：在借款页面或资产详情页中显示（例如：```ETH 借款利率 5.8%```）。
  - APR(单利)：$Borrow APR = borrowRatePerBlock × blocksPerYear$
  - ```borrowRatePerBlock```：每区块借款利率。
- 抵押率（```Collateral Factor```）
- 显示：例如：“ETH 抵押率 75%” → 抵押价值 100 ETH 最多可借 75 ETH 等值的其他资产。
- 健康因子（```Health Factor```）
- 实时计算抵押物价值与借款债务的比例，提示清算风险。
