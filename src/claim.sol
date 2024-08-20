// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@solady/src/auth/Ownable.sol";
import "@solady/src/tokens/ERC20.sol";

/// @title omcVest
/// @author 0xfraan
/// @notice Vesting contract for OMC sales
contract omcVest is Ownable {
    uint256 public totalAmount;
    uint256 public totalDeposit;

    uint64 public fee;
    address public token;

    mapping(address => uint256) public amount;
    mapping(address => uint256) public claimed;

    error InvalidAddress();
    error InvalidLength();
    error TransferFailed();
    error InsufficientFee();

    constructor(address _token, uint64 _fee) {
        if (_token == address(0)) revert InvalidAddress();

        _initializeOwner(msg.sender);

        token = _token;
        fee = _fee;
    }

    function claim() external payable {
        if (msg.value < fee) revert InsufficientFee();

        uint256 released = claimable(msg.sender);
        if (released == 0) return;

        unchecked {
            claimed[msg.sender] += released;
        }

        ERC20(token).transfer(msg.sender, released);
    }

    function claimable(address _user) public view returns (uint256) {
        return unlocked(_user) - claimed[_user];
    }

    function unlocked(address _user) public view returns (uint256) {
        return (amount[_user] * totalDeposit) / totalAmount;
    }

    function deposit(uint256 _amount) external onlyOwner {
        unchecked {
            totalDeposit += _amount;
        }

        ERC20(token).transferFrom(owner(), address(this), _amount);
    }

    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        ERC20(_token).transfer(owner(), _amount);
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        (bool success,) = owner().call{value: _amount}("");
        if (!success) revert TransferFailed();
    }

    function setFee(uint64 _fee) external onlyOwner {
        fee = _fee;
    }

    function setAmounts(address[] memory _users, uint256[] memory _amounts) external onlyOwner {
        if (_users.length != _amounts.length) revert InvalidLength();

        for (uint256 i; i < _amounts.length; ++i) {
            amount[_users[i]] = _amounts[i];
            totalAmount += _amounts[i];
        }
    }
}