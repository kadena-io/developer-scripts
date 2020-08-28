(use coin)
(let* ((acct:string "rotest")
       (bal:decimal (coin.get-balance acct))
      )
  (coin.rotate acct (read-keyset "ks"))
  (coin.transfer acct
    "croesus"
    bal)
)
