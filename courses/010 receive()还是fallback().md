

```                       
                       接收ETH
                         |
                   msg.data是空？
                      /      \
                     /        \
       transfer(value)       call{value: value}(data)，且data指向的函数不存在
           send(value)          \
   call{value: value}()          \
                 /                \
                是                 否
               /                    \
         receive()存在?             fallback()
             / \
            是  否
           /     \
    receive()   fallback()
```    


#### 目标合约接收以太币的说明(建议打开代码查看：contracts/TestFallback.sol):
- ```TryCallTarget_0```：发送以太币（0或者大于0，都一样） + 指定函数签名为空(等价于msg.data为空) = 返回值true + 只会触发receive
- ```TryCallTarget_1```：发送以太币（0或者大于0，都一样） + 指定已存在函数的签名(等价于msg.data不为空) = 返回值true + 不会触发receive，也不会触发fallback(最为特殊的一条!)
- ```TryCallTarget_2```：发送以太币（0或者大于0，都一样） + 指定不存在函数的签名(等价于msg.data不为空) = 返回值true + 只会触发fallback
- ```TryCallTarget_3```：发送以太币（0或者大于0，都一样） + 不指定函数的签名(等价于msg.data为空) = 返回值true + 只会触发receive


#### 代理合约模式中：
- 把"代理合约的地址"，放入"At address"(Load contract from address)，加载出一个逻辑合约。
- 此时，该逻辑合约，它的原始数据来源是代理合约。
- 此时，调用该逻辑合约的业务函数(该函数在代理合约中并未定义)，则会触发代理合约中的fallback函数