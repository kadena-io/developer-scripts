;(namespace "user")
(define-keyset 'admin-keyset (read-keyset 'admin-keyset))
(module crowdfund-campaign 'admin-keyset
  (use coin)
  ;define campaign schema
  (defschema campaign
    title:string
    description:string
    target-raise:decimal
    current-raise:decimal
    start-date:time
    target-date:time
    ownerAccount:string
    guard:guard
    status:integer
    )

  (defschema fund
    campaign-title:string
    fundOwner:string
    pact-id:string
    escrow:string
    status:integer
    )

  (deftable campaigns-table:{campaign})
  (deftable fund-table:{fund})

  (defconst CREATED 0)
  (defconst CANCELLED 1)
  (defconst SUCCEEDED 2)
  (defconst FAILED 3)

  (defun crowdfund-guard:guard () (create-module-guard 'crowdfund-guard))

  (defcap ACCT_GUARD (account)
    (enforce-guard (at 'guard (details account))))

  (defcap CAMPAIGN_GUARD (title)
    (with-read campaigns-table title {
      "guard":=guard
      }
      (enforce-guard guard))
  )

  (defcap ROLLBACK (title from:string)
    (with-read campaigns-table title {
      "target-date":=target-date,
      "start-date":=start-date,
      "status":= status
      }
      (let ((from-guard (at 'guard (details from))
      ))
      (enforce-one "refund guard failure or campaign already succeeded" [
        (enforce (enforce-refund target-date start-date status from-guard)
          "Campaign is not open or guards don't match")
        (enforce (= status CANCELLED) "Campaign has cancelled")
        (enforce (= status FAILED) "Campaign has failed")
        ])
       )))

  (defun enforce-refund:bool (target-date:time start-date:time status:integer issuer-guard:guard)
      (enforce (!= status CANCELLED) "CAMPAIGN HAS BEEN CANCELLED")
      (enforce (!= status FAILED) "Campaign has failed")
      (enforce (!= status SUCCEEDED) "Campaign has failed")
      (enforce (< (curr-time) target-date) "CAMPAIGN HAS ENDED")
      (enforce (>= (curr-time) start-date) "CAMPAIGN HAS NOT STARTED")
      (enforce-guard issuer-guard)
    )

  (defcap CANCEL:bool (title)
    (with-read campaigns-table title{
      "status":=status
      }
      (enforce (= status CANCELLED) "NOT CANCELLED")))

  (defcap OPEN:bool (title)
    (with-read campaigns-table title{
      "target-date":=target-date,
      "start-date":=start-date,
      "status":=status
      }
      (enforce (!= status CANCELLED) "CAMPAIGN HAS BEEN CANCELLED")
      (enforce (< (curr-time) target-date) "CAMPAIGN HAS ENDED")
      (enforce (>= (curr-time) start-date) "CAMPAIGN HAS NOT STARTED")))

  (defcap SUCCESS:bool (title)
    (with-read campaigns-table title{
      "target-raise":=target-raise,
      "current-raise":=current-raise,
      "target-date":=target-date,
      "status":=status
      }
      (enforce (>= (curr-time) target-date) "CAMPAIGN HAS NOT ENDED")
      (enforce (>= current-raise target-raise) "CAMPAIGN HAS NOT RAISED ENOUGH")
      (enforce (!= status CANCELLED) "CAMPAIGN HAS BEEN CANCELLED")
      ))

  (defcap FAIL:bool (title)
    (with-read campaigns-table title{
      "target-raise":=target-raise,
      "target-date":=target-date,
      "current-raise":=current-raise,
      "status":=status
      }
      (enforce (!= status CANCELLED) "CAMPAIGN HAS BEEN CANCELLED")
      (enforce (>= (curr-time) target-date) "CAMPAIGN HAS NOT ENDED")
      (enforce (< current-raise target-raise) "CAMPAIGN HAS SUCCEEDED")))


  (defcap REFUND () true)
  (defcap RAISE () true)

  (defun create-campaign (
    title:string description:string
    ownerAccount:string target-raise:decimal
    start-date:time target-date:time)
    "Adds a campaign to campaign table"
    (enforce (< (curr-time) start-date) "Start Date shouldn't be in the past")
    (enforce (< start-date target-date) "Start Date should be before target-date")
    (enforce (< 0.0 target-raise) "Target raise is not positive number")

    (with-capability (ACCT_GUARD ownerAccount)
        (insert campaigns-table title {
            "title": title,
            "description": description,
            "target-raise":target-raise,
            "current-raise": 0.0,
            "start-date":start-date,
            "target-date":target-date,
            "ownerAccount": ownerAccount,
            "guard": (at 'guard (details ownerAccount)),
            "status": CREATED
            })))

  (defun read-campaigns:list ()
    "Read all campaigns in campaign table"
    (select campaigns-table
      ['title 'description 'ownerAccount 'start-date 'target-date  'current-raise 'target-raise 'status]
      (constantly true)))

  (defun cancel-campaign (title)
    (with-capability (CAMPAIGN_GUARD title)
      (update campaigns-table title {
          "status": CANCELLED
       }))
  ;;Rollback all -get all pacts and rollback
  )

  (defun succeed-campaign (title)
    (with-capability (SUCCESS title)
      (update campaigns-table title {
          "status": SUCCEEDED
       }))
  ;;resolve pacts - get all pacts and resolve
  )

  (defun fail-campaign (title)
    (with-capability (FAIL title)
      (update campaigns-table title {
          "status": FAILED
       }))
  ;;Rollback all - get all pacts and rollback
  )

  (defun create-fund (title funder escrow)
     (insert fund-table (pact-id) {
       "campaign-title":title,
       "escrow": escrow,
       "fundOwner":funder,
       "pact-id":(pact-id),
       "status":CREATED
       }))

  (defun cancel-fund (title funder escrow)
    (require-capability (ROLLBACK title funder))
    (update fund-table (pact-id) {
      "status":CANCELLED
      }))

  (defun fetch-pacts:list (title:string)
    (select fund-table (where 'campaign-title (= title))))

  (defun raise-campaign (title amount)
    (require-capability (RAISE))
      (with-read campaigns-table title {
        "current-raise":= current-raise
        }
        (update campaigns-table title {
          "current-raise": (+ current-raise amount)
          })))

  (defun refund-campaign (title amount)
    (require-capability (REFUND))
      (with-read campaigns-table title {
        "current-raise":= current-raise
        }
        (update campaigns-table title {
          "current-raise": (- current-raise amount)
          })))

  (defpact fund-campaign (from title amount escrow)

      (step-with-rollback
        ;;initiate
        (with-capability (ACCT_GUARD from)
          (with-capability (OPEN title)
            (with-capability (RAISE)
            ;; use pact guard
              (transfer-create from escrow (create-pact-guard escrow) amount)
              (create-fund title from escrow)
              (raise-campaign title amount)
              )))
        ;;rollback
        (with-capability (REFUND)
          (with-capability (ROLLBACK title from)
            (transfer escrow from amount)
            (cancel-fund title from escrow)
            (refund-campaign title amount)))
        )
      ;;Executes when the campaign meets the goal
      (step
        (with-capability (SUCCESS title)
          (with-read campaigns-table title {"ownerAccount":= owner }
          (transfer escrow owner amount)))))

  (defun curr-time:time ()
    @doc "Returns current chain's block-time in time type"
    (at 'block-time (chain-data)))
)

(create-table campaigns-table)
(create-table fund-table)
