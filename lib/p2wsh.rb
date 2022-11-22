module P2wsh
  require_relative 'p2wsh/multisig_transaction'
  require_relative 'p2wsh/util'

  extend Util

  @default_fee = 0.00002

  def self.default_fee=(fee)
    @default_fee = fee.to_f
  end

  def self.default_fee
    @default_fee
  end

  def self.rpc_config=(hash)
    @rpc_config = hash
  end

  def self.rpc_config
    @rpc_config
  end

  def self.client
    raise StandardError, 'Set rpc_config with P2wsh.rpc_donfig={...}' if @rpc_config.nil?

    @client ||= Bitcoin::RPC::BitcoinCoreClient.new(@rpc_config)
  end
end
