(use util.guards1) 
(coin.create-account "gas-station" 
    (guard-all [ 
        (create-user-guard (coin.gas-only)) 
        (max-gas-price 0.00000001) 
        (max-gas-limit 400) ]))

