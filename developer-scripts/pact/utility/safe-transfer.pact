;;Smart Transfer
(coin.transfer-create "alice" "bob" (read-keyset "ks") 200.1)
(coin.transfer "bob" "alice" 0.1)
