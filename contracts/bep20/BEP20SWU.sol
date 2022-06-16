pragma solidity >=0.6.0;

import "./BEP20.sol";

contract BEP20SWU is BEP20 {
    
    uint256 public _feeBurnPct;
    uint256 public _feePlatformPct;
    uint256 public _holdersRewardPct;

    address public _platformRewardAddress;
    address public _holdersRewardAddress;

    event FeesPctUpdated(
        uint256 indexed feeBurnPct,
        uint256 indexed feePlatformPct,
        uint256 indexed holdersRewardPct,
        uint256 oldFeeBurnPct,
        uint256 oldFeePlatformPct,
        uint256 oldHoldersRewardPct
    );
    event PlatformRewardAddressUpdated(
        address indexed platformRewardAddress,
        address indexed oldPlatformRewardAddress
    );
    event HoldersRewardAddressUpdated(
        address indexed holdersRewardAddress,
        address indexed oldHoldersRewardAddress
    );

    constructor() public {}

    /**
     * @dev sets initials supply and the owner
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 amount,
        address owner,
        uint256 feeBurnPct,
        uint256 feePlatformPct,
        uint256 holdersRewardPct,
        address platformRewardAddress,
        address holdersRewardAddress
    ) public initializer {
        _owner = owner;
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _feeBurnPct = feeBurnPct;
        _feePlatformPct = feePlatformPct;
        _holdersRewardPct = holdersRewardPct;
        _platformRewardAddress = platformRewardAddress;
        _holdersRewardAddress = holdersRewardAddress;
        _mint(owner, amount);
    }

    function setFees(
        uint256 feeBurnPct,
        uint256 feePlatformPct,
        uint256 holdersRewardPct
    ) public onlyOwner {
        require(
            feeBurnPct.add(feePlatformPct).add(holdersRewardPct) <= 10000,
            "Fees must not total more than 100%"
        );

        emit FeesPctUpdated(
            feeBurnPct,
            feePlatformPct,
            holdersRewardPct,
            _feeBurnPct,
            _feePlatformPct,
            _holdersRewardPct
        );
        _feeBurnPct = feeBurnPct;
        _feePlatformPct = feePlatformPct;
        _holdersRewardPct = holdersRewardPct;
    }

    function setPlatformRewardAddress(address platformRewardAddress)
        public
        onlyOwner
    {
        require(
            platformRewardAddress != address(0),
            "Address must not be zero address"
        );
        emit PlatformRewardAddressUpdated(
            platformRewardAddress,
            _platformRewardAddress
        );
        _platformRewardAddress = platformRewardAddress;
    }

    function setHoldersRewardAddress(address holdersRewardAddress)
        public
        onlyOwner
    {
        require(
            holdersRewardAddress != address(0),
            "Address must not be zero address"
        );
        emit HoldersRewardAddressUpdated(
            holdersRewardAddress,
            _holdersRewardAddress
        );
        _holdersRewardAddress = holdersRewardAddress;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );

        uint256 feeBurnAmount = 0;

        if (_feeBurnPct > 0) {
            feeBurnAmount = amount.mul(_feeBurnPct).div(10000);

            _totalSupply = _totalSupply.sub(feeBurnAmount);
            emit Transfer(sender, address(0), feeBurnAmount);
        }

        uint256 feePlatformAmount = 0;

        if (_feePlatformPct > 0 && _platformRewardAddress != address(0)) {
            feePlatformAmount = amount.mul(_feePlatformPct).div(10000);

            _balances[_platformRewardAddress] = _balances[
                _platformRewardAddress
            ].add(feePlatformAmount);
            emit Transfer(sender, _platformRewardAddress, feePlatformAmount);
        }

        uint256 feeHoldersAmount = 0;

        if (_holdersRewardPct > 0 && _holdersRewardAddress != address(0)) {
            feeHoldersAmount = amount.mul(_holdersRewardPct).div(10000);

            _balances[_holdersRewardAddress] = _balances[_holdersRewardAddress]
                .add(feeHoldersAmount);
            emit Transfer(sender, _holdersRewardAddress, feeHoldersAmount);
        }

        amount = amount.sub(feeBurnAmount).sub(feePlatformAmount).sub(
            feeHoldersAmount
        );

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}
