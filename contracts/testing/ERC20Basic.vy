# @version ^0.2.0

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: HashMap[address, HashMap[address, uint256]]
totalSupply: uint256

minter: public(address)
owner: public(address)
future_owner: public(address)


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals

    init_supply: uint256 = _supply * 10 ** _decimals
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.minter = msg.sender
    self.owner = msg.sender

    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)


@external
def transfer(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def setMinter(_minter: address) -> bool:
    assert msg.sender == self.minter
    self.minter = _minter
    
    return True


@external
def mint(account: address, amount: uint256) -> bool:
    assert msg.sender == self.minter
    assert account != ZERO_ADDRESS

    self.totalSupply += amount
    self.balanceOf[account] += amount
    log Transfer(ZERO_ADDRESS, account, amount)
    
    return True


@external
def burn(amount: uint256) -> bool:
    self.totalSupply -= amount
    self.balanceOf[msg.sender] -= amount
    log Transfer(msg.sender, ZERO_ADDRESS, amount)

    return True


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