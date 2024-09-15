// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InvestmentPlatform {
    
    struct Project {
        string name;
        uint256 targetAmount;
        uint256 currentAmount;
        uint256 deadline;
        address creator;
        bool isFunded;
        mapping(address => uint256) investments;  // 记录投资者的投资金额
        address[] investors;  // 存储所有投资者的地址
    }

    uint256 public projectIdCounter;
    mapping(uint256 => Project) public projects;

    event ProjectCreated(uint256 projectId, string name, uint256 targetAmount, uint256 deadline, address creator);
    event InvestmentReceived(uint256 projectId, address investor, uint256 amount);
    event ProjectFunded(uint256 projectId, uint256 totalAmount);
    event FundsWithdrawn(uint256 projectId, uint256 amount);
    event DividendDistributed(uint256 projectId, uint256 totalDividend);

    /**
     * @dev Create a new project.
     * @param name Name of the project.
     * @param targetAmount The target fundraising amount.
     * @param deadline The deadline for fundraising (block timestamp).
     */
    function createProject(string memory name, uint256 targetAmount, uint256 deadline) public {
        require(deadline > block.timestamp, "Deadline must be in the future");
        require(targetAmount > 0, "Target amount must be greater than zero");

        projectIdCounter++;
        Project storage newProject = projects[projectIdCounter];
        newProject.name = name;
        newProject.targetAmount = targetAmount;
        newProject.currentAmount = 0;
        newProject.deadline = deadline;
        newProject.creator = msg.sender;
        newProject.isFunded = false;

        emit ProjectCreated(projectIdCounter, name, targetAmount, deadline, msg.sender);
    }

    /**
     * @dev Invest in a project.
     * @param projectId ID of the project to invest in.
     */
    function invest(uint256 projectId) public payable {
        Project storage project = projects[projectId];

        require(block.timestamp < project.deadline, "Project funding period is over");
        require(msg.value > 0, "Investment must be greater than zero");
        require(project.currentAmount < project.targetAmount, "Project is already fully funded");

        if (project.investments[msg.sender] == 0) {
            project.investors.push(msg.sender);  // 记录新的投资者
        }

        project.investments[msg.sender] += msg.value;
        project.currentAmount += msg.value;

        emit InvestmentReceived(projectId, msg.sender, msg.value);

        // If the project is fully funded, mark it as funded
        if (project.currentAmount >= project.targetAmount) {
            project.isFunded = true;
            emit ProjectFunded(projectId, project.currentAmount);
        }
    }

    /**
     * @dev Allows project creator to withdraw funds if the project is fully funded.
     * @param projectId ID of the project.
     */
    function withdrawFunds(uint256 projectId) public {
        Project storage project = projects[projectId];

        require(msg.sender == project.creator, "Only the project creator can withdraw funds");
        require(project.isFunded, "Project is not fully funded");

        uint256 amount = project.currentAmount;
        project.currentAmount = 0;

        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(projectId, amount);
    }

    /**
     * @dev Distribute dividends to the investors if the project is fully funded.
     * @param projectId ID of the project.
     */
    function distributeDividends(uint256 projectId) public {
        Project storage project = projects[projectId];
        
        require(msg.sender == project.creator, "Only the project creator can distribute dividends");
        require(project.isFunded, "Project is not fully funded");

        uint256 totalInvestment = project.currentAmount;
        uint256 dividendPerInvestor = totalInvestment / project.investors.length;

        for (uint i = 0; i < project.investors.length; i++) {
            address investor = project.investors[i];
            uint256 investment = project.investments[investor];
            uint256 dividend = (investment * dividendPerInvestor) / totalInvestment;
            payable(investor).transfer(dividend);
        }

        emit DividendDistributed(projectId, totalInvestment);
    }
}
