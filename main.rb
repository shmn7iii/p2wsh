require 'bitcoin'
require_relative 'lib/p2wsh'
require_relative 'fixtures'

include Bitcoin
include Bitcoin::Opcodes

Bitcoin.chain_params = :signet

P2wsh.default_fee = 0.00002
P2wsh.rpc_config = {
  schema: 'http',
  host: 'localhost',
  port: 38332,
  user: 'hoge',
  password: 'hoge'
}


# 送金
# ========================================
multisig_transaction = P2wsh::MultisigTransaction.new
locked_tx = multisig_transaction.send(amount: 0.0001, m: 2, pubkeys: [$pub_alice, $pub_bob, $pub_carol])


# 情報の受け渡し
# ========================================
locked_tx_txid = locked_tx.tx.txid
puts "locked_tx_txid = '#{locked_tx_txid}'"

redeem_script_hex = locked_tx.redeem_script.to_hex
puts "redeem_script_hex = '#{redeem_script_hex}'"


# アンロック
# ========================================
multisig_transaction = P2wsh::MultisigTransaction.new(txid: locked_tx_txid, redeem_script_hex:)
unlocked_tx = multisig_transaction.unlock(address: $alice, keys: [$key_alice, $key_bob])

unlocked_tx_txid = unlocked_tx.txid
puts "unlocked_tx_txid = '#{unlocked_tx_txid}'"
