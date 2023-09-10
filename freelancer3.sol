// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */


 contract freelancer{
     uint TaskNo;
     uint UserNo;
     address payable public owner;
     constructor() {
         TaskNo = 0;
         UserNo = 0;
         owner = payable(address(this));
    }

    enum status_type{Advertised , UnderProgress , Completed , Rejected, NeedtoCheck}
    struct Project{
        string Name;
        address owner;
        string Description;
        uint ID;
        status_type Status;
        uint fees;
        address taken_by;
    }

    Project[] Projects;
    string[] Projects_Name;

    struct Lancer{
        uint ID;
        string Name;
        address User;
        uint[] Projects_No;
    }

    Lancer[] Lancers;
    function CreateProject(string memory _Name,string calldata _Description,uint _fees) public payable returns (uint){
        require(msg.sender.balance > msg.value);
        require(msg.value == _fees*10**18);
        Projects.push(Project({
            Name : _Name,
            owner : msg.sender,
            Description : _Description,
            ID : TaskNo,
            Status : status_type.Advertised,
            fees : _fees,
            taken_by : address(0) // sort of like a null address
        }));
        Projects_Name.push(_Name);
        TaskNo += 1;
        return TaskNo-1;
    }

    function addLancer(string calldata _Name) public returns (uint) {
        Lancer memory newLancer = Lancer({
            ID: Lancers.length,
            Name: _Name,
            User: msg.sender,
            Projects_No: new uint[](0) // Initialize an empty dynamic array
        });
        
        Lancers.push(newLancer);
        
        return Lancers.length - 1;
    }

    function findProjectIndexByTaskNo(uint taskNo) public view returns (uint) {
    for (uint i = 0; i < Projects.length; i++) {
        if (Projects[i].ID == taskNo) {
            return i; 
        }
    }
    return uint(Projects.length);
    }

    function findLancerIndexByAddress(address adrs) public view returns (uint) {
        for (uint i = 0; i < Lancers.length; i++) {
            if (Lancers[i].User == adrs) {
                return i; 
            }
        }
        return uint(Lancers.length);
    }


    function ListProjects() public view returns (string[] memory){
        return Projects_Name;
    }

    function check_Project(uint _TaskNo) public view returns(Project memory){
        return Projects[_TaskNo];
    }

    function take_Project(uint _TaskNo) public {
        require (Projects[_TaskNo].Status == status_type.Advertised);
        Projects[_TaskNo].Status = status_type.UnderProgress;
        Projects[_TaskNo].taken_by = msg.sender;
        uint index = findLancerIndexByAddress(msg.sender);
        require(index < Lancers.length, "Lancer not found"); 
        Lancers[index].Projects_No.push(_TaskNo);
    }

    function submit_project(uint _TaskNo) public {
        require(Projects[_TaskNo].Status == status_type.UnderProgress);
        require (Projects[_TaskNo].taken_by == msg.sender);
        Projects[_TaskNo].Status = status_type.NeedtoCheck; 
    }


    function accept_project(uint _TaskNo , uint _fees) public {
        require(Projects[_TaskNo].Status == status_type.NeedtoCheck);
        require(Projects[_TaskNo].fees == _fees);
        //pay the lancer here with address Projects.taken_by
        payable(Projects[_TaskNo].taken_by).transfer(_fees*10**18);
        Projects[_TaskNo].Status = status_type.Completed;
    }

    function reject_submission(uint _TaskNo) public {
        require(Projects[_TaskNo].Status == status_type.NeedtoCheck);
        Projects[_TaskNo].Status = status_type.Advertised;
        address adrs = Projects[_TaskNo].taken_by;
        Projects[_TaskNo].taken_by = address(0);
        uint index = findLancerIndexByAddress(adrs);
        for(uint i = 0; i < Lancers[index].Projects_No.length; i++){
            if(Lancers[index].Projects_No[i] == _TaskNo){
                Lancers[index].Projects_No[i] = Lancers[index].Projects_No[Lancers[index].Projects_No.length - 1];
                Lancers[index].Projects_No.pop();
            }
        }
    }
 }