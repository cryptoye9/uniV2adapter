// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";


contract UniswapV2Adapter is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable Router;
    address public immutable WETH;

    mapping (address => mapping (address => address[])) public routes; // tokenFrom => tokenTo => route
    mapping (address => mapping (address => uint256)) public routeLengths; // tokenFrom => tokenTo => route length

    error ZeroAddress();

    constructor(address _router, address _WETH) public {
        if (_router == address(0) || _WETH == address(0)) revert ZeroAddress();

        Router = IUniswapV2Router02(_router);
        WETH = _WETH;
    }

    function setRoute(address tokenFrom, address tokenTo, address[] memory route) external onlyOwner {
        for (uint8 i = 0; i < route.length; ++i) 
            routes[tokenFrom][tokenTo].push(route[i]);
        for (uint8 i = 0; i < route.length; ++i) 
            routes[tokenFrom][tokenTo].push(route[route.length - i - 1]);
        routeLengths[tokenFrom][tokenTo] = route.length;
    }

    function swap(address tokenFrom, uint256 amountToSwap, address tokenTo, uint256 slippage) external {        
        uint256 routeLength;
        uint256 balanceBeforeSwap = IERC20(tokenTo).balanceOf(address(this));

        if (routeLengths[tokenFrom][tokenTo] == 0) {
            routeLength = 3;

        } else {
            routeLength = routeLengths[tokenFrom][tokenTo];
        }

        SafeERC20.safeTransferFrom(
            IERC20(tokenFrom), msg.sender, address(this), amountToSwap
        );

        _swap(tokenFrom, amountToSwap, tokenTo, routeLength, slippage);
        uint256 amountToSend = IERC20(tokenTo).balanceOf(address(this)) - balanceBeforeSwap;
        IERC20(tokenTo).safeTransfer(msg.sender, amountToSend);
    }

    function _swap(
        address tokenFrom, 
        uint256 amountToSwap, 
        address tokenTo,
        uint256 routeLength, 
        uint256 slippage
    ) private {
        uint256 amountIn = amountToSwap;
        address to = address(this);
        uint256 deadline = block.timestamp + 100;
        address[] memory path = new address[](2);

        address[] memory route = getRoute(tokenFrom, tokenTo);
        for (uint8 i = 0; i < routeLength; i++) console.log(route[i]);

        for (uint8 i = 0; i < routeLength - 1; ++i) {
            path[0] = route[i];
            path[1] = route[i + 1];
            console.log(path[0], path[1]);
            uint256[] memory amountsOutMin = new uint[](2);
            amountsOutMin = Router.getAmountsOut(amountIn, path);
            uint256 amountOutMin = amountsOutMin[1] * (100 ether - slippage) / 100 ether;

            Router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );

            deadline = block.timestamp + 100;
        }
    }

    function getRoute(address from, address to) public returns(address[] memory) {
        if (routeLengths[from][to] == 0) {
            uint8 n = 3;
            address[] memory route = new address[](n);
            route[0] = from;
            route[1] = WETH;
            route[2] = to;
        } else {
            address[] memory route = new address[](routeLengths[from][to]);
            for (uint8 i = 0; i < routeLengths[from][to]; ++i) {
                route[i] = routes[from][to][i];
            } 
            return route;
        } 
    }
}