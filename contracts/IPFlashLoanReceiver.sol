pragma solidity ^0.6.2;

interface IPFlashLoanReceiver {
    function executeOperation(address _token, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}