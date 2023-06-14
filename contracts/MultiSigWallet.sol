// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint8 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint8 numConfirmations;
    }

    mapping(uint => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "MultiSigWallet: caller is not the owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "MultiSigWallet: tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "MultiSigWallet: tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "MultiSigWallet: tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint8 _numConfirmationsRequired) {
        require(_owners.length > 0, "MultiSigWallet: invalide owners parameter");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "MultiSigWallet: invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "MultiSigWallet: invalid owner");
            require(!isOwner[owner], "MultiSigWallet: owner not unique");
            isOwner[owner] = true;
        }
        owners = _owners;
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;
        transactions.push(
            Transaction(_to, _value, _data, false, 0)
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired, "MultiSigWallet: cannot execute tx");
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "MultiSigWallet: MultiSigWallet: tx failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "MultiSigWallet: tx not confirmed");
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
