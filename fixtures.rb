Bitcoin.chain_params = :signet

# テスト用アカウントと鍵
$key_alice = Bitcoin::Key.from_wif('cTzEHTNYQQ2PGLJWFkXdpxHm3B8kuU7yN3c5b5ZkSWzUY6j3ZW5B')
$key_bob   = Bitcoin::Key.from_wif('cUTymPpf51Y1Q8hddD93kSqVahkdFQJXWCuMgY8ctHJqbermrXPK')
$key_carol = Bitcoin::Key.from_wif('cRaww9WmBUogesd6vEBBi4A24yZdxSMQT75FJ9ZQTqWtpRJSTG2f')
$key_david = Bitcoin::Key.from_wif('cSHFCDprZSsp423BG8brHReK7FG4CNifJYZvgcZ6N6QchcxEgyDp')

## アドレス
$alice = $key_alice.to_p2wpkh
$bob   = $key_bob.to_p2wpkh
$carol = $key_carol.to_p2wpkh
$david = $key_david.to_p2wpkh

# 公開鍵
$pub_alice = $key_alice.pubkey
$pub_bob   = $key_bob.pubkey
$pub_carol = $key_carol.pubkey
$pub_david = $key_david.pubkey
