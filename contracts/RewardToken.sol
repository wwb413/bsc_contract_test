pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is IERC20,Context,Ownable{

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    // customize to lock reward 70% and release in 30days
    uint256 private _rewardLock = 7000; // lock 70%
    uint256 private _totalBlockRelease = 30 * 24 * 60 * 60 / 5; // BKC Blocktime 5 sec
    mapping(address => uint256) private _balancesLock;
    mapping(address => uint256) private _rewardPerBlock;
    mapping(address => uint256) private _lastClaimBlock;
    mapping(address => uint256) private _endClaimBlock;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    uint256 private _cap = 101051200e18; //101,051,200

    function cap() public view returns (uint256) {
        return _cap;
    }

    // @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        require(totalSupply().add(_amount) <= cap(), "cap exceeded");
        _mint(_to, _amount);
        return true;
    }
    
    function mint(uint256 _amount) public onlyOwner returns (bool) {
        require(totalSupply().add(_amount) <= cap(), "cap exceeded");
        _mint(_msgSender(), _amount);
        return true;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero'));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }
    
    /**
     * Harvest reward holding system (Algorithm sarun release)
     * 
     * After Harvest, you will get the rewards as following:
     * - 30% of your rewards will return to your wallet immediately. 
     * - 70% of your remaining rewards must be divided by 7 days and remaining reward renew to 7 days everytime reward harvested again.
     */
     
    // onlyOwner is MasterChef can setRewardLock 
    function setRewardLock(uint256 lock) public onlyOwner {
        require(lock <= 10000, "lock: invalid reward lock");
        _rewardLock = lock;
    }
    
    // onlyOwner is MasterChef can setTotalBlockRelease
    function setTotalBlockRelease(uint256 totalBlockRelease) public onlyOwner {
        _totalBlockRelease = totalBlockRelease;
    }
    
    // onlyOwner is MasterChef to transferWithLock
    function transferWithLock(address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0, "amount: invalid amount");

        _transferWithLock(_msgSender(), recipient, amount);
        return true;
    }

    function _transferWithLock (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');
        
        // claim locked reward
         _claimRewardLock(recipient);
        
        uint256 _amountLock = amount.mul(_rewardLock).div(10000); // 70%
        uint256 _amount = amount.sub(_amountLock, 'BEP20: transfer amount exceeds balance'); // 30%

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(_amount);
        
        // update lock balance
        _balancesLock[recipient] = _balancesLock[recipient].add(_amountLock);
        _lastClaimBlock[recipient] = block.number;
        _endClaimBlock[recipient] = block.number.add(_totalBlockRelease); // renew last claim block
        _rewardPerBlock[recipient] = _balancesLock[recipient].mul(10000).div(_totalBlockRelease);
        
        emit Transfer(sender, recipient, amount);
    }
    
    function claimRewardLock() public {
        _claimRewardLock(_msgSender());
    }
    
    function _claimRewardLock(address account) internal {
        uint256 release = getRewardLockToClaim(account);
        if (release > 0) {
            uint256 remain = _balancesLock[account].sub(release);
            if (_endClaimBlock[account] < block.number) {
                _balances[account] = _balances[account].add(_balancesLock[account]);
                _balancesLock[account] = 0;
            } else {
                _balances[account] = _balances[account].add(release);
                _balancesLock[account] = remain;
            }
            
            // set last claim block
            _lastClaimBlock[account] = block.number;
        }
    }
    
    function getRewardLockToClaim(address account) public view returns (uint256) {
        if (block.number > _endClaimBlock[account]) {
            return _balancesLock[account];
        } else {
            return (block.number.sub(_lastClaimBlock[account])).mul(_rewardPerBlock[account]).div(10000);
        }
    }
    
    function getTotalRewardLock(address account) public view returns (uint256) {
        return _balancesLock[account];
    }
    
    function getLastClaimBlock(address account) public view returns (uint256) {
        return _lastClaimBlock[account];
    }
    
    function getEndClaimBlock(address account) public view returns (uint256) {
        return _endClaimBlock[account];
    }

}