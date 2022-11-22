module P2wsh
  class MultisigTransaction
    attr_accessor :tx, :redeem_script

    # @param [String] txid トランザクションID
    # @param [String] redeem_script_hex RedeemScriptのHEX
    def initialize(txid: nil, redeem_script_hex: nil)
      @tx = txid ? Bitcoin::Tx.parse_from_payload(P2wsh.client.getrawtransaction(txid).htb) : nil
      @redeem_script = redeem_script_hex ? Bitcoin::Script.parse_from_payload(redeem_script_hex.htb) : nil
    end

    # 送金
    # @param [Integer] amount 送金金額
    # @param [Integer] m アンロックに必要な公開鍵の数
    # @param [Array] pubkeys n個の公開鍵の配列
    # @return [MultisigTransaction]
    def send(amount:, m:, pubkeys:)
      raise ArgumentError, 'Arg `m` must be greater than lengh of pubkeys' if m > pubkeys.size

      @redeem_script = Bitcoin::Script.to_multisig_script(m, pubkeys)
      @tx = create_p2wsh_tx(amount:, redeem_script: @redeem_script)

      P2wsh.client.sendrawtransaction(@tx.to_hex)

      self
    end

    # アンロック
    # @param [String] address アンロックした資金の送金先アドレス
    # @param [Array] keys 署名鍵の配列
    # @return [Transaction] アンロックしたトランザクション
    def unlock(address:, keys:)
      raise ArgumentError, 'Initialize instance with argument: txid' if @tx.nil?
      raise ArgumentError, 'Initialize instance with argument: redeem_script_hex' if @redeem_script.nil?

      locked_txid = @tx.txid
      redeem_script = @redeem_script

      p2wsh_tx = unlock_p2wsh_tx(locked_txid:, redeem_script:, address:, keys:)

      P2wsh.client.sendrawtransaction(p2wsh_tx.to_hex)

      p2wsh_tx
    end

    private

    # P2WSHトランザクションの構成
    # @param [Integer] amount 送金金額
    # @param [Bitcoin::Script] redeem_script RedeemScript
    # @return [Bitcoin::Transaction] ロックしたトランザクション（未送信）
    def create_p2wsh_tx(amount:, redeem_script:)
      utxos = P2wsh.consuming_utxos(amount:, fee: P2wsh.default_fee)

      tx = Bitcoin::Tx.new
      tx = P2wsh.make_inputs(tx:, utxos:)
      tx = P2wsh.make_outputs(tx:, amount:,
                              address: Bitcoin::Script.to_p2wsh(redeem_script).to_addr,
                              change: utxos.map { |utxo| utxo['amount'].to_f }.sum - amount - P2wsh.default_fee,
                              change_addr: utxos[0]['address'])

      tx = P2wsh.sign_transaction(tx:)
    end

    # P2WSHトランザクションのアンロック
    # @param [String] locked_txid ロックされたトランサクションのTXID
    # @param [String] address アンロックした資金の送金先アドレス
    # @param [Array] keys 署名鍵の配列
    # @return [Bitcoin::Transaction] アンロックしたトランザクション（未送信）
    def unlock_p2wsh_tx(locked_txid:, redeem_script:, address:, keys:)
      locked_tx = Bitcoin::Tx.parse_from_payload(P2wsh.client.getrawtransaction(locked_txid).htb)
      locked_utxo_vout = 0
      locked_utxo_value = locked_tx.out[locked_utxo_vout].value

      p2wsh_tx = Bitcoin::Tx.new
      p2wsh_tx.in <<  Bitcoin::TxIn.new(out_point: Bitcoin::OutPoint.from_txid(locked_txid, locked_utxo_vout))
      p2wsh_tx.out << Bitcoin::TxOut.new(value: locked_utxo_value - (P2wsh.default_fee * (10**8)).to_i, script_pubkey: Bitcoin::Script.parse_from_addr(address))

      sighash = p2wsh_tx.sighash_for_input(0, redeem_script, sig_version: :witness_v0, amount: locked_utxo_value, hash_type: Bitcoin::SIGHASH_TYPE[:all])
      p2wsh_tx.in[0].script_witness.stack << ''
      keys.each do |key|
        sig = key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
        p2wsh_tx.in[0].script_witness.stack << sig
      end
      p2wsh_tx.in[0].script_witness.stack << redeem_script.to_payload

      p2wsh_tx
    end
  end
end
