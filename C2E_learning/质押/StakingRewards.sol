// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract StackingRewards {
    IERC20 public immutable stakingToken; // 质押代币，用户用来质押的代币（比如 USDT）
    IERC20 public immutable rewardsToken; // 用户通过质押获得的奖励代币（比如项目 Token）
    address public owner; // 合约拥有者，可管理奖励发放等
    uint256 public duration; // 当前奖励发放周期的持续时间（秒）
    uint256 public finishAt; // 当前奖励周期的结束时间戳
    uint256 public updatedAt; // 上一次更新奖励参数的时间
    uint256 public rewardRate; // 每秒发放的奖励数量（单位：rewardsToken / 秒）
    uint256 public rewardPerTokenStored; //每个质押 token 所累积的奖励率（用于计算公式）

    mapping(address => uint256) public userRewardPerTokenPaid; // 	每个用户已领取的 rewardPerToken，防止重复计算
    mapping(address => uint256) public rewards; // 每个用户当前待领取的奖励总额

    uint256 public totalSupply; // 当前所有用户质押的代币总量
    mapping(address => uint256) public balanceOf; // 每个用户质押的代币数量

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    /*
    - 初始化时传入两种 ERC20 代币地址：
    - _stakingToken: 用户要质押的代币
    - _rewardsToken: 用户将获得的奖励代币
    - 设置合约部署者为 owner
    */
    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    /*
    - 设置奖励周期时长
    - 只有 owner 可调用
    - 必须在上一个奖励周期结束后（finishAt < now），才能设置新的奖励周期时长 duration
    - 注意：这里只是设置了 duration，​​并未启动新的奖励周期​
    */
    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    /*
    - 通知并初始化奖励金额
    - 作用是：
        - 合约 owner 存入一定数量的 rewardsToken奖励代币到本合约
        - 设置这些奖励将在 duration时间内线性释放给所有质押用户
    */
    function notifyRewardAmount(
        uint256 _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp > finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = rewardRate *
                (finishAt - block.timestamp);
            rewardRate = (remainingRewards + _amount) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    /*
    - 存入质押代币（stake）
    - 用户调用此函数，将自己账户中的 stakingToken代币转入合约
    - 要求 _amount > 0
    - 更新用户的 balanceOf和全局的 totalSupply
    - 通过 updateReward确保在质押前先结算已有奖励
    */
    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount == 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    /*
    - 提取质押代币（withdraw)
    - 用户可以提取自己已质押的代币
    - 要求 _amount > 0
    - 更新 balanceOf和 totalSupply
    - 将代币转回用户
    - 通过 updateReward确保先计算应得奖励
    */
    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount == 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    /*
    - 返回当前可用的奖励时间
    */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(block.timestamp, finishAt);
    }

    /*
    - 计算每 Token 的奖励率
    - 如果无人质押 (totalSupply == 0)，直接返回之前存储的值
    - 否则，计算从上次更新以来新增的奖励，并分摊到所有质押的 token 上：
    */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
                totalSupply;
    }

    /*
    - 查询用户已赚取的奖励
    - 用户赚取的奖励包括：
        - 根据其质押数量和 rewardPerToken()动态增长部分
        - 以及之前未领取的 rewards[_account]
    */
    function earned(address _account) public view returns (uint256) {
        return
            (balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) /
                1e18 +
            rewards[_account];
    }

    /*
    - 领取奖励
    */
    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    /*
    - 求最小值
    */
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
