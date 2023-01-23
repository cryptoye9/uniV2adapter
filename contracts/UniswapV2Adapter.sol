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

    error ZeroAddress();

    constructor(address _router, address _WETH) public {
        if (_router == address(0) || _WETH == address(0)) revert ZeroAddress();

        Router = IUniswapV2Router02(_router);
        WETH = _WETH;
    }

    function setRoute(address tokenFrom, address tokenTo, address[] memory route) external onlyOwner {
        routes[tokenFrom][tokenTo] = route;

        //console.log(routes[tokenFrom][tokenTo]);
        //console.log(routes[tokenTo][tokenFrom]);

        //uint8 reverseIndex = uint8(route.length);
        //routes[tokenTo][tokenFrom][0] = address(0);
    }

    function swap(address tokenFrom, uint256 amountToSwap, address tokenTo, uint256 slippage) external {
        address[] memory route = routes[tokenFrom][tokenTo];

        SafeERC20.safeTransferFrom(
            IERC20(tokenFrom), msg.sender, address(this), amountToSwap
        );

        if (route.length == 0) {
            route[0] = tokenFrom;
            route[1] = WETH; 
            route[2] = tokenTo;
        }

        uint256 balanceBeforeSwap = IERC20(tokenTo).balanceOf(address(this));
        _swap(tokenFrom, amountToSwap, tokenTo, route, slippage);
        uint256 amountToSend = IERC20(tokenTo).balanceOf(address(this)) - balanceBeforeSwap;
        IERC20(tokenTo).safeTransfer(msg.sender, amountToSend);
    }

    function _swap(
        address tokenFrom, 
        uint256 amountToSwap, 
        address tokenTo,
        address[] memory route,
        uint256 slippage
    ) private {
        uint256 amountIn = amountToSwap;
        address to = address(this);
        uint256 deadline = block.timestamp + 100;
        address[] memory path;

        for (uint8 i = 0; i < route.length - 1; ++i) {
            path[0] = route[i];
            path[1] = route[i + 1];
            uint256[] memory amountsOutMin = Router.getAmountsOut(amountIn, path);
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
}