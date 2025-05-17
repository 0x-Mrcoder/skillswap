// test/SkillSwap.t.sol
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SkillSwap.sol";

contract SkillSwapTest is Test {
    SkillSwap skillSwap;
    SkillToken skillToken;

function setUp() public {
    skillToken = new SkillToken();
    skillToken.mint(address(this), 1_000_000 * 1e18);
    skillSwap = new SkillSwap(address(skillToken));
    skillToken.transferOwnership(address(skillSwap));
}

    function testCreateOffer() public {
        skillSwap.createOffer("JavaScript", "Solidity", uint64(block.timestamp + 1 days), uint64(2 days));
        SkillSwap.SkillOffer memory offer = skillSwap.getOfferDetails(0);
        assertEq(offer.skillHave, "JavaScript");
        assertEq(offer.skillWant, "Solidity");
        assertEq(offer.user, address(this));
    }

    function testMatchOffer() public {
        skillSwap.createOffer("JavaScript", "Solidity", uint64(block.timestamp + 1 days), uint64(2 days));
        vm.prank(address(0x123));
        skillSwap.matchOffer(0);
        SkillSwap.SkillOffer memory offer = skillSwap.getOfferDetails(0);
        assertEq(uint256(offer.status), uint256(SkillSwap.SwapStatus.Approved));
        assertEq(offer.partner, address(0x123));
    }

    function testCompleteSwapMintsTokenReward() public {
    address creator = address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
    address matcher = address(0x0000000000000000000000000000000000000123);

    // Give both addresses some tokens if needed for swapFee, otherwise skip
    // skillToken.mint(creator, 0); // Not needed, SkillSwap will mint reward

    vm.prank(creator);
    skillSwap.createOffer("JS", "Solidity", uint64(block.timestamp + 1), uint64(2 days));
    vm.prank(matcher);
    skillSwap.matchOffer(0);
    vm.warp(block.timestamp + 2);

    uint256 creatorBefore = skillToken.balanceOf(creator);
    uint256 matcherBefore = skillToken.balanceOf(matcher);

    vm.prank(creator);
    skillSwap.completeSwap(0);

    uint256 creatorAfter = skillToken.balanceOf(creator);
    uint256 matcherAfter = skillToken.balanceOf(matcher);

    assertEq(creatorAfter - creatorBefore, 10 * 1e18);
    assertEq(matcherAfter - matcherBefore, 10 * 1e18);
}

    function testOnlyCreatorCanCancelSwap() public {
        skillSwap.createOffer("Go", "Rust", uint64(block.timestamp + 1 days), uint64(2 days));
        vm.prank(address(0x999));
        vm.expectRevert("Only creator");
        skillSwap.cancelSwap(0);
    }

    function testCreatorCannotMatchOwnOffer() public {
        skillSwap.createOffer("Python", "Solidity", uint64(block.timestamp + 1 days), uint64(2 days));
        vm.expectRevert("Cannot match own offer");
        skillSwap.matchOffer(0);
    }

    function testCannotMatchAlreadyMatchedOffer() public {
        skillSwap.createOffer("Python", "Solidity", uint64(block.timestamp + 1 days), uint64(2 days));
        vm.prank(address(0x123));
        skillSwap.matchOffer(0);
        vm.prank(address(0x456));
        vm.expectRevert("Offer already matched or invalid");
        skillSwap.matchOffer(0);
    }

    function testCannotCancelMatchedOffer() public {
        skillSwap.createOffer("Python", "Solidity", uint64(block.timestamp + 1 days), uint64(2 days));
        vm.prank(address(0x123));
        skillSwap.matchOffer(0);
        vm.expectRevert("Can't cancel now");
        skillSwap.cancelSwap(0);
    }

    function testOnlyOwnerCanRemoveCancelledOffer() public {
        skillSwap.createOffer("JS", "Solidity", uint64(block.timestamp + 1 days), uint64(2 days));
        skillSwap.cancelSwap(0);

        vm.prank(address(0x123));
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", address(0x123))
        );
        skillSwap.removeCancelledOffer(0);

        skillSwap.removeCancelledOffer(0); // should succeed
    }

    function testBuyPremiumBadge() public {
        skillToken.approve(address(skillSwap), 50 * 1e18);
        skillSwap.buyPremiumBadge();
        assertTrue(skillSwap.isPremium(address(this)));
        assertEq(skillToken.balanceOf(address(skillSwap)), 50 * 1e18);
    }

    function testCannotBuyPremiumBadgeTwice() public {
        skillToken.approve(address(skillSwap), 100 * 1e18);
        skillSwap.buyPremiumBadge();
        vm.expectRevert("Already premium");
        skillSwap.buyPremiumBadge();
    }

function testBuyPremiumBadgeFailsWithoutEnoughTokens() public {
    address user = address(0xBEEF);
    vm.prank(user);
    skillToken.approve(address(skillSwap), 50 * 1e18);
    vm.prank(user);
    vm.expectRevert();
    skillSwap.buyPremiumBadge();
}
    function testBuyPremiumBadgeFailsWithoutApproval() public {
        vm.expectRevert();
        skillSwap.buyPremiumBadge();
    }

    function testOnlyParticipantsCanCompleteSwap() public {
        skillSwap.createOffer("Python", "Rust", uint64(block.timestamp + 1), uint64(2 days));
        vm.prank(address(0x123));
        skillSwap.matchOffer(0);
        vm.warp(block.timestamp + 2);
        vm.prank(address(0x456));
        vm.expectRevert("Not a participant");
        skillSwap.completeSwap(0);
    }

    function testCancelSwap() public {
        skillSwap.createOffer("JS", "Solidity", uint64(block.timestamp + 1 days), uint64(2 days));
        skillSwap.cancelSwap(0);
        SkillSwap.SkillOffer memory offer = skillSwap.getOfferDetails(0);
        assertEq(uint256(offer.status), uint256(SkillSwap.SwapStatus.Cancelled));
    }

    function testNonPremiumCanCreateOffer() public {
        // Should not revert
        skillSwap.createOffer("HTML", "CSS", uint64(block.timestamp + 1 days), uint64(2 days));
    }

    function testIsPremiumReturnsFalseByDefault() public view {
        assertFalse(skillSwap.isPremium(address(this)));
    }
}