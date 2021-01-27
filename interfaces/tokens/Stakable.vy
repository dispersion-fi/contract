# @version ^0.2.0


event Reward:
    id: uint256
    amount: uint256


@external
def deposit(_account: address, _amount: uint256) -> bool:
    return False


@external
def stake(_reward: uint256) -> bool:
    return False


@external
def withdraw(_account: address) -> bool:
    return False
