// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256); // 返回代币的总供应量
    function balanceOf(address account) external view returns(uint256); // 返回指定地址的代币余额
    function transfer(address recipient, uint256 amount) external returns (bool); // 将代币从调用者地址转移到接收者地址
    function allowance(address owner, address spender) external view returns (uint256); // 返回spender地址被owner地址授权可以使用的owner代币数量
    function approve(address spender, uint256 amount) external returns (bool); // 允许spender地址使用调用者地址的指定数量的代币
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); // 从sender地址向recipient地址转移amount数量的代币，调用者必须有足够的allowance
}


/*
工作流程示例
初始状态：总质押量 = 1000，奖励指数 = 0

添加奖励：注入100个奖励代币，奖励指数变为 (100 × 1e18) / 1000 = 0.1 × 1e18

用户质押：用户A质押100代币，获得100份额

计算奖励：用户A的奖励 = 100 × (0.1e18 - 0) / 1e18 = 10 个奖励代币

这个合约的核心优势是 gas 效率高，只在必要的时候更新用户奖励状态。
*/

contract DiscreteStakingRewards{
    // 代币接口
    IERC20 public immutable stakingToken; // 质押代币
    IERC20 public immutable rewardToken; // 奖励代币

    // 用户质押数据
    mapping (address => uint) public balanceOf; // 用户质押余额
    uint public totalSupply; // 总质押量

    // 奖励计算相关
    uint private constant MULTIPLIER = 1e18;  // 奖励计算精度
    uint private rewardIndex; // 全局奖励指数
    mapping (address => uint) private rewardIndexOf; // 用户上次的奖励指数
    mapping (address => uint) private earned; // 用户已累积但未领取的奖励

    constructor(address _stakingToken, address _rewarToken){
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewarToken);
    }

    /*
    - 奖励指数机制
    - 功能：由外部调用者（通常是管理员或奖励分发者）调用，用于增加奖励池中的奖励并更新全局奖励指数。
    - 流程：
        - 从调用者转移指定数量的奖励代币到合约
        - 根据新增的奖励和当前总质押量更新全局奖励指数
    */
    function updateRewardIndex(uint reward) external {
        rewardToken.transferFrom(msg.sender, address(this), reward);
        rewardIndex += (reward * MULTIPLIER) / totalSupply;
    }

    /*
    - 功能：计算指定地址根据其质押份额应得的奖励（不改变状态）
    - 奖励 = 质押数量 × (当前奖励指数 - 用户上次记录的奖励指数) / 精度乘数
    */
    function _calculateRewards(address account) private view returns(uint){
        uint shares = balanceOf[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / MULTIPLIER;
    }

    /*
    - 功能​​：查看指定地址已赚取但可能未领取的总奖励（包括已记录的和根据最新指数计算的）
    */
    function calculateRewardsEarned(address account) external view returns(uint){
        return earned[account] + _calculateRewards(account);
    }

    /*
    - 更新用户奖励
    - ​​功能​​：更新指定地址的已赚取奖励和奖励指数记录（改变状态）
    - 流程​​：
        - 将根据最新指数计算的奖励添加到已赚取奖励中
        - 更新用户记录的奖励指数为当前全局奖励指数
    */
    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }

    /*
    - 功能​​：用户质押代币到合约
    - 流程​​：
        - 计算并更新用户当前应得奖励
        - 增加用户的质押余额和总质押量
        - 从用户地址转移指定数量的代币到合约
    */
    function stake(uint amount) external {
        _calculateRewards(msg.sender);
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    /*
    - 功能​​：用户从合约提取质押的代币
    - ​​流程​​：
        - 更新用户的奖励记录（将应得奖励加入earned）
        - 减少用户的质押余额和总质押量
        - 将指定数量的代币返还给用户
    */
    function unstake(uint amount) external {
        _updateRewards(msg.sender);
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        stakingToken.transfer(msg.sender, amount);
    }

    /*
    - 领取奖励
    - ​​功能​​：用户领取已赚取的奖励代币
    ​​流程​​：
    更新用户的奖励记录
    获取用户当前应得的奖励
    如果有奖励，则将奖励转移到用户地址，并将earned置零
    返回领取的奖励数量

    */
    function claim() external returns(uint){
        _updateRewards(msg.sender);
        uint reward = earned[msg.sender];

        if(reward > 0){
            earned[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
        }

        return reward;
    }
}