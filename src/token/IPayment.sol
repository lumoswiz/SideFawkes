// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { FHE, euint128, inEuint128, ebool } from "@fhenixprotocol/contracts/FHE.sol";

interface IPayment {
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function approveEncrypted(address spender, inEuint128 memory amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function balanceOfEncrypted(address account) external view returns (euint128);
    function decimals() external view returns (uint8);
    function mint(address to, uint256 amount) external;
    function mintEncrypted(address to, inEuint128 memory amount) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferEncrypted(address to, euint128 amount) external;
    function transferEncrypted(address to, inEuint128 memory amount) external;
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transferFromEncrypted(address from, address to, euint128 amount) external;
    function transferFromEncrypted(address from, address to, inEuint128 memory amount) external;
    function unwrap(inEuint128 memory amount) external;
    function wrap(uint256 amount) external;
}
