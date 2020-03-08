pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IPFlashLoanReceiver.sol";


contract PFlashLoans is Ownable {
    using SafeMath for uint256;

    // Amount of fee to be paid on a flash loan 10**18 == 100%
    uint256 public fee;
    // Fee share for the fee recipient
    uint256 public feeShare;

    address public feeRecipient;

    constructor(uint256 _fee, uint256 _feeShare, address _feeRecipient) Ownable() public {
        require(_fee <= 10**18, "PFlashLoans.constructor: Fee too big");
        require(_feeShare <= 10**18, "PFlashLoans.constructor: Fee too big");
        fee = _fee;
        feeShare = _feeShare;
        feeRecipient = _feeRecipient;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= 10**18, "PFlashLoans.setFee: Fee too big");
        fee = _fee;
    }

    function setFeeShare(uint256 _feeShare) external onlyOwner {
        require(_feeShare <= 10**18, "PFlashLoans.setFeeShare: Fee too big");
        feeShare = _feeShare;
    }

    function flashLoan(
        address _from,
        address _token,
        uint256 _amount,
        address _recipient,
        bytes calldata _params
    ) external {
        IERC20 token = IERC20(_token);
        IPFlashLoanReceiver recipient = IPFlashLoanReceiver(_recipient);

        uint256 feeAmount = _amount.mul(fee).div(10**18);
        uint256 feeShareAmount = feeAmount.mul(feeShare).div(10**18);
        require(feeShareAmount != 0, "PFlashLoans.flashLoan: Amount too low");
        // Send tokens to flash loan recipient
        require(token.transferFrom(_from, _recipient, _amount), "PFlashLoans.flashLoan: transferFrom failed");
        recipient.executeOperation(_token, _amount, feeAmount, _params);
        require(token.transfer(_from, _amount.add(feeAmount).sub(feeShareAmount)), "PFlashLoans.flashLoan: transfer to lender failed");
        require(token.transfer(feeRecipient, feeShareAmount), "PFlashLoans.flashLoan: transfer to fee recipient failed");
    }
}