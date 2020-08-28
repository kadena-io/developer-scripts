(namespace "user")
(module covid GOVERNANCE

  (use coin)

  ;; ===============
  ;; CONTRACT GOVERANCE: Only covid-admin account
  ;; ===============

  (defcap GOVERNANCE ()
    "makes sure only admin account can update the smart contract"
    (enforce-guard (at 'guard (coin.details "covid-admin")))
  )

  ;; ===============
  ;; TABLES: test and pritning entity data columns
  ;; ===============

  (defschema test-schema
    ;; test manufacturer
    test-manufacturer:string
    ;; test model or manufacturer name for test
    test-model:string
    ;; patient age-group
    age-group:string
    ;; patient gender: male | female | other
    gender:string
    ;; patient country
    country:string
    ;; patient zip code
    zipcode:string
    ;; patient test result: positive | negative | inconclusive
    result:string
    ;; patient info hash
    patient-hash:string
    ;; last time record was modified
    last-mod-time:time
    ;; record public key initalization block height
    pub-key-init-bh:integer
    ;; test initialization (administering) block height
    test-init-bh:integer
    ;; test end (record result) block height
    test-end-bh:integer)

  (defschema printer-schema
    ;; if printer is authorized to print
    authorized:bool
    ;; name of printing entity (ex: manufacturer or authorized supplier)
    entity-name:string
    ;; list of all test label public keys priting entity has registered
    test-pub-keys:[string])

    (defschema acct-info
      ;pub key of test
      acct-name:string
      ;name of keyset to read from env-data
      ks-name:string
    )

  (deftable test-table-three:{test-schema})
  (deftable printer-table-three:{printer-schema})


  ;; ===============
  ;; CAPABILITIES: admin, printing entity, test
  ;; ===============

  (defcap ADMIN ()
    "makes sure only admin account can approve new printing entities"
    (enforce-guard (at 'guard (coin.details "covid-admin")))
  )

  (defcap PRINTING-ENTITY (pub-key:string)
    "enforce printing entity coin account and active status"
    (enforce-guard (at 'guard (coin.details pub-key)))
    (with-read printer-table-three pub-key {"authorized" := authorized}
      (enforce authorized "printing entity no longer authorized to register tests"))
  )

  (defcap REGISTERED-TEST (pub-key:string)
    "make sure the test keys match provided public key"
    (enforce-guard (at 'guard (coin.details pub-key)))
  )

  ;; ===============
  ;; ADMIN ONLY FUNCTIONS: can create and blacklist printing entities
  ;; ===============

  (defun create-printing-entity (pub-key:string entity-name:string)
    @doc "ADMIN ONLY: Init new printing entity"
    (with-capability (ADMIN)
      (coin.create-account pub-key (read-keyset "ks"))
      (insert printer-table-three pub-key {
        "authorized": true,
        "entity-name": entity-name,
        "test-pub-keys": []
      })
      (format "Entity {} is now authorized to register and print test labels with pub-key={}"
        [entity-name, pub-key])
    )
  )

  (defun blacklist-printing-entity (pub-key:string)
    @doc "ADMIN ONLY: Init new printing entity"
    (with-capability (ADMIN)
      (with-read printer-table-three pub-key {
        "entity-name":= entity-name,
        "authorized":= authorized}
        (enforce authorized "priting entity is already blacklisted")
        (update printer-table-three pub-key {
          "authorized": false})
        (format "Entity {} is no longer authorized to print"
          [entity-name])
      )
    )
  )

  ;; ===============
  ;; PRINTING ENTITY ONLY FUNCTIONS: can register test to print labels
  ;; ===============


 (defun register-test-helper (printer-pub-key:string test-manufacturer:string test-model:string acct:object:{acct-info})
    @doc "PRINTING ENTITY ONLY: facilitate mapping over the last parameter of the function"
    (require-capability (PRINTING-ENTITY printer-pub-key))
    (coin.create-account (at "acct-name" acct) (read-keyset (at "ks-name" acct)))
    (insert test-table-three (at "acct-name" acct) {
      "test-manufacturer": test-manufacturer,
      "test-model": test-model,
      "age-group": "",
      "gender": "",
      "country": "",
      "zipcode": "",
      "result": "",
      "patient-hash": "",
      "last-mod-time": (at 'block-time (chain-data)),
      "pub-key-init-bh": (at 'block-height (chain-data)),
      "test-init-bh": 0,
      "test-end-bh": 0
    })
    (with-read printer-table-three printer-pub-key {
      "test-pub-keys" := test-pub-keys}
      (update printer-table-three printer-pub-key {
        "test-pub-keys": (+ test-pub-keys [(at "acct-name" acct)])
      })
    )
 )


  (defun register-test (printer-pub-key:string test-manufacturer:string test-model:string accts:[object:{acct-info}])
    @doc "PRINTING ENTITY ONLY: register the test public key on chain when printing a label"
    (with-capability (PRINTING-ENTITY printer-pub-key)
      (map (register-test-helper printer-pub-key test-manufacturer test-model) accts)
      (format
        "{} tests registered on chain by printer={}"
        [(length accts), printer-pub-key])
    )
  )

  ;; ===============
  ;; TEST ONLY FUNCTIONS: called when test is handled by doctors through test dashboard
  ;; ===============

  (defun administer-test (pub-key:string age-group:string gender:string country:string zipcode:string patient-hash:string)
    @doc "REGISTED-TEST ONLY: administer a test and write demographic info"
    (with-capability (REGISTERED-TEST pub-key)
      (with-read test-table-three pub-key {"test-init-bh" := init-bh}
        (enforce (= init-bh 0) "this test has already been administered")
        (update test-table-three pub-key {
          "age-group": age-group,
          "gender": gender,
          "country": country,
          "zipcode": zipcode,
          "patient-hash": patient-hash,
          "last-mod-time": (at 'block-time (chain-data)),
          "test-init-bh": (at 'block-height (chain-data))
        })
        (format
          "Test with public key={} administered to patient={}"
          [pub-key, patient-hash])
      )
    )
  )

  (defun end-test (pub-key:string result:string)
    @doc "REGISTED-TEST ONLY: end a test and write result"
    (with-capability (REGISTERED-TEST pub-key)
      (with-read test-table-three pub-key {
        "test-end-bh" := end-bh,
        "test-init-bh" := init-bh}
        (enforce (!= init-bh 0) "this test has not yet been administered")
        (enforce (= end-bh 0) "this test has already been ended")
        (update test-table-three pub-key {
          "result": result,
          "last-mod-time": (at 'block-time (chain-data)),
          "test-end-bh": (at 'block-height (chain-data))
        })
        (format
          "Test with public key={} ended with result={}"
          [pub-key, result])
      )
    )
  )

  ;; ===============
  ;; READ FUNCTIONS: anyone can get test and printing entity info
  ;; ===============

  (defun get-all-test-keys ()
    @doc "returns all test public keys"
    (keys test-table-three)
  )

  (defun get-record:object{test-schema} (pub-key:string)
    @doc "gets data for a test by public key"
    (read test-table-three pub-key)
  )

  (defun get-all-printing-entities ()
    @doc "returns all printing entity pub keys"
    (keys printer-table-three)
  )

  (defun get-priting-entity:object{printer-schema} (pub-key:string)
    @doc "get info of a particular printing entity"
    (read printer-table-three pub-key)
  )


)

; (create-table test-table-three)
; (create-table printer-table-three)
