//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract BankProject1 {
    // Creating mutiple and differen accounts for the users
    //Bank deposits money into his account and different accounts and the users can withdraw money from their accounts
    //The users can also check their account balance
    // owner of the account can withdraw money from an account
    //Bank can also close an account if the user wants to close it
    //Bank can also charge a fee for maintaining the account
    ///owner can also transfer money to another account

    // Know the information of the account holder
    struct Account {
        string name;
        uint256 accountBalance;
        address accountAddress;
        bool isAccountActive;
    }
    
uint256 public totalAmountInBank; // Total amount of money in the bank
address public immutable bankOwner; // Address of the bank owner
uint256 public constant FEE = 1e16; 
uint256 public maintenanceFee; // how much the fee is, in wei
uint256 public collectedFees;  // how much the bank has earned so far

    //// Creating mutiple and differen accounts for the users
    mapping(address => Account) public differentAccounts;

    modifier accountExists() {
        require(differentAccounts[msg.sender].isAccountActive == true, "Account does not exist");
        _;
    }
    modifier onlyBankOwner() {
        require(msg.sender == bankOwner, "Only the bank owner can perform this action");
        _;
    }

    /// Sets the owner of the bank upon deployment
    constructor(address _bankOwner) {
        bankOwner = _bankOwner;
    }

    //set maintainance fee by the bank owner
    function setMaintenanceFee(uint256 _fee) public onlyBankOwner {
        maintenanceFee = _fee;
    }

    function createAccount(string memory _name) public payable onlyBankOwner(bankOwvfb) {
        require(differentAccounts[msg.sender].isAccountActive == false, "Account already exists");
        differentAccounts[msg.sender] = Account({
            name: _name,
            accountBalance: 0,
            accountAddress: msg.sender,
            isAccountActive: true
        });
    }

 // Bank deposits money into his account and different accounts
    function userDeposit() public  payable accountExists {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        differentAccounts[msg.sender].accountBalance += msg.value;

        totalAmountInBank += msg.value; // Update total amount in the bank
        
       
    }

// the users can withdraw money from their accounts
    function userWithdraw(uint256 _amount) public accountExists {
        // CHECK: make sure the user actually has enough funds
        require(_amount > 0, "withdrawal amount must be greater than zero");
        require(differentAccounts[msg.sender].accountBalance >= _amount, "Insufficient balance");

        // EFFECT: update state BEFORE sending ETH
        // (this is the CEI pattern — protects against re-entrancy attacks)
        differentAccounts[msg.sender].accountBalance -= _amount;
        totalAmountInBank -= _amount; // Update total amount in the bank

     // Calculate what user actually receives after fee
        uint256 amountAfterFee = _amount - maintenanceFee;
        collectedFees += maintenanceFee; // Update collected fees for the bank
        // INTERACTION: send ETH to the user
        (bool isWithdrawn, ) = payable(msg.sender).call{value: amountAfterFee}("");
        require(isWithdrawn, "Withdrawal failed");
    }

    ///owner can also transfer money to another account
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function transferToUsers(address user, uint256 _amount) public accountExists {
          // Total cost to sender = amount + fee
           uint256 totalDeducted = _amount + maintenanceFee;

        // CHECK: make sure the user has enough funds, the recipient account exists, and the sender is not transferring to themselves
        require(_amount > 0, "Transfer amount must be greater than zero");
        require(differentAccounts[msg.sender].accountBalance >= _amount, "Insufficient balance");
        require(differentAccounts[user].isAccountActive == true, "Recipient account does not exist");
        require(msg.sender != user, "Cannot transfer to the same account");
           
        // EFFECT: update state BEFORE sending ETH
        differentAccounts[msg.sender].accountBalance -= totalDeducted; // Deduct the total amount (transfer + fee) from sender
        differentAccounts[user].accountBalance += _amount;
         collectedFees += maintenanceFee;  // Update collected fees for the bank
        emit Transfer(msg.sender, user, _amount);
    }  
    
    // /Bank can also close an account if the user wants to close it 
    function closeAccount() public accountExists{
        require(differentAccounts[msg.sender].accountBalance == 0, "Account balance must be zero to close the account");
        // let the account inactive and delete the account from the mapping
     differentAccounts[msg.sender].isAccountActive = false;
     //delete the account from the mapping
        delete differentAccounts[msg.sender];
        // Emit an event to indicate that the account has been closed
        emit AccountClosed(msg.sender);


    }
    

   event AccountClosed(address indexed account);
   event hasTransferred(address indexed from, address indexed to, uint256 amount);



}