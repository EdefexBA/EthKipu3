// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleSwap
/// @author Max Seifert
/// @notice A simplified implementation of a Uniswap-like liquidity pool for two ERC20 tokens.
/// @dev This contract handles tokenA and tokenB liquidity pools and manages internal liquidity tokens.

contract SimpleSwap {

    /// @notice owner Address of the provider of liquidity tokens
    /// @notice Name of the liquidity token
    /// @notice Symbol of the liquidity token
    /// @notice Decimals used for the liquidity token
    /// @notice Address of token A
    /// @notice Address of token B
    /// @notice Current reserve of token A held by the pool
    /// @notice Current reserve of token B held by the pool
    /// @notice Total supply of liquidity tokens minted
    /// @notice Mapping of liquidity token balances per user
    address public owner;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    address public tokenA;
    address public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balanceOf;

    /// @notice Initializes the contract with the two token addresses
    /// @param _tokenA Address of token A
    /// @param _tokenB Address of token B
    constructor(address _tokenA, address _tokenB) {
		tokenA = _tokenA;
		tokenB = _tokenB;
		_name = "SimpleSwap Token";
		_symbol = "SWP";
		_decimals = 18;
		owner = msg.sender;
	}

    /// @notice Emitted when liquidity is added to the pool
    /// @param provider Address of the liquidity provider
    /// @param amountA Amount of token A added
    /// @param amountB Amount of token B added
    /// @param liquidityMinted Amount of liquidity tokens minted
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityMinted);

    /// @notice Emitted when liquidity is removed from the pool
    /// @param provider Address of the liquidity provider
    /// @param amountA Amount of token A returned
    /// @param amountB Amount of token B returned
    /// @param liquidityBurned Amount of liquidity tokens burned
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityBurned);

    /// @notice Emitted when a token swap is performed
    /// @param swapper Address performing the swap
    /// @param tokenIn Address of the token sent in
    /// @param amountIn Amount of token sent
    /// @param tokenOut Address of the token received
    /// @param amountOut Amount of token received
    event TokensSwapped(address indexed swapper, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    /// @notice Returns the name of the liquidity token
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the liquidity token
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the number of decimals used for the liquidity token
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /// @notice Adds liquidity to the pool and mints liquidity tokens
    /// @param tokenA_ address of tokenA
    /// @param tokenB_ address of tokenB
    /// @param amountADesired Amount of token A to add
    /// @param amountBDesired Amount of token B to add
    /// @param amountAMin Minimum accepted amount of token A
    /// @param amountBMin Minimum accepted amount of token B
    /// @param to Address to receive liquidity tokens
    /// @param deadline Transaction expiry timestamp
    /// @return amountA Final amount of token A added
    /// @return amountB Final amount of token B added
    /// @return liquidity Amount of liquidity tokens minted
    function addLiquidity(address tokenA_, address tokenB_, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity) {

		require(deadline > block.timestamp, "Transaction expired");
		require(tokenA_ == tokenA && tokenB_ == tokenB, "Invalid token pair");

		if (reserveA == 0 && reserveB == 0) {
		
			require(msg.sender == owner, "Only owner");
			require(to == owner, "Only owner");

			amountA = 1000 ether;
			amountB = 1000 ether;
			liquidity = 1000 ether;

			IERC20(tokenA).transferFrom(owner, address(this), amountA);
			IERC20(tokenB).transferFrom(owner, address(this), amountB);

			reserveA = amountA;
			reserveB = amountB;
			_totalSupply = liquidity;
			_balanceOf[to] = liquidity;

		} else {
        
			uint256 _reserveA = reserveA;
			uint256 _reserveB = reserveB;

			uint256 amountBOptimal = (amountADesired * _reserveB) / _reserveA;
        
			if (amountBOptimal <= amountBDesired) {
				require(amountBOptimal >= amountBMin, "Insufficient token B");
				amountA = amountADesired;
				amountB = amountBOptimal;
			} else {
				uint256 amountAOptimal = (amountBDesired * _reserveA) / _reserveB;
				require(amountAOptimal <= amountADesired, "Too much token A");
				require(amountAOptimal >= amountAMin, "Not enough token A");
				amountA = amountAOptimal;
				amountB = amountBDesired;
			}

			IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
			IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

            uint liqA = (amountA * _totalSupply) / _reserveA;
            uint liqB = (amountB * _totalSupply) / _reserveB;

            liquidity = liqA;
            if (liquidity > liqB) {
                liquidity = liqB;
            }

			reserveA +=amountA;
			reserveB +=amountB;
			_totalSupply += liquidity;
			_balanceOf[to] += liquidity;

		}

		emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);

		return (amountA, amountB, liquidity);

    }

    /// @notice Removes liquidity from the pool and burns liquidity tokens
    /// @param tokenA_ address of tokenA
    /// @param tokenB_ address of tokenB
    /// @param liquidity amount of liquidity tokens to burn
    /// @param amountAMin Minimum accepted amount of token A
    /// @param amountBMin Minimum accepted amount of token B
    /// @param to Address to receive tokens
    /// @param deadline Transaction expiry timestamp
    /// @return amountA Final amount of token A added
    /// @return amountB Final amount of token B added
    function removeLiquidity (address tokenA_, address tokenB_, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB) {

        require(deadline > block.timestamp, "Transaction expired");
        require(tokenA_ == tokenA && tokenB_ == tokenB, "Invalid token pair");

        amountA = (liquidity * reserveA) / _totalSupply;
        amountB = (liquidity * reserveB) / _totalSupply;

        require(amountA >= amountAMin, "AmountA below minimum");
        require(amountB >= amountBMin, "AmountB below minimum");
        require(_balanceOf[msg.sender] >= liquidity, "Insufficient liquidity");
        require(reserveA >= amountA && reserveB >= amountB, "Insufficient reserves");

        _balanceOf[msg.sender] -=liquidity;
        _totalSupply -=liquidity;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
        reserveA -= amountA;
        reserveB -= amountB;

       emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);

       return (amountA, amountB);

    }

    /// @notice Exchanges one token for another in the exact amount.
    /// @param amountIn Amount of input tokens.
    /// @param amountOutMin: Minimum acceptable number of output tokens.
    /// @param path: Array of token addresses. (input token, output token)
    /// param to: Recipient address.
    /// @param deadline: Timestamp for the transaction.
    /// @return amounts : Array with input and output amounts.
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts) {
        
        require(deadline > block.timestamp, "Transaction expired");
        require(path.length == 2 && path[0] != path[1], "Invalid pair of tokens");
        require((path[0] == tokenA && path[1] == tokenB) || (path[0] == tokenB && path[1] == tokenA), "Invalid token pair");
        require(amountIn > 0, "Insufficient amountIn");

        uint256 amountOut;

        if (path[0] == tokenA) {
            IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
            amountOut = (amountIn * reserveB) / (reserveA + amountIn);
            require(amountOut >= amountOutMin, "Insuficient amountOut");
            IERC20(tokenB).transfer(to, amountOut);
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            IERC20(tokenB).transferFrom(msg.sender, address(this), amountIn);
            amountOut = (amountIn * reserveA) / (reserveB + amountIn);
            require(amountOut >= amountOutMin, "Insuficient amountOut");
            IERC20(tokenA).transfer(to, amountOut); 
            reserveA += amountIn;
            reserveB -= amountOut;
        }
        
        amounts = new uint[](2) ;
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(msg.sender, path[0], amountIn, path[1], amountOut);

        return amounts;

    }

    ///@notice Gets the price of one token in terms of another.
    ///@param tokenA_ Address of the first ERC20 token to calculate a price for.
    ///@param tokenB_ Address of the second ERC20 token to calculate a price for.
    ///@return price Price of tokenA in terms of tokenB
    function getPrice(address tokenA_, address tokenB_) external view returns (uint price) {

        require(
			(tokenA_ == tokenA && tokenB_ == tokenB) || (tokenA_ == tokenB && tokenB_ == tokenA),
			"Invalid token pair");

        uint256 reserveA_ = reserveA;
        uint256 reserveB_ = reserveB;

        require(reserveA_ > 0, "No liquidity for token A");

        return reserveB_ * 10e18 / reserveA_;

    }
    
    ///@notice Gets the amount of token in the swap.
    ///@param amountIn Amount of token A to swap.
    ///@param reserveIn Amount of token A reserves in the contract.
    ///@param reserveOut Amount of token B reserves in the contract.
    ///@return amountOut Amount of tokens B to receive.
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut) {

        require(amountIn > 0, "AmountIn <= 0");
        require(reserveIn > 0 && reserveOut > 0, "Reserves <= 0");

        return (amountIn * reserveOut) / (reserveIn + amountIn);
	
	}

}
