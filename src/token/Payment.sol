// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { FHE, euint128, inEuint128 } from "@fhenixprotocol/contracts/FHE.sol";

contract Payment is ERC20("PAYMENT", "PAY") {
    mapping(address => euint128) internal _encBalances;
    mapping(address => mapping(address => euint128)) internal _allowances;

    function wrap(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount);

        _burn(msg.sender, amount);

        euint128 a = FHE.asEuint128(amount);
        euint128 b = _encBalances[msg.sender];

        _encBalances[msg.sender] = FHE.add(b, a);
    }

    function unwrap(inEuint128 calldata amount) external {
        euint128 a = FHE.asEuint128(amount);
        euint128 b = _encBalances[msg.sender];
        FHE.req(b.gte(a));

        _encBalances[msg.sender] = FHE.sub(b, a);

        _mint(msg.sender, FHE.decrypt(a));
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function mintEncrypted(address to, inEuint128 calldata amount) external {
        euint128 a = FHE.asEuint128(amount);
        euint128 b = _encBalances[to];
        _encBalances[to] = FHE.add(b, a);
    }

    function _approve(address owner, address spender, euint128 amount) internal {
        _allowances[owner][spender] = amount;
    }

    function approveEncrypted(address spender, inEuint128 calldata amount) external {
        _approve(msg.sender, spender, FHE.asEuint128(amount));
    }

    function _spendAllowance(address owner, address spender, euint128 amount) internal returns (euint128) {
        euint128 current = allowanceEncrypted(owner, spender);
        euint128 spent = FHE.min(current, amount);
        _approve(owner, spender, FHE.sub(current, spent));
        return spent;
    }

    function transferFromEncrypted(address from, address to, inEuint128 calldata amount) external {
        transferFromEncrypted(from, to, FHE.asEuint128(amount));
    }

    function transferFromEncrypted(address from, address to, euint128 amount) public {
        euint128 spent = _spendAllowance(from, msg.sender, amount);
        _transferImpl(from, to, spent);
    }

    function transferEncrypted(address to, inEuint128 calldata amount) public {
        _transferImpl(msg.sender, to, FHE.asEuint128(amount));
    }

    function transferEncrypted(address to, euint128 amount) public {
        _transferImpl(msg.sender, to, amount);
    }

    function _transferImpl(address from, address to, euint128 amount) internal {
        euint128 value = FHE.select(amount.lte(_encBalances[from]), amount, FHE.asEuint128(0));
        _encBalances[to] = FHE.add(_encBalances[to], value);
        _encBalances[from] = FHE.sub(_encBalances[from], value);
    }

    function balanceOfEncrypted(address account) external view returns (euint128) {
        return _encBalances[account];
    }

    function allowanceEncrypted(address owner, address spender) public view returns (euint128) {
        return _allowances[owner][spender];
    }
}
