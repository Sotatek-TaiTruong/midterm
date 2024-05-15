// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract SwapContract is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct SwapRequest {
        address requester;
        address approver;
        uint256 amount;
        uint256 status; // 0: Pending, 1: Approved, 2: Rejected, 3: Cancelled
        IERC20 tokenA;
        IERC20 tokenB;
    }

    mapping(uint256 => SwapRequest) public swapRequests;
    uint256 public swapRequestCounter;
    uint256 public feePercent;
    address public treasury;

    event SwapRequestCreated(
        uint256 indexed requestId,
        address indexed requester,
        address indexed approver,
        uint256 amount
    );
    event SwapRequestStatusChanged(uint256 indexed requestId, uint256 status);

    constructor(address _treasury, uint256 _feePercent) {
        treasury = _treasury;
        feePercent = _feePercent;
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(msg.sender);
        _disableInitializers();
    }

    function createSwapRequest(
        address _approver,
        uint256 _amount,
        IERC20 _tokenA,
        IERC20 _tokenB
    ) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");

        _tokenA.transferFrom(msg.sender, address(this), _amount);

        swapRequestCounter++;
        swapRequests[swapRequestCounter] = SwapRequest({
            requester: msg.sender,
            approver: _approver,
            amount: _amount,
            status: 0,
            tokenA: _tokenA,
            tokenB: _tokenB
        });

        emit SwapRequestCreated(
            swapRequestCounter,
            msg.sender,
            _approver,
            _amount
        );
    }

    function approveSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.status == 0, "Swap request is not pending");
        require(
            msg.sender == request.approver,
            "Only approver can approve this swap request"
        );

        uint256 fee = (request.amount * feePercent) / 100;
        uint256 netAmount = request.amount - fee;

        request.tokenB.transferFrom(msg.sender, address(this), request.amount);
        request.tokenA.transfer(msg.sender, netAmount);
        request.tokenB.transfer(request.requester, netAmount);

        request.tokenA.transfer(treasury, fee);
        request.tokenB.transfer(treasury, fee);

        request.status = 1;
        emit SwapRequestStatusChanged(_requestId, 1);
    }

    function rejectSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.status == 0, "Swap request is not pending");
        require(
            msg.sender == request.approver,
            "Only approver can reject this swap request"
        );

        request.tokenA.transfer(request.requester, request.amount);

        request.status = 2;
        emit SwapRequestStatusChanged(_requestId, 2);
    }

    function cancelSwapRequest(uint256 _requestId) external nonReentrant {
        SwapRequest storage request = swapRequests[_requestId];
        require(request.status == 0, "Swap request is not pending");
        require(
            msg.sender == request.requester,
            "Only requester can cancel this swap request"
        );

        request.tokenA.transfer(request.requester, request.amount);

        request.status = 3;
        emit SwapRequestStatusChanged(_requestId, 3);
    }

    function setFeePercent(uint256 _feePercent) external onlyOwner {
        feePercent = _feePercent;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
}
