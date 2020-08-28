(define-keyset 'loans-admin-keyset
(read-keyset "loans-admin-keyset"))

(module loans 'loans-admin-keyset

  (defschema loan
    loanName:string
    entityName:string
    loanAmount:integer
    status:string
    )

  (defschema loan-history
    loanId:string
    buyer:string
    seller:string
    amount:integer
    )

  (defschema loan-inventory
    balance:integer
    )

  (deftable loans-table:{loan})
  (deftable loan-history-table:{loan-history})
  (deftable loan-inventory-table:{loan-inventory})

  (defconst INITIATED "initiated")
  (defconst ASSIGNED "assigned")

  ;;utility function
  (defun inventory-key (loanId:string owner:string)
     "Make composite key from OWNER and LoanId"
     (format "{}:{}" [loanId owner])
   )

  (defun create-a-loan (loanId loanName entityName loanAmount)
    (insert loans-table loanId {
      "loanName":loanName,
      "entityName":entityName,
      "loanAmount":loanAmount,
      "status":INITIATED
      })
    (insert loan-inventory-table (inventory-key loanId entityName){
      "balance": loanAmount
      }))

  (defun assign-a-loan (txid loanId buyer amount)
    ;; read entity name from loans-table
    (with-read loans-table loanId {
      "entityName":= entityName,
      "loanAmount":= issuerBalance
      }
      ;;insert loan transaction into loan-history table
      (insert loan-history-table txid {
        "loanId":loanId,
        "buyer":buyer,
        "seller":entityName,
        "amount": amount
        })
      ;; insert buyer's loan balance into inventory table
      (insert loan-inventory-table (inventory-key loanId buyer) {
        "balance":amount
        })
      ;; update new balance of the issuer in the inventory table
      (update loan-inventory-table (inventory-key loanId entityName){
        "balance": (- issuerBalance amount)
        }))
      ;; update loan status at loans-table
      (update loans-table loanId {
        "status": ASSIGNED
        }))

  (defun sell-a-loan (txid loanId buyer seller amount)
    (with-read loan-inventory-table (inventory-key loanId seller)
      {"balance":= prev-seller-balance}
      (with-default-read loan-inventory-table (inventory-key loanId buyer)
        {"balance" : 0}
        {"balance":= prev-buyer-balance}
      (insert loan-history-table txid {
        "loanId":loanId,
        "buyer":buyer,
        "seller":seller,
        "amount": amount
        })
      (update loan-inventory-table (inventory-key loanId seller)
        {"balance": (- prev-seller-balance amount)})
      (write loan-inventory-table (inventory-key loanId buyer)
        {"balance": (+ prev-buyer-balance amount)}))))

  (defun read-a-loan (loanId)
    (read loans-table loanId))

  (defun read-loan-tx ()
    (map (txlog loans-table) (txids loans-table 0)))

  (defun read-all-loans ()
    (select loans-table (constantly true)))

  (defun read-inventory-pair (key)
    {"inventory-key":key, "balance": (at 'balance (read loan-inventory-table key))}
    )

  (defun read-loan-inventory ()
    (map (read-inventory-pair) (keys loan-inventory-table)))

  (defun read-loans-with-status (status)
    (select loans-table (where "status" (= status))))

  )

(create-table loans-table)
(create-table loan-history-table)
(create-table loan-inventory-table)
