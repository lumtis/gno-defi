package wgnot

import (
	"std"
	"strings"

	"gno.land/p/grc/grc20"
	"gno.land/p/ufmt"
	"gno.land/r/users"
)

const (
	GNOT_DENOM = "ugnot"
)

var (
	wgnot *grc20.Token
)

func init() {
	wgnot = grc20.NewToken("Wrapped Gnot", "WGNOT", 6)
}

// method proxies as public functions.
//

// getters.

func TotalSupply() uint64 {
	return wgnot.TotalSupply()
}

func BalanceOf(owner users.AddressOrName) uint64 {
	return wgnot.BalanceOf(owner.Resolve())
}

func Allowance(owner, spender users.AddressOrName) uint64 {
	return wgnot.Allowance(owner.Resolve(), spender.Resolve())
}

// setters.

func Transfer(to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	wgnot.Transfer(caller, to.Resolve(), amount)
}

func Approve(spender users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	wgnot.Approve(caller, spender.Resolve(), amount)
}

func TransferFrom(from, to users.AddressOrName, amount uint64) {
	caller := std.GetCallerAt(2)
	wgnot.TransferFrom(caller, from.Resolve(), to.Resolve(), amount)
}

// mint WGNOT from deposited GNOT

func Deposit() {
	caller := std.GetCallerAt(2)
	sent := std.GetOrigSend()
	if len(sent) != 1 || sent[0].Denom != GNOT_DENOM {
		panic("gnot must be sent")
	}
	if sent[0].Amount <= 0 {
		panic("invalid sent amount")
	}
	wgnot.Mint(caller, uint64(sent[0].Amount))
}

// withdraw WGNOT to GNOT

func Withdraw(amount int64) {
	if amount <= 0 {
		panic("invalid amount")
	}
	banker := std.GetBanker(std.BankerTypeRealmSend)
	caller := std.GetCallerAt(2)
	pkgaddr := std.GetOrigPkgAddr()
	banker.SendCoins(pkgaddr, caller, std.Coins{{GNOT_DENOM, amount}})
	wgnot.Burn(caller, uint64(amount))
}

func GetGRC20() *grc20.Token {
	return wgnot
}

// render.
//

func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		return wgnot.RenderHome()
	case c == 2 && parts[0] == "balance":
		owner := users.AddressOrName(parts[1])
		balance := wgnot.BalanceOf(owner.Resolve())
		return ufmt.Sprintf("%d\n", balance)
	default:
		return "404\n"
	}
}
