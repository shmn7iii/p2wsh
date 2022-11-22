module P2wsh
  module Util
    # 送金金額＋手数料をぎりぎり上回るUTXOリストの作成
    # @params [Float] amount 送金金額
    # @params [Float] fee 手数料
    # @return [Array] UTXOの配列
    def consuming_utxos(amount:, fee: P2wsh.default_fee)
      unspent = P2wsh.client.listunspent
      unspent.select! { |t| t['spendable'] == true }

      spendable_amount = unspent.map { |utxo| utxo['amount'].to_f }.sum
      raise ArgumentError, 'Insufficient funds' if spendable_amount < (amount + fee)

      unspent.sort_by! { |x| x['amount'] }

      utxos = []
      unspent.each do |tx|
        utxos << tx
        balance = utxos.reduce(0) { |s, t| s + t['amount'].to_f }
        break if balance >= amount + fee
      end

      utxos
    end

    # トランザクションのinputの構成
    # @params [Bitcoin::Transaction] tx 対象トランザクション
    # @params [Array] utxos 利用するUTXOの配列
    # @return [Bitcoin::Transaction] トランザクション
    def make_inputs(tx:, utxos:)
      utxos.each do |utxo|
        outpoint = Bitcoin::OutPoint.from_txid(utxo['txid'], utxo['vout'])
        tx.in << Bitcoin::TxIn.new(out_point: outpoint)
      end

      tx
    end

    # トランザクションのoutputの構成
    # @params [Bitcoin::Transaction] tx 対象トランザクション
    # @params [Float] amount 送金金額
    # @params [String] address 送金先アドレス
    # @params [Float] change おつり金額
    # @params [String] change_addr おつりの送金先アドレス
    # @return [Bitcoin::Transaction] トランザクション
    def make_outputs(tx:, amount:, address:, change:, change_addr:)
      amount_satoshi = (amount * (10**8)).to_i
      change_satoshi = (change * (10**8)).to_i

      tx.out << Bitcoin::TxOut.new(value: amount_satoshi, script_pubkey: Bitcoin::Script.parse_from_addr(address))
      tx.out << Bitcoin::TxOut.new(value: change_satoshi, script_pubkey: Bitcoin::Script.parse_from_addr(change_addr))

      tx
    end

    # トランザクションへ署名
    # @params [Bitcoin::Transaction] tx 対象トランザクション
    # @return [Bitcoin::Transaction] トランザクション
    def sign_transaction(tx:)
      tx.in.each_with_index do |input, index|
        source_tx_output = Bitcoin::Tx.parse_from_payload(P2wsh.client.getrawtransaction(input.out_point.txid).htb).out[input.out_point.index]
        key = Bitcoin::Key.from_wif(P2wsh.client.dumpprivkey(source_tx_output.script_pubkey.to_addr))
        sig_hash = tx.sighash_for_input(index, source_tx_output.script_pubkey,
                                        sig_version: :witness_v0, amount: source_tx_output.value)
        signature = key.sign(sig_hash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
        input.script_witness.stack << signature
        input.script_witness.stack << key.pubkey.htb
      end

      tx
    end
  end
end
