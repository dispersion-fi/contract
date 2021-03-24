# @version ^0.2.11
"""
@title Uniswap Reaper Strategy V1
@author Dispersion Finance Team
@license MIT
"""


from vyper.interfaces import ERC20
import interfaces.strategies.ReaperStrategy as ReaperStrategy
import interfaces.Staker as Staker
import interfaces.Ownable as Ownable


implements: Ownable
implements: ReaperStrategy


event CommitOwnership:
    owner: address

event ApplyOwnership:
    owner: address


reaper: public(address)
activated: public(bool)

admin: public(address)
owner: public(address)
futureOwner: public(address)


@external
def __init__(_reaper: address):
    assert _reaper != ZERO_ADDRESS, "_reaper is not set"
    self.reaper = _reaper
    self.activated = False
    self.admin = msg.sender
    self.owner = msg.sender


@external
def invest(_amount: uint256):
    assert self.admin == msg.sender
    assert False, "not supported"


@external
def reap() -> uint256:
    assert False, "not supported"
    return 0


@external
def deposit(_amount: uint256):
    assert msg.sender == self.reaper, "reaper only"


@external
def withdraw(_amount: uint256, _account: address):
    assert msg.sender == self.reaper, "reaper only"
    assert self.activated, "not activated"


@external
def claim(_amount: uint256, _account: address):
    assert msg.sender == self.reaper, "reaper only"
    assert self.activated, "not activated"


@view
@external
def availableToDeposit(_amount: uint256, _account: address) -> uint256:
    assert msg.sender == self.reaper, "reaper only"
    return _amount


@view
@external
def availableToWithdraw(_amount: uint256, _account: address) -> uint256:
    assert msg.sender == self.reaper, "reaper only"

    if not self.activated:
        return 0

    return _amount


@external
def transferOwnership(_futureOwner: address):
    """
    @notice Transfers ownership by setting new owner `_futureOwner` candidate
    @dev Callable by owner only
    @param _futureOwner Future owner address
    """
    assert msg.sender == self.owner, "owner only"
    self.futureOwner = _futureOwner
    log CommitOwnership(_futureOwner)


@external
def applyOwnership():
    """
    @notice Applies transfer ownership
    @dev Callable by owner only. Function call actually changes owner
    """
    assert msg.sender == self.owner, "owner only"
    _owner: address = self.futureOwner
    assert _owner != ZERO_ADDRESS, "owner not set"
    self.owner = _owner
    log ApplyOwnership(_owner)
