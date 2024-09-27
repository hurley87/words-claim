// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
/**
 * @notice The Fun token
 */

contract FunToken is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit, ERC20Votes {
    /**
     * @dev EIP-20 token name for this token
     */
    string public constant TOKEN_NAME = "Fun";

    /**
     * @dev EIP-20 token symbol for this token
     */
    string public constant TOKEN_SYMBOL = "FUN";

    /**
     * @dev Total number of tokens in circulation
     */
    uint256 public constant TOKEN_INITIAL_SUPPLY = 111_111_111_111;

    /**
     * @dev Minimum time between mints
     */
    uint32 public constant MINIMUM_TIME_BETWEEN_MINTS = 1 days * 365;

    /**
     * @dev Cap on the percentage of totalSupply that can be minted at each mint
     */
    uint8 public constant MINT_CAP = 1;

    /**
     * @dev The timestamp after which minting may occur
     */
    uint256 public mintingAllowedAfter;

    /**
     * @dev The minting date has not been reached yet
     */
    error MintingDateNotReached();

    /**
     * @dev Cannot mint to the zero address
     */
    error MintToZeroAddressBlocked();

    /**
     * @dev Minting date must be set to occur after deployment
     */
    error MintAllowedAfterDeployOnly(uint256 blockTimestamp, uint256 mintingAllowedAfter);

    /**
     * @dev Attempted to mint more than the cap allows
     */
    error FunMintCapExceeded();

    /**
     * @dev Construct a new Fun token
     * @param ownerAddress The address that will own the contract
     */
    constructor(address ownerAddress) ERC20(TOKEN_NAME, TOKEN_SYMBOL) ERC20Permit(TOKEN_NAME) Ownable() {
        _mint(ownerAddress, TOKEN_INITIAL_SUPPLY * 10 ** decimals());

        mintingAllowedAfter = 1758028800;
        _transferOwnership(ownerAddress);
    }

    /**
     * @dev Mint new tokens
     * @param to The address of the target account
     * @param amount The number of tokens to be minted
     */
    function mint(address to, uint96 amount) external onlyOwner {
        if (block.timestamp < mintingAllowedAfter) {
            revert MintingDateNotReached();
        }

        if (to == address(0)) {
            revert MintToZeroAddressBlocked();
        }

        // record the mint
        mintingAllowedAfter = block.timestamp + MINIMUM_TIME_BETWEEN_MINTS;

        // mint the amount
        if (amount > (totalSupply() * MINT_CAP) / 100) {
            revert FunMintCapExceeded();
        }

        _mint(to, amount);
    }

    /**
     * @dev Pause all token transfers
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause all token transfers
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function nonces(address owner) public view override(ERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    // Add this function to implement pausing functionality
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
