extends Node

var current_round: int = 1
var current_coins: int = 0
var owned_relics: Array[String] = []


func reset_run() -> void:
	current_round = 1
	current_coins = 0
	owned_relics.clear()


func has_relic(relic_id: String) -> bool:
	return relic_id in owned_relics


func try_spend_coins(amount: int) -> bool:
	if amount <= 0 or current_coins < amount:
		return false
	current_coins -= amount
	return true


func add_relic(relic_id: String) -> bool:
	if relic_id.is_empty() or has_relic(relic_id):
		return false
	owned_relics.append(relic_id)
	return true


# 商店交易必须同时满足「未拥有」和「余额足够」两个条件，避免 UI 重复点击时
# 分别扣款、加遗物而造成状态不一致。
func try_purchase_relic(relic_id: String, price: int) -> bool:
	if relic_id.is_empty() or price <= 0:
		return false
	if has_relic(relic_id) or current_coins < price:
		return false

	current_coins -= price
	owned_relics.append(relic_id)
	return true
