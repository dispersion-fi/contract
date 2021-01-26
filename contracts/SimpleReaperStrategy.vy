# @version ^0.2.0


import interfaces.strategies.ReaperStrategy as ReaperStrategy
import interfaces.Ownable as Ownable


implements: Ownable
implements: ReaperStrategy


event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address


DEFAULT_BOOST_RATE: constant(uint256) = 10 ** 18


owner: public(address)
future_owner: public(address)
reaper: public(address)
boost_rate: public(uint256)


@external
def __init__(_reaper: address):
    self.reaper = _reaper
    self.boost_rate = DEFAULT_BOOST_RATE
    self.owner = msg.sender


@external
def deposit(amount: uint256, account: address) -> uint256:
    return amount


@external
def withdraw(amount: uint256, account: address) -> uint256:
    return amount


@external
@nonreentrant('lock')
def invest(): 
    pass


@external
@nonreentrant('lock')
def reap(): 
    pass


@external
def transferOwnership(_future_owner: address):
    assert msg.sender == self.owner, "owner only"

    self.future_owner = _future_owner
    log CommitOwnership(_future_owner)


@external
def applyOwnership():
    assert msg.sender == self.owner, "owner only"
    _owner: address = self.future_owner
    assert _owner != ZERO_ADDRESS, "owner not set"
    self.owner = _owner
    log ApplyOwnership(_owner)
