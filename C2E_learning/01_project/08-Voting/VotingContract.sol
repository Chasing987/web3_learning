// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract Create {
    using Counters for Counters.Counter; // 使用 OpenZeppelin 的 Counters 库来维护自增 ID

    Counters.Counter public _voterId; // 投票者 ID 计数器
    Counters.Counter public _candidateId; // 候选人 ID 计数器

    address public votingOrganizer; // 投票组织者（部署合约的地址），在构造函数中设为 msg.sender

    // 候选人（Candidate）
    struct Candidate {
        uint256 candidateId; // 候选人 ID（由 _candidateId 自增生成）
        string age; // 候选人年龄（以字符串存储）
        string name; // 候选人姓名
        string image; // 候选人图片（可能是 URL 或 IPFS hash）
        uint256 voteCount; // 当前票数
        address _address; // 候选人的区块链地址（作为主键）
        string ipfs; // 与候选人相关的 IPFS 数据地址
    }

    // 事件：在新候选人被创建时触发，包含候选人全部字段，candidateId 被 indexed 以便于查询
    event CandidateCreate(
        uint256 candidateId,
        string age,
        string name,
        string image,
        uint256 voteCount,
        address _address,
        string ipfs
    );

    address[] public candidateAddress; // 保存候选人地址的数组（用于遍历/列出所有候选人）
    mapping(address => Candidate) public candidates; // 通过地址索引候选人数据


    address[] public votedVoters; // 保存所有被授权投票者的地址
    address[] public votersAddress; //保存已经实际投票的地址列表

    mapping(address => Voter) public voters; // 通过地址索引投票者数据

    // 投票者（Voter）
    struct Voter {
        uint256 voter_voterId; // 投票者 ID（由 _voterId 自增）
        string voter_name; // 投票者姓名
        string voter_image; // 投票者图片（URL 或 IPFS）
        address voter_address; // 投票者地址（冗余存储，等于 mapping 的 key）
        uint256 voter_allowed; // 是否被授权投票（源码使用 0/1 表示未授权/已授权）
        bool voter_voted; // 是否已投票
        uint256 voter_vote; // 已投票的候选人 ID（源码中未直接存候选人地址，而存候选人 ID）
        string voter_ipfs; // 投票者的 IPFS 关联数据
    }

    // 事件：在投票者被授权时触发，包含投票者全部字段，voter_voterId 被 indexed。
    event VoterCreated(
        uint256 indexed vote_voterId,
        string voter_name,
        string voter_image,
        address voter_address,
        uint256 voter_allowed,
        bool voter_voted,
        uint256 voter_vote,
        string voter_ipfs
    );

    constructor() {
        votingOrganizer = msg.sender;
    }

    // 为给定地址创建或者更新一个candidate
    function setCandidate(
        address _address,
        string memory _age,
        string memory _name,
        string memory _image,
        string memory _ipfs
    ) public {
        require(
            votingOrganizer == msg.sender,
            "you have no organizer to set Candidate"
        );

        _candidateId.increment();

        uint256 idNumber = _candidateId.current();

        Candidate storage candidate = candidates[_address];

        candidate.age = _age;
        candidate.name = _name;
        candidate.candidateId = idNumber;
        candidate.image = _image;
        candidate.voteCount = 0;
        candidate._address = _address;
        candidate.ipfs = _ipfs;

        candidateAddress.push(_address);

        emit CandidateCreate(
            candidate.candidateId,
            _age,
            _name,
            _image,
            candidate.voteCount,
            candidate._address,
            candidate.ipfs
        );
    }

    // 获取候选人地址
    function getCandidate() public view returns (address[] memory) {
        return candidateAddress;
    }

    // 获取获选人的个数
    function getCandidateLength() public view returns (uint256) {
        return candidateAddress.length;
    }

    // 获取获选人的数据
    function getCandidate(
        address _address
    )
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            string memory,
            uint256,
            string memory,
            address
        )
    {
        return (
            candidates[_address].age,
            candidates[_address].name,
            candidates[_address].candidateId,
            candidates[_address].image,
            candidates[_address].voteCount,
            candidates[_address].ipfs,
            candidates[_address]._address
        );
    }

    // 为指定地址授权成为投票者
    function voterRight(
        address _address,
        string memory _name,
        string memory _image,
        string memory _ipfs
    ) public {
        require(
            votingOrganizer == msg.sender,
            "you have no right to provide authorization for vote"
        );

        _voterId.increment();

        uint256 idNumber = _voterId.current();
        Voter storage voter = voters[_address];

        require(voter.voter_allowed == 0);

        voter.voter_allowed = 1;
        voter.voter_name = _name;
        voter.voter_image = _image;
        voter.voter_address = _address;
        voter.voter_voterId = idNumber;
        voter.voter_vote = 1000;
        voter.voter_voted = false;
        voter.voter_ipfs = _ipfs;

        votersAddress.push(_address);

        emit VoterCreated(
            voter.voter_voterId,
            _name,
            _image,
            _address,
            voter.voter_allowed,
            voter.voter_voted,
            voter.voter_vote,
            voter.voter_ipfs
        );
    }

    // 执行投票
    function vote(
        address _candidateAddress,
        uint256 _candidateVoteId
    ) external {
        Voter storage voter = voters[msg.sender];

        require(!voter.voter_voted, "you have already voted");
        require(voter.voter_allowed != 0, "you have no right to vote");

        voter.voter_voted = true;
        voter.voter_vote = _candidateVoteId;

        votedVoters.push(msg.sender);
        candidates[_candidateAddress].voteCount += voter.voter_allowed;
    }

    // 返回被授权的投票者数量
    function getVoterLength() public view returns (uint256) {
        return votersAddress.length;
    }

    // 返回投票者的详细字段
    function getVoterData(
        address _address
    )
    public
    view
    returns (
        uint256,
        string memory,
        string memory,
        address,
        string memory,
        uint256,
        bool
    )
    {
        return (
            voters[_address].voter_voterId,
            voters[_address].voter_name,
            voters[_address].voter_image,
            voters[_address].voter_address,
            voters[_address].voter_ipfs,
            voters[_address].voter_allowed,
            voters[_address].voter_voted
        );
    }

    // 返回已经投票的地址列表
    function getVotedVoterList() public view returns (address[] memory){
        return votedVoters;
    }

    // 返回所有被授权投票的地址列表
    function getVoterList() public view returns (address[] memory){
        return votersAddress;
    }
}
