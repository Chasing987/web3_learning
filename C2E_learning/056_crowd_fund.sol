// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 { // 定义了与代币交互的最基本的函数：transfer() 和 transferFrom()
    function transfer(address, uint256) external  returns (bool); // 直接从一个地址转账代币给另一个地址
    function transferFrom(address, address, uint256) external returns (bool); // 从一个地址（由授权人指定）转账代币给另一个地址，前提是授权过
}

/*
- 部署测试
- 账户1（deployer）: -> launch
- 账户2 -> pledge
- 账户3 -> pledge
*/
contract CrowdFund{
    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign{ // 保存每个众筹活动的状态信息（目标金额、认捐总额、时间等）
        address creator;  // 众筹发起人
        uint goal; // 目标金额（单位是代币数量，不是wei）
        uint pledged; // 当前已认捐总额
        uint32 startAt; // 众筹开始时间戳
        uint32 endAt; // 众筹结束事件戳
        bool claimed; // 是否已经提取资金
    }

    IERC20 public immutable token; // 用户指定的ERC20 代币合约地址
    uint public count; // 众筹活动计数器，用于分配唯一ID
    mapping (uint => Campaign) public campaigns; // 所有活动集合
    mapping (uint => mapping (address => uint)) public pledgedAmount; // 在每个活动中，每个用户对每个活动的认捐数量
    
    // 传入的是合法的ERC20 代币合约地址
    constructor(address _token){
        token = IERC20(_token);
    }

    /*
    - 发起众筹
    - 参数：目标筹集的代币数量、距离当前时间的启动延迟（秒）、距离当前时间的结束时间（秒），且不能超过30天
    */   
    function launch(uint _goal, uint32 _startOffset, uint32 _endOffset) external {
        require(_endOffset > _startOffset, "endAt <= startAt");
        require(_endOffset <= 30 days, "end > 30 days");

        uint32 _startAt = uint32(block.timestamp) + _startOffset;
        uint32 _endAt = uint32(block.timestamp) + _endOffset;

        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    /*
    - 取消众筹（发起人操作）
    - 功能：在众筹还未开始时，允许发起者取消该活动并删除数据
    */ 
    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "started");
        delete campaigns[_id];
        emit Cancel(_id);
    }

    /*
    - 认捐资金
    - 功能：用户授权合约自己从自己的地址转_mount 代币到众筹合约
    */ 
    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;

        token.transferFrom(msg.sender, address(this), _amount); // 从用户账户扣款到合约地址
        emit Pledge(_id, msg.sender, _amount);
    }

    /*
    - 撤回认捐
    - 功能：在活动未结束时，允许用户撤回自己认捐的部分代币
    */ 
    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    /*
    - 提取资金
    - 功能：在众筹结束后，如果认捐总额 >= 目标金额，发起人可以提取所有代币
    */
    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(campaign.claimed == false, "claimed");
        campaign.claimed = true;
        
        token.transfer(msg.sender, campaign.pledged); // 将全部pledge代币转账给创建者
        emit Claim(_id);
    }

    /*
    - 失败退款
    - 功能：在众筹失败（未达到目标）时，允许用户取回自己认捐的代币
    */
    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "pledged >= goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }
}