// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FunderDonation.sol";
import "./FunderSwap.sol";

contract FunderProxy {
    // USDC address compatible with Aave for aUSDC.
    address private constant USDC_KOVAN_ADDRESS =
        0xe22da380ee6B445bb8273C81944ADEB6E8450422;

    ERC20 private usdc = ERC20(USDC_KOVAN_ADDRESS);

    FunderSwap private immutable funderSwap;
    FunderDonation private immutable funderDonation;

    constructor(address funderSwapAddress, address funderDonationAddress) public {
        funderSwap = FunderSwap(funderSwapAddress);
        funderDonation = FunderDonation(funderDonationAddress);
    }

    function swapAndDonateETH(address to) external payable {
        require(msg.value > 0, "Cannot swap and donate 0 ETH");

        // Swaps ETH for USDC. Swapped USDC is returned to this contract, which
        // will be donated within the same transaction.
        funderSwap.swapToUSDC{value: msg.value}();

        uint256 swappedUSDCAmount = usdc.balanceOf(address(this));
        _donateUSDC(swappedUSDCAmount, to);
    }

    function _donateUSDC(uint256 amount, address to) private {
        require(amount > 0, "Cannot donate 0 USDC");
        usdc.increaseAllowance(address(funderDonation), amount);
        funderDonation.donate(amount, to);
    }
}
