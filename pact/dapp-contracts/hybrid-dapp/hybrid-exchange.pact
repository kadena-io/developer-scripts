(namespace "user")
(module hybrid-exchange GOVERNANCE

  (defcap GOVERNANCE ()
    (enforce-guard (at 'guard (details 'contract-admins))))

  (use coin)

  (defschema hybrid-schema
    ht-balance:decimal
    coins-in:decimal
    coins-out:decimal
    ht-account:bool
    req-history:[string]
  )

  (defschema tx-schema
    account:string
    amount:decimal
    status:string
    time:string
  )

  (deftable hybrid-table-2:{hybrid-schema})
  (deftable txs-table-2:{tx-schema})

  (defconst TX_OPEN:string "open")
  (defconst TX_COMPLETE:string "complete")
  (defconst TX_REFUNDED:string "rejected")

  ;TOTAL SUPPLY 1 million tokens
  (defconst TOTAL_SUPPLY:decimal 1000000.0)

  ;module-guard account
  (defconst ADMIN_ACCOUNT:string "hybrid-mg")
  (defun ht-guard:guard () (create-module-guard ADMIN_ACCOUNT))


;need to figure out this admin stuff after
  (defcap ADMIN ()
    "makes sure only contract owner can make important function calls"
    (enforce-guard (at 'guard (coin.details 'hybrid-admin)))
  )

  (defcap REGISTERED_USER (account:string)
    "makes sure user's guard matches"
    ;true
    (enforce-guard (at 'guard (coin.details account)))
  )


  (defun buy-ht (account:string amount:decimal)
    @doc "way for user to buy hybrid token with kadena coin \
    \ debits user, credits module-guard"
    ;also enforces amount is pos, and user has the funds
    ;and that his guard matches the account name
    (coin.transfer account ADMIN_ACCOUNT amount)
    (with-default-read hybrid-table-2 account
      ;{"guard": (at 'guard (coin.account-info account)),
      ;placeholder!!!!!!!!!!!!!
      ;{"guard": (ht-guard), ;;WARNING!!!! TO BE CHANGED!!!!!
      ;change above!!!!!!!
      {"ht-balance": 0.0,
      "coins-in": 0.0,
      "coins-out": 0.0,
      "ht-account": false,
      "req-history": []}
      ;{"guard":= guard-user,
      {"ht-balance":= ht-balance-user,
      "coins-in":= coins-in-user,
      "coins-out":= coins-out-user,
      "ht-account":= ht-account,
      "req-history" := req-history}
      (with-read hybrid-table-2 "admin"
        {"coins-in":= coins-in-admin,
        "ht-balance":= ht-balance-admin}

      ;make sure we have enough tokens left!
      (enforce (<= amount ht-balance-admin) "sorry there are not enough tokens available")

      (write hybrid-table-2 account
        ;{"guard": guard-user,
        {"ht-balance": (+ ht-balance-user amount),
        "coins-in": (+ coins-in-user amount),
        "coins-out": coins-out-user,
        "ht-account": ht-account,
        "req-history": req-history})
      (update hybrid-table-2 "admin"
        {"coins-in": (+ coins-in-admin amount),
        "ht-balance": (- ht-balance-admin amount)})
      )
    )
  )

  (defun sell-ht (account:string amount:decimal)
    @doc "way for user to sell hybrid token for kadena coin \
    \ debits module guard, credits user"
    (with-capability (REGISTERED_USER account)
      (with-read hybrid-table-2 account
        {"ht-balance":= ht-balance-user,
        "coins-out":= coins-out-user}
        (enforce (>= ht-balance-user amount) "amount must be less than your current balance")
        ;;transfer the money (already checks amount is positive in coin)
        (coin.transfer ADMIN_ACCOUNT account amount)
      (with-read hybrid-table-2 "admin"
        {"ht-balance":= ht-balance-admin,
        "coins-out":= coins-out-admin}
        (update hybrid-table-2 account
          {"ht-balance": (- ht-balance-user amount),
          "coins-out": (+ coins-out-user amount)}
        )
        (update hybrid-table-2 "admin"
          {"ht-balance": (+ ht-balance-admin amount),
          "coins-out": (+ coins-out-admin amount)}
        )
      ))
    )
  )

  (defun trans-to-priv (account:string amount:decimal)
    @doc "user calls this when wanting to transfer hybrid token \
    \ to Kuro private network"
    (with-capability (REGISTERED_USER account)
      (with-read hybrid-table-2 account
        {"ht-balance":= balance-user,
         "ht-account":= ht-account}
        (enforce (>= balance-user amount) "amount must be less than your current balance")
        (enforce (> amount 0.0) "amount must be positive")
        (debit-ht-user account amount)
        ;;create a uniqueID -> account + timestamp
        (let* ((ts (format-time "%Y-%m-%d%H:%M:%S.%v" (at "block-time" (chain-data))))
          (id (format "{}-{}" [account, ts])))
          (insert txs-table-2 id
            { "account": account,
              "amount": amount,
              "status": TX_OPEN,
              "time": ts })
            (with-read hybrid-table-2 account
              {"req-history":= req-history}
              ; (if ht-account
              ; (update hybrid-table-2 account
              ; {"req-history": (+ req-history [ts])}))
              (update hybrid-table-2 account
                {"ht-account": true,
                 "req-history": (+ req-history [ts])}))
            ;return some info to user
            (format "Confirmation that your request ({}) is being processed..." [id])
          )))
  )
  
  (defun credit-ht (account:string amount:decimal)
    @doc "ADMIN ONLY: credit user account with amount \
    \ used for incoming tokens FROM Kuro"
    (with-capability (ADMIN)
      (with-read hybrid-table-2 account
        {"ht-balance":= balance-user}
        (with-read hybrid-table-2 "admin"
          {"ht-balance":= balance-admin}
          (update hybrid-table-2 account
            {"ht-balance": (+ balance-user amount)})
          (update hybrid-table-2 "admin"
            {"ht-balance": (- balance-admin amount)})
        )
      )
    )
  )

  (defun debit-ht (account:string amount:decimal)
    @doc "ADMIN ONLY: debit user account with amount \
    \ of token to be moved TO Kuro"
    (with-capability (ADMIN)
      (with-read hybrid-table-2 account
        {"ht-balance":= balance-user}
        (with-read hybrid-table-2 "admin"
          {"ht-balance":= balance-admin}
          (enforce (>= balance-user amount) "user does not have enough balance")
          (update hybrid-table-2 account
            {"ht-balance": (- balance-user amount)})
          (update hybrid-table-2 "admin"
            {"ht-balance": (+ balance-admin amount)})
        )
      )
    )
  )

  (defun debit-ht-user (account:string amount:decimal)
    @doc "ADMIN ONLY: debit user account with amount \
    \ of token to be moved TO Kuro"
    (require-capability (REGISTERED_USER account))
    (with-read hybrid-table-2 account
      {"ht-balance":= balance-user}
      (with-read hybrid-table-2 "admin"
        {"ht-balance":= balance-admin}
        (enforce (>= balance-user amount) "user does not have enough balance")
        (update hybrid-table-2 account
          {"ht-balance": (- balance-user amount)})
        (update hybrid-table-2 "admin"
          {"ht-balance": (+ balance-admin amount)})
      )
    )
  )

  (defun confirm-transfer-to-kuro (id:string)
    @doc "ADMIN ONLY: changing status of inter-chain transfers as complete"
    (with-capability (ADMIN)
      (update txs-table-2 id
        {"status": TX_COMPLETE})
    )
  )

  (defun reject-transfer-to-kuro (id:string)
    @doc "ADMIN ONLY: changing status of inter-chain transfers as rejected \
    \ called if debit-ht gets rejected when called from admin \
    \ also refunds the amount to the user"
    (with-capability (ADMIN)
      (with-read txs-table-2 id
        {"amount" := amount,
        "account" := account}
        (credit-ht account amount)
        (update txs-table-2 id
          {"status": TX_REFUNDED})
      )
    )
  )

  ;intended front-end use: (map (hybrid-exchange.get-tx) (hybrid-exchange.get-tx-keys))
  (defun get-tx-keys ()
    @doc "ADMIN ONLY: see who needs to be credited on either chain \
    \ can potentially encypt users info??"
    ;do i need ADMIN cap here, anyone can access this db in theory
    (with-capability (ADMIN)
      (keys txs-table-2)
    )
  )
  (defun get-tx (id:string)
    @doc "for user or admin to check status of a tx"
    (read txs-table-2 id)
  )

  (defun get-req-history (account:string)
    @doc "for user to get all his requested txs"
    (with-capability (REGISTERED_USER account)
      (at "req-history" (read hybrid-table-2 account))
    )
  )

  (defun init-admin-account ()
    @doc "ADMIN ONLY: init admin account --> ONE TIME ONLY FUNCTION"
    (with-capability (ADMIN)
      (insert hybrid-table-2 "admin" {
        ;"guard": (ht-guard),
        "ht-balance": TOTAL_SUPPLY,
        "coins-in": 0.0,
        "coins-out": 0.0,
        "ht-account": false,
        "req-history": []}
      )
    )
  )

  (defun get-balance (account:string)
    (with-read hybrid-table-2 account
      {"ht-balance":= balance}
      balance
    )
  )

)

(create-table hybrid-table-2)
(create-table txs-table-2)
(init-admin-account)
