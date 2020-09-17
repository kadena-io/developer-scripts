(namespace "free")

(module hello-world GOVERNANCE
  "A smart contract to greet the world."

  (defcap GOVERNANCE ()
    (enforce-guard (keyset-ref-guard 'hello-keyset)))

  (defschema name-schema
    @doc "Name schema"
    @model [(invariant (!= name ""))]
    name)

  (deftable
    name-table:{name-schema})

  (defun here (n:string)
    "Designed for /send calls. Leave your trace on Kadena mainnet!"
    (enforce (!= n "") "Name cannot be empty")
    (with-default-read name-table "total"
      {"name": 0}
      {"name":= total}
      (write name-table "total" {"name": (+ total 1)})
      (write name-table (format "{}" [total]) {"name": n}))
      (format "{} was here." [n]))

  (defun lookup (key:string)
    (with-read name-table key
      {"name":= name}
      name))
)

(create-table name-table)
