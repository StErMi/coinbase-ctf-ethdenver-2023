// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Using OpenZeppelin 4.7.0 contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// Solve the riddles and embrace the challenge you will face,
/// To add yourself to the leaderboard, to become based.
///
/// @dev If using Coinbase Wallet, find your private key in the CB Wallet Chrome Extension
///      (Settings -> Developer Settings > Show private key).
/// @dev Need test funds? https://coinbase.com/faucets
contract RiddleBounty is Ownable {
    using ECDSA for bytes32;

    /// @dev Bounty is active
    bool public isOpenFlag;

    /// @dev Those who have solved challenge 1
    mapping(address => bool) public solvedChallenge1;

    /// @dev Those who have solved challenges 1 and 2
    mapping(address => bool) public solvedChallenge2;

    /// @dev Challenge finishers in order of finishing time
    address[] public leaderboard;

    /// @dev Finishing times of challenge finishers
    mapping(address => uint256) public finishingTimes;

    mapping(address => bytes) public previousSignature;
    mapping(address => address) public userWhoUsedSigner;

    bytes32 private constant RIDDLE_1_HASH = 0x3896ee3a8be6143be3fa1938adbae827fc724b5ff649501e7fd8c0c5352cbafa;
    bytes32 private constant RIDDLE_2_HASH = 0x9c611b41c1f90946c2b6ddd04d716f6ec349ac4b4f99612c3e629db39502b941;
    bytes32 private constant RIDDLE_3_HASH = 0x3cd65f6089844a3c6409b0acc491ca0071a5672c2ab2a071f197011e0fc66b6a;

    /// @dev calculated as ECDSA.toEthSignedMessageHash(RIDDLE_3_HASH)
    bytes32 private constant RIDDLE_3_ETH_MESSAGE_HASH =
        0x20a1626365cea00953c957fd02ddc4963990d404232d4e58acb66f46c59d9887;

    modifier isOpen() {
        require(isOpenFlag, "Bounty is closed");
        _;
    }

    /// @dev Opens the bounty.
    /// @dev The contract owner is the deployer and is the only one who can open or close the bounty.
    constructor() {
        isOpenFlag = true;
    }

    function hasSolvedChallenge1(address user) external view returns (bool) {
        return solvedChallenge1[user];
    }

    function hasSolvedChallenge2(address user) external view returns (bool) {
        return solvedChallenge2[user];
    }

    function isOnLeaderboard(address user) external view returns (bool) {
        return finishingTimes[user] > 0;
    }

    function getLeaderboardStats() external view returns (address[] memory, uint256[] memory) {
        uint256[] memory timestamps = new uint256[](leaderboard.length);
        for (uint256 i = 0; i < leaderboard.length; i++) {
            timestamps[i] = finishingTimes[leaderboard[i]];
        }
        return (leaderboard, timestamps);
    }

    /// In the new world there's a curious thing,
    /// A tap that pours coins, like a magical spring
    /// A free-for-all place so vast,
    /// A resource that fills your wallet fast (cccccc)
    function solveChallenge1(string calldata riddleAnswer) external isOpen {
        if (RIDDLE_1_HASH == keccak256(abi.encodePacked(riddleAnswer))) {
            solvedChallenge1[msg.sender] = true;
        }
    }

    /// Onward we journey, through sun and rain
    /// A path we follow, with hope not in vain
    /// Guided by the Beacon Chain, with unwavering aim
    /// Our destination approaches, where two become the same (Ccc Ccccc)
    ///
    /// @dev These may be helpful: https://docs.ethers.org/v5/api/utils/hashing/ and
    /// https://docs.ethers.org/v5/api/signer/#Signer-signMessage
    function solveChallenge2(string calldata riddleAnswer, bytes calldata signature) external isOpen {
        bytes32 messageHash = keccak256(abi.encodePacked(riddleAnswer));

        require(RIDDLE_2_HASH == messageHash, "riddle not solved yet");

        require(msg.sender == ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature), "invalid signature");

        if (solvedChallenge1[msg.sender]) {
            solvedChallenge2[msg.sender] = true;
        }
    }

    /// A proposal was formed, a new blob in the land,
    /// To help with the scale, and make things more grand
    /// A way to improve the network's high fees,
    /// And make transactions faster, with greater ease (CCC-NNNN)
    ///
    /// @dev These may be helpful: https://docs.ethers.org/v5/api/utils/hashing/ and
    /// https://docs.ethers.org/v5/api/signer/#Signer-signMessage
    function solveChallenge3(
        string calldata riddleAnswer,
        address signer,
        bytes calldata signature
    ) external isOpen {
        require(signer != address(0), "signer cannot be zero address");

        bytes32 messageHash = keccak256(abi.encodePacked(riddleAnswer));
        require(RIDDLE_3_HASH == messageHash, "riddle answer incorrect");

        require(
            signer == ECDSA.recover(RIDDLE_3_ETH_MESSAGE_HASH, signature),
            "invalid signature, message must be signed by signer"
        );

        if (previousSignature[signer].length == 0) {
            previousSignature[signer] = signature;
            userWhoUsedSigner[signer] = msg.sender;
            return;
        }

        require(userWhoUsedSigner[signer] == msg.sender, "solution was used by someone else");

        require(
            keccak256(abi.encodePacked(previousSignature[signer])) != keccak256(abi.encodePacked(signature)),
            "you have already used this signature, try submitting a different one"
        );

        if (solvedChallenge2[msg.sender] && (finishingTimes[msg.sender] == 0)) {
            finishingTimes[msg.sender] = block.timestamp;
            leaderboard.push(msg.sender);
        }
    }

    function open() external onlyOwner {
        isOpenFlag = true;
    }

    function close() external onlyOwner {
        isOpenFlag = false;
    }
}
