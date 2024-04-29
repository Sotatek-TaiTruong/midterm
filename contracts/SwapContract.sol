// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SwapContract is Ownable, ReentrancyGuard {
    enum SwapStatus { Pending, Approved, Rejected, Cancelled }

    struct SwapRequest {
        address payable sender;
        address payable receiver;
        uint256 amount;
        SwapStatus status;
    }

    SwapRequest[] public swapRequests;
    address public treasury;
    uint256 public transactionFee = 5; // 5% transaction fee

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function createSwapRequest(address payable _receiver, uint256 _amount) external payable nonReentrant {
        require(msg.value > 0, "Amount must be greater than 0");
        SwapRequest memory newRequest = SwapRequest({
            sender: payable(msg.sender),
            receiver: _receiver,
            amount: _amount,
            status: SwapStatus.Pending
        });
        swapRequests.push(newRequest);
        emit SwapRequestCreated(swapRequests.length - 1, msg.sender, _receiver, _amount);
    }

    function approveSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.status == SwapStatus.Pending, "Request is not pending");
        require(msg.sender == request.receiver, "Only the receiver can approve");

        uint256 fee = (request.amount * transactionFee) / 100;
        uint256 amountToTransfer = request.amount - fee;

        payable(treasury).transfer(fee);
        request.receiver.transfer(amountToTransfer);
        request.sender.transfer(request.amount);

        request.status = SwapStatus.Approved;
        emit SwapRequestApproved(_requestId, msg.sender);
    }

    function rejectSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.status == SwapStatus.Pending, "Request is not pending");
        require(msg.sender == request.receiver, "Only the receiver can reject");

        request.sender.transfer(request.amount);
        request.status = SwapStatus.Rejected;
        emit SwapRequestRejected(_requestId, msg.sender);
    }

    function cancelSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.status == SwapStatus.Pending, "Request is not pending");
        require(msg.sender == request.sender, "Only the sender can cancel");

        request.sender.transfer(request.amount);
        request.status = SwapStatus.Cancelled;
        emit SwapRequestCancelled(_requestId, msg.sender);
    }

    function setTransactionFee(uint256 _fee) external onlyOwner {
        transactionFee = _fee;
    }

    event SwapRequestCreated(uint256 indexed requestId, address indexed sender, address indexed receiver, uint256 amount);
    event SwapRequestApproved(uint256 indexed requestId, address indexed approver);
    event SwapRequestRejected(uint256 indexed requestId, address indexed rejector);
    event SwapRequestCancelled(uint256 indexed requestId, address indexed canceller);
}