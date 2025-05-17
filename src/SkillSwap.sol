// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SkillToken} from "./SkillToken.sol";



/// @title SkillToken - ERC20 reward token for SkillSwap platform
// contract SkillToken is ERC20, Ownable {
//     constructor() ERC20("SkillToken", "SKL") Ownable(msg.sender) {
//         _mint(msg.sender, 1_000_000 * 1e18);
//     }

//     function mint(address to, uint256 amount) external onlyOwner {
//         _mint(to, amount);
//     }
// }

/// @title SkillSwap - Skill trading platform with premium badge, offer expiry, ratings, and fees
/// @dev MrCoder
/// @author Usman Umar

contract SkillSwap is Ownable {
    enum SwapStatus { Pending, Approved, Completed, Cancelled, Expired }

    struct SkillOffer {
        uint256 id;
        address user;
        string skillHave;
        string skillWant;
        uint64 scheduledTime;
        uint64 createdAt;
        uint64 expiresIn; 
        SwapStatus status;
        address partner;
    }

    uint256 public offerCount;
    mapping(uint256 => SkillOffer) public offers;
    mapping(address => uint256[]) public userOffers;

    // Premium Badge System
    mapping(address => bool) public isPremium;
    uint256 public premiumBadgePrice = 50 * 1e18;

    // Ratings
    mapping(address => uint256) public totalRatings;
    mapping(address => uint256) public ratingCount;

    // Swap Fee
    uint256 public swapFee = 5 * 1e18;
    bool public swapFeeEnabled = false;

    SkillToken public skillToken;

    event OfferCreated(uint256 indexed offerId, address indexed user, string skillHave, string skillWant);
    event OfferMatched(uint256 indexed offerId, address indexed partner);
    event SwapCompleted(uint256 indexed offerId, address indexed user1, address indexed user2);
    event SwapCancelled(uint256 indexed offerId);
    event OfferExpired(uint256 indexed offerId);
    event OfferRemoved(uint256 indexed offerId);
    event PremiumBadgePurchased(address indexed user);
    event Rated(address indexed rater, address indexed ratedUser, uint8 rating);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        skillToken = SkillToken(_tokenAddress);
    }

    function createOffer(
        string calldata _have,
        string calldata _want,
        uint64 _scheduledTime,
        uint64 _expiresIn
    ) external {
        require(_scheduledTime > block.timestamp, "Scheduled time must be in future");
        require(_expiresIn > 1 hours, "Expiry too short");

        offers[offerCount] = SkillOffer({
            id: offerCount,
            user: msg.sender,
            skillHave: _have,
            skillWant: _want,
            scheduledTime: _scheduledTime,
            createdAt: uint64(block.timestamp),
            expiresIn: _expiresIn,
            status: SwapStatus.Pending,
            partner: address(0)
        });

        userOffers[msg.sender].push(offerCount);
        emit OfferCreated(offerCount, msg.sender, _have, _want);
        offerCount++;
    }

    function matchOffer(uint256 offerId) public {
        SkillOffer storage offer = offers[offerId];
        require(offer.status == SwapStatus.Pending, "Offer already matched or invalid");
        require(msg.sender != offer.user, "Cannot match own offer");
        require(block.timestamp <= offer.createdAt + offer.expiresIn, "Offer expired");

        offer.status = SwapStatus.Approved;
        offer.partner = msg.sender;

        emit OfferMatched(offerId, msg.sender);
    }

    function completeSwap(uint256 offerId) external {
        SkillOffer storage offer = offers[offerId];
        require(offer.status == SwapStatus.Approved, "Swap not approved");
        require(block.timestamp >= offer.scheduledTime, "Too early");
        require(msg.sender == offer.user || msg.sender == offer.partner, "Not a participant");

        offer.status = SwapStatus.Completed;

        if (swapFeeEnabled) {
            require(
                skillToken.transferFrom(offer.user, address(this), swapFee),
                "User fee failed"
            );
            require(
                skillToken.transferFrom(offer.partner, address(this), swapFee),
                "Partner fee failed"
            );
        }

        skillToken.mint(offer.user, 10 * 1e18);
        skillToken.mint(offer.partner, 10 * 1e18);

        emit SwapCompleted(offerId, offer.user, offer.partner);
    }

    function cancelSwap(uint256 offerId) external {
        SkillOffer storage offer = offers[offerId];
        require(msg.sender == offer.user, "Only creator");
        require(offer.status == SwapStatus.Pending, "Can't cancel now");

        offer.status = SwapStatus.Cancelled;
        emit SwapCancelled(offerId);
    }

    function expireOffer(uint256 offerId) external {
        SkillOffer storage offer = offers[offerId];
        require(offer.status == SwapStatus.Pending, "Already handled");
        require(block.timestamp > offer.createdAt + offer.expiresIn, "Not expired yet");

        offer.status = SwapStatus.Expired;
        emit OfferExpired(offerId);
    }

    function removeCancelledOffer(uint256 offerId) external onlyOwner {
        require(
            offers[offerId].status == SwapStatus.Cancelled ||
            offers[offerId].status == SwapStatus.Expired,
            "Not removable"
        );
        delete offers[offerId];
        emit OfferRemoved(offerId);
    }

    function getUserOffers(address user) external view returns (uint256[] memory) {
        return userOffers[user];
    }

    function getOfferDetails(uint256 offerId) external view returns (SkillOffer memory) {
        return offers[offerId];
    }

    function buyPremiumBadge() external {
        require(!isPremium[msg.sender], "Already premium");
        require(skillToken.transferFrom(msg.sender, address(this), premiumBadgePrice), "Transfer failed");

        isPremium[msg.sender] = true;
        emit PremiumBadgePurchased(msg.sender);
    }

    function setPremiumBadgePrice(uint256 _price) external onlyOwner {
        premiumBadgePrice = _price;
    }

    // --- Swap Fee Settings ---
    function setSwapFee(uint256 _fee) external onlyOwner {
        swapFee = _fee;
    }

    function toggleSwapFee(bool enabled) external onlyOwner {
        swapFeeEnabled = enabled;
    }

    // --- Ratings ---
    function rateUser(address ratedUser, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating out of range");

        totalRatings[ratedUser] += rating;
        ratingCount[ratedUser]++;

        emit Rated(msg.sender, ratedUser, rating);
    }

    function getAverageRating(address user) external view returns (uint256) {
        if (ratingCount[user] == 0) return 0;
        return totalRatings[user] / ratingCount[user];
    }
}
