# @version ^0.2.0

from vyper.interfaces import ERC20
import interfaces.tokens.ERC20Detailed as ERC20Detailed
import interfaces.tokens.ERC20Burnable as ERC20Burnable
import interfaces.tokens.ERC20Mintable as ERC20Mintable
import interfaces.Ownable as Ownable
import interfaces.tokens.Farmable as Farmable


implements: ERC20
implements: ERC20Detailed
implements: ERC20Burnable
implements: ERC20Mintable
implements: Farmable
implements: Ownable


event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event CommitOwnership:
    owner: address

event ApplyOwnership:
    owner: address

event YearEmissionUpdate:
    newYearEmission: uint256


YEAR: constant(uint256) = 86_400 * 365
DECIMALS: constant(uint256) = 18
INITIAL_SUPPLY: constant(uint256) = 100_000 * 10 ** DECIMALS
INITIAL_YEAR_EMISSION: constant(uint256) = 1_000_000 * 10 ** DECIMALS
EMISSION_REDUCTION_TIME: constant(uint256) = YEAR
EMISSION_REDUCTION_DELIMITER: constant(uint256) = 2


owner: public(address)
futureOwner: public(address)
minter: public(address)

# ERC20
name: public(String[32])
symbol: public(String[8])
balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)
allowance: public(HashMap[address, HashMap[address, uint256]])

startEmissionTimestamp: public(uint256)
lastEmissionUpdateTimestamp: public(uint256)    
_yearEmission: uint256
_emissionIntegral: uint256


@external
def __init__(_name: String[32], _symbol: String[8]):
    self.name = _name
    self.symbol = _symbol
    self.balanceOf[msg.sender] = INITIAL_SUPPLY
    self.totalSupply = INITIAL_SUPPLY
    self.owner = msg.sender
    log Transfer(ZERO_ADDRESS, msg.sender, INITIAL_SUPPLY)


@view
@external
def decimals() -> uint256:
    return DECIMALS


@external
def setName(_name: String[32], _symbol: String[8]):
    assert msg.sender == self.owner, "owner only"
    self.name = _name
    self.symbol = _symbol


@external
def setMinter(_minter: address):
    assert msg.sender == self.owner, "owner only"
    assert _minter != ZERO_ADDRESS, "zero address"
    self.minter = _minter


@internal
def _updateYearEmission() -> uint256:
    _lastEmissionUpdateTimestamp: uint256 = self.lastEmissionUpdateTimestamp
    if _lastEmissionUpdateTimestamp == 0:
        return 0

    futureEmissionUpdateTimestamp: uint256 = _lastEmissionUpdateTimestamp + EMISSION_REDUCTION_TIME
    lastYearEmission: uint256 = self._yearEmission

    if block.timestamp > futureEmissionUpdateTimestamp:
        self._emissionIntegral += lastYearEmission
        self.lastEmissionUpdateTimestamp = futureEmissionUpdateTimestamp
        lastYearEmission /= EMISSION_REDUCTION_DELIMITER
        self._yearEmission = lastYearEmission
        log YearEmissionUpdate(lastYearEmission)

    return lastYearEmission


@internal
def _currentEmissionIntegral() -> uint256:
    currentYearMaxEmission: uint256 = self._updateYearEmission() 
    return self._emissionIntegral + currentYearMaxEmission * (block.timestamp - self.lastEmissionUpdateTimestamp) / YEAR


@external
def mint(_account: address, _amount: uint256):
    assert msg.sender == self.minter, "minter only"
    assert _account != ZERO_ADDRESS, "zero address"

    _totalSupply: uint256 = self.totalSupply
    self.totalSupply = _totalSupply + _amount
    self.balanceOf[_account] += _amount
    assert self._currentEmissionIntegral() + INITIAL_SUPPLY >= _totalSupply + _amount, "exceeds allowable mint amount"
    log Transfer(ZERO_ADDRESS, _account, _amount)


@external
def startEmission():
    assert msg.sender == self.owner, "owner only"
    assert self.lastEmissionUpdateTimestamp == 0, "emission already started"
    self._yearEmission = INITIAL_YEAR_EMISSION
    self.lastEmissionUpdateTimestamp = block.timestamp
    self.startEmissionTimestamp = block.timestamp
    log YearEmissionUpdate(INITIAL_YEAR_EMISSION)


@external
def yearEmission() -> uint256:
    return self._updateYearEmission()


@external
def emissionIntegral() -> uint256:
    return self._currentEmissionIntegral()


@external
def transfer(_recipient : address, _amount : uint256) -> bool:
    assert _recipient != ZERO_ADDRESS, "recipient is zero address"
    self.balanceOf[msg.sender] -= _amount
    self.balanceOf[_recipient] += _amount
    log Transfer(msg.sender, _recipient, _amount)
    return True


@external
def transferFrom(_sender : address, _recipient : address, _amount : uint256) -> bool:
    assert _sender != ZERO_ADDRESS, "sender is zero address"
    assert _recipient != ZERO_ADDRESS, "recipient is zero address"
    
    self.balanceOf[_sender] -= _amount
    self.balanceOf[_recipient] += _amount

    _allowance: uint256 = self.allowance[_sender][msg.sender]
    if _allowance != MAX_UINT256:
        self.allowance[_sender][msg.sender] = _allowance - _amount

    log Transfer(_sender, _recipient, _amount)
    return True


@external
def approve(_spender : address, _amount : uint256) -> bool:
    assert _amount == 0 or self.allowance[msg.sender][_spender] == 0, "already approved"
    self.allowance[msg.sender][_spender] = _amount
    log Approval(msg.sender, _spender, _amount)
    return True


@external
def burn(_amount: uint256):
    self.totalSupply -= _amount
    self.balanceOf[msg.sender] -= _amount
    log Transfer(msg.sender, ZERO_ADDRESS, _amount)


@external
def transferOwnership(_futureOwner: address):
    assert msg.sender == self.owner, "owner only"
    self.futureOwner = _futureOwner
    log CommitOwnership(_futureOwner)


@external
def applyOwnership():
    assert msg.sender == self.owner, "owner only"
    _owner: address = self.futureOwner
    assert _owner != ZERO_ADDRESS, "owner not set"
    self.owner = _owner
    log ApplyOwnership(_owner)
