// SPDX-License-Identifier: MIT
// Corenium Idea Coin
// OpenZeppelin Contracts (last updated v5.0.0)
// FLS 101010 110302 010305

pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 * Extended version of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;

    uint256 private _reward;
    uint256 private _nextHalvingSupply;
    uint256 private _totalSupply;

    uint256 private immutable _cap;
    address payable private immutable _fawkes;

    event TheOverture(uint256 reward);
    event NowTheBrass(uint256 newReward);
    event HereComesTheCrescendo(address indexed from, address indexed to, uint256 newNextHalvingSupply);
    event RememberRememberHowBeautifulIsItNot();
    
    /**
     * @dev The address is not fawkes.
     */
    error GunpowderTreason(address msgSender);

    /**
     * @dev Its all over. Cant burn anymore.
     * “No one will ever forget that night, and what it meant for cryptocurrency.
     *  But I will never forget the man and what he meant to me.”
     */
    error NoOneWillEverForgetThatNight();

    /**
     * @dev Sets the values for {name}, {symbol}, {reward} and {cap}.
     *
     * {name}, {symbol} and {cap} values are immutable:
     * they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_, uint256 reward_, uint256 cap_) {
        _name = name_;
        _symbol = symbol_;
        _reward = reward_;
        _cap = cap_;
        _nextHalvingSupply = cap_ / 2;
        _fawkes = payable(_msgSender());
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev Returns the current reward.
     */
    function reward() public view virtual returns (uint256) {
        return _reward;
    }

    /**
     * @dev Returns the next halving supply.
     */
    function nextHalvingSupply() public view virtual returns (uint256) {
        return _nextHalvingSupply;
    }

    /**
     * @dev Returns the fawkes address.
     * Alan Moore’s philosophy
     * If you wish to develop as a writer/(whatever you want to be)
     * you will have to also develop as a person.
     * I would suggest that you will need
     * to develop a moral standpoint
     */
    function fawkes() internal view virtual returns (address payable) {
        return _fawkes;
    }

    /**
     * @dev Throws if called by any account other than the fawkes.
     */
    modifier onlyFawkes() {
        _checkFawkes();
        _;
    }

    /**
     * @dev Throws if the sender is not the fawkes.
     */
    function _checkFawkes() internal view virtual {
        if (fawkes() != _msgSender()) {
            revert GunpowderTreason(_msgSender());
        }
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    receive() external payable {}
    fallback() external payable {}

    /**
     * @dev Function to reclaim native token.
     */
    function reclaimNative() external onlyFawkes{
        uint256 amount = address(this).balance;
        (bool success,) = fawkes().call{value: amount}("");
        require(success, "Reclaim Failed");
    }

    /**
     * @dev Function to reclaim all IERC20 compatible tokens
     * @param tokenAddress address The address of the token contract
     */
    function reclaimToken(address tokenAddress) external onlyFawkes {
        require(tokenAddress != address(0), "Token cannot be 0x0");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(fawkes(), balance), "Reclaim Token Failed");
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 value) external virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 value) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 value) external virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev returns current reward for the transfer.
     * No reward if `from` and `to` are same. No reward if `from` or `to` is fawkes.
     * Halves if supply reaches next halving
     *
     * Emits a {NowTheBrass} event if halving occurred or completed.
     * Emits a {HereComesTheCrescendo} event if halving occurred.
     * Emits a {RememberRememberHowBeautifulIsItNot} event if minted supply reaches cap.
     */
    function currentReward(address from, address to) internal virtual returns (uint256){
        uint256 rewardValue = reward();
        if (rewardValue == 0) {
            return rewardValue;
        }
        if (from == to || from == fawkes() || to == fawkes()) {
            return 0;
        }

        uint256 maxSupply = cap();
        uint256 mintedSupply = totalSupply() + (rewardValue * 3);
        if (mintedSupply > maxSupply) {
            _reward = rewardValue = 0;
            emit NowTheBrass(rewardValue);
            emit RememberRememberHowBeautifulIsItNot();
            return rewardValue;
        }

        uint256 nextHalvingSupplyValue = nextHalvingSupply();
        if (mintedSupply > nextHalvingSupplyValue) {
            _nextHalvingSupply = nextHalvingSupplyValue =
                nextHalvingSupplyValue +
                ((maxSupply - nextHalvingSupplyValue) / 2);
            emit HereComesTheCrescendo(from, to, nextHalvingSupplyValue);
            rewardValue = rewardValue / 2;
            if (rewardValue == 0) {
                rewardValue = 1;
            }
            _reward = rewardValue;
            emit NowTheBrass(rewardValue);
            return rewardValue;
        }

        return rewardValue;
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`
     * 
     * Emits a {Transfer} event.
     * Emits a {TheOverture} event if reward > 0.
     */
     function _update(address from, address to, uint256 value) internal virtual {
        uint256 fromBalance = _balances[from];
        if (fromBalance < value) {
            revert ERC20InsufficientBalance(from, fromBalance, value);
        }

        uint256 currentRewardValue = currentReward(from, to);
        uint256 toBalance = _balances[to];
        if (currentRewardValue == 0) {
            if (from != to) {
                unchecked {
                    _balances[from] = fromBalance - value;
                    _balances[to] = toBalance + value;
                }
            }//else (from=to) { no balance change }
        } else {
            uint256 fawkesBalance = _balances[fawkes()];
            unchecked {
                _balances[from] = fromBalance + currentRewardValue - value;
                _balances[to] = toBalance + currentRewardValue + value;
                _balances[fawkes()] = fawkesBalance + currentRewardValue;
                _totalSupply = _totalSupply + (currentRewardValue * 3);
            }
            emit TheOverture(currentRewardValue);
        }
        emit Transfer(from, to, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `_msgSender`.
     * Lowering the total supply. Reward will not change.
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(uint256 value) external virtual  {
        if (reward() == 0) {
            revert NoOneWillEverForgetThatNight();
        }
        uint256 fromBalance = _balances[_msgSender()];
        if (fromBalance < value) {
            revert ERC20InsufficientBalance(_msgSender(), fromBalance, value);
        }
        unchecked {
            _balances[_msgSender()] = fromBalance - value;
            _totalSupply = _totalSupply - value;
        }
        emit Transfer(_msgSender(), address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

/**
 * @dev shangai compiler: 0.8.22 optimization: 999888000
 */
contract ICETH is ERC20Capped {
    constructor()
        ERC20Capped(
            "Idea Coin on Ethereum",
            "ICETH",
            50 * (10**decimals()),
            210 * (10**6) * (10**decimals())
        )
    {}
}
