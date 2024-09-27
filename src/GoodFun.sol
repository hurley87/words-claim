// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./vendor/GelatoVRFConsumerBase.sol";
import "./Base64.sol";

contract GoodFun is ERC1155, GelatoVRFConsumerBase, Ownable {
    using Strings for uint256;

    IERC20 public erc20Token;
    bytes32 public merkleRoot;

    address private immutable _operatorAddr;
    string public name = "Fun Games";
    string public symbol = "$FUN";

    mapping(address => bool) public hasClaimedFreeTokens;
    mapping(uint256 => uint256) public scores;

    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant TOKEN_FACTOR = (10 ** 18);

    string public wordOfTheDay;
    uint256 public wordOfTheDayBonus = 2; // Multiplier for the bonus word

    function _operator() internal view override returns (address) {
        return _operatorAddr;
    }

    constructor(address operator)
        ERC1155("https://amber-late-bug-27.mypinata.cloud/ipfs/QmetCwbwaGa8VeTnVpcFCA9TeUDzjuNUXss9CaPzAjv2oi/{id}.json")
    {
        _operatorAddr = operator;
        erc20Token = IERC20(address(0x0ea1113fD40f0ABd399eEa1472d2d9b6AB953298));
        merkleRoot = 0xe69613e429a14618f9632b98731504b6f68c75ed6d7a37e9a9e7c48423141aac;
        _initializeScores();
    }

    // Initialize scores for letters A-Z
    function _initializeScores() internal {
        scores[1] = 1; // A
        scores[2] = 3; // B
        scores[3] = 3; // C
        scores[4] = 2; // D
        scores[5] = 1; // E
        scores[6] = 4; // F
        scores[7] = 2; // G
        scores[8] = 4; // H
        scores[9] = 1; // I
        scores[10] = 7; // J
        scores[11] = 5; // K
        scores[12] = 1; // L
        scores[13] = 3; // M
        scores[14] = 1; // N
        scores[15] = 1; // O
        scores[16] = 3; // P
        scores[17] = 9; // Q
        scores[18] = 1; // R
        scores[19] = 1; // S
        scores[20] = 1; // T
        scores[21] = 1; // U
        scores[22] = 4; // V
        scores[23] = 4; // W
        scores[24] = 7; // X
        scores[25] = 4; // Y
        scores[26] = 9; // Z
    }

    function _fulfillRandomness(uint256 randomness, uint256, bytes memory extraData) internal override {
        address recipient = abi.decode(extraData, (address));

        uint8[26] memory frequencies = [9, 2, 2, 4, 12, 2, 3, 2, 9, 1, 1, 4, 2, 6, 8, 2, 1, 6, 4, 6, 4, 2, 2, 1, 2, 1];

        uint256 totalLetters = 98; // Sum of all frequencies

        uint256 mintAmount = 10;
        uint256[] memory ids = new uint256[](mintAmount);
        uint256[] memory amounts = new uint256[](mintAmount);

        for (uint256 j = 0; j < mintAmount; j++) {
            // Generate a random index
            uint256 randomIndex =
                uint256(keccak256(abi.encode(randomness, block.timestamp, msg.sender, j))) % totalLetters;

            // Find the corresponding letter
            uint256 randomNumber = 1;
            uint256 accumulatedFrequency = 0;
            for (uint256 i = 0; i < frequencies.length; i++) {
                accumulatedFrequency += frequencies[i];
                if (randomIndex < accumulatedFrequency) {
                    randomNumber = i + 1; // +1 because array is 0-indexed but letters are 1-26
                    break;
                }
            }

            require(randomNumber >= 1 && randomNumber <= 26, "Invalid random number");

            ids[j] = randomNumber;
            amounts[j] = 1;
        }

        _mintBatch(recipient, ids, amounts, "");
    }

    function mintTen() public payable {
        if (!hasClaimedFreeTokens[msg.sender]) {
            hasClaimedFreeTokens[msg.sender] = true;
        } else {
            require(msg.value >= MINT_PRICE, "Insufficient payment");
        }

        _requestRandomness(abi.encode(msg.sender));
    }

    function burnAndRedeem(
        string memory word,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes32[] calldata merkleProof
    ) public {
        // Step 1: Verify the inferred word using the Merkle proof
        require(_verifyWord(word, merkleProof), "Invalid word");

        uint256 totalValue = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            // Step 2: Check that the user owns enough of each token ID using balanceOf
            uint256 balance = balanceOf(msg.sender, ids[i]);
            require(balance >= amounts[i], "Not enough balance to burn");

            totalValue += scores[ids[i]] * amounts[i];
        }

        // Step 3: Batch burn the ERC-1155 tokens
        _burnBatch(msg.sender, ids, amounts);

        // Step 4: Apply bonus if the word matches the Word of the Day
        if (keccak256(abi.encodePacked(word)) == keccak256(abi.encodePacked(wordOfTheDay))) {
            totalValue *= wordOfTheDayBonus;
        }

        // Step 5: Transfer corresponding amount of ERC-20 tokens
        uint256 tokenAmount = totalValue * TOKEN_FACTOR;
        require(erc20Token.transfer(msg.sender, tokenAmount), "Token transfer failed");
    }

    function _verifyWord(string memory word, bytes32[] calldata proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(word));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // Set a new Merkle root (only owner)
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Test function to verify a word using the provided proof
    function verifyWord(string memory word, bytes32[] calldata proof) public view returns (bool) {
        // Hash the word using keccak256, similar to how it was hashed in the Merkle tree
        bytes32 leaf = keccak256(abi.encodePacked(word));

        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        return true;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // Updated function to withdraw ERC20 tokens
    function withdrawTokens(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");

        uint256 contractBalance = erc20Token.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient token balance");

        require(erc20Token.transfer(owner(), amount), "Token transfer failed");
    }

    // New function to set the Word of the Day
    function setWordOfTheDay(string memory _word) external onlyOwner {
        wordOfTheDay = _word;
    }

    // New function to set the Word of the Day bonus multiplier
    function setWordOfTheDayBonus(uint256 _bonus) external onlyOwner {
        require(_bonus > 0, "Bonus must be greater than 0");
        wordOfTheDayBonus = _bonus;
    }

    // New function to set the ERC20 token contract address
    function setERC20Token(address _newTokenAddress) external onlyOwner {
        require(_newTokenAddress != address(0), "Invalid token address");
        erc20Token = IERC20(_newTokenAddress);
    }
}
