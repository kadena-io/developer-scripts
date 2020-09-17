(namespace "user")
(module pacty-parrots GOVERNANCE

  (defcap GOVERNANCE ()
    (enforce-guard (at 'guard (details 'contract-admins))))


  (use coin)
  ; --------------------------------------------------------------------------
  ; Schemas and Tables
  ; ---------------------------------------------------------------------
  (defschema user-games
    rounds-played:integer
    coins-in:decimal
    coins-out:decimal
    total-rolls:integer
    rounds:list)
  (deftable user-games-table:{user-games})
  ; --------------------------------------------------------------------------
  ; Constants and Capabilities
  ; --------------------------------------------------------------------------
  (defconst ROUND_CLOSED:string "closed")
  (defconst ROUND_OPEN:string "open")
  (defconst PARROTS_ACCOUNT:string 'parrot-bank)
  (defconst PAYOUT_MATRIX:object {
    ;pirate and cop zero your score
    ;all other results are summed or multiplied if both outcomes the same
    ;Blue is worth 7 points
    "BB": 49, "BG": 13, "BP": 12, "BR": 11, "BT": 10, "BY": 9, "BI": 0, "BC": 0,
      "BF": 507, "BA": 207, "BK": 107, "BD": 57, "BM": 22, "BH": 37, "BS": 67,
    ;Green is worth 6 points
    "GB": 13, "GG": 36, "GP": 11, "GR": 10, "GT": 9, "GY": 8, "GI": 0, "GC": 0,
      "GF": 506, "GA": 206, "GK": 106, "GD": 56, "GM": 21, "GH": 36, "GS": 66,
    ;Purple is worth 5 points
    "PB": 12, "PG": 11, "PP": 25, "PR": 9, "PT": 8, "PY": 7, "PI": 0, "PC": 0,
      "PF": 505, "PA": 205, "PK": 105, "PD": 55, "PM": 20, "PH": 35, "PS": 65,
    ;Red is worth 4 points
    "RB": 11, "RG": 10, "RP": 9, "RR": 16, "RT": 7, "RY": 6, "RI": 0, "RC": 0,
      "RF": 504, "RA": 204, "RK": 104, "RD": 54, "RM": 19, "RH": 34, "RS": 64,
    ;Teal is worth 3 points
    "TB": 10, "TG": 9, "TP": 8, "TR": 7, "TT": 9, "TY": 5, "TI": 0, "TC": 0,
      "TF": 503, "TA": 203, "TK": 103, "TD": 53, "TM": 18, "TH": 33, "TS": 63,
    ;Yellow is worth 2 points
    "YB": 9, "YG": 8, "YP": 7, "YR": 6, "YT": 5, "YY": 4, "YI": 0, "YC": 0,
      "YF": 502, "YA": 202, "YK": 102, "YD": 52, "YM": 17, "YH": 32, "YS": 62,
    ;Cop zeros result
    "CB": 0, "CG": 0, "CP": 0, "CR": 0, "CT": 0, "CY": 0, "CI": 0, "CC": 0,
      "CF": 0, "CA": 0, "CK": 0, "CD": 0, "CM": 0, "CH": 0, "CS": 0,
    ;Pirate zeros result
    "IB": 0, "IG": 0, "IP": 0, "IR": 0, "IT": 0, "IY": 0, "II": 0, "IC": 0,
      "IF": 0, "IA": 0, "IK": 0, "ID": 0, "IM": 0, "IH": 0, "IS": 0,
    ;Guy Fieri is worth 500 points
    "FB": 507, "FG": 506, "FP": 505, "FR": 504, "FT": 503, "FY": 502, "FI": 0, "FC": 0,
      "FF": 250000, "FA": 700, "FK": 600, "FD": 550, "FM": 515, "FH": 530, "FS": 560,
    ;Nicolas Cage is worth 200 points
    "AB": 207, "AG": 206, "AP": 205, "AR": 204, "AT": 203, "AY": 202, "AI": 0, "AC": 0,
      "AF": 700, "AA": 40000, "AK": 300, "AD": 250, "AM": 215, "AH": 230, "AS": 260,
    ;Keanu Reeves is worth 100 points
    "KB": 107, "KG": 106, "KP": 105, "KR": 104, "KT": 103, "KY": 102, "KI": 0, "KC": 0,
      "KF": 600, "KA": 300, "KK": 10000, "KD": 150, "KM": 115, "KH": 130, "KS": 160,
    ;deal-with-it is worth 50 points
    "DB": 57, "DG": 56, "DP": 55, "DR": 54, "DT": 53, "DY": 52, "DI": 0, "DC": 0,
      "DF": 550, "DA": 250, "DK": 150, "DD": 2500, "DM": 65, "DH": 80, "DS": 110,
    ;moustache is worth 15 points
    "MB": 22, "MG": 21, "MP": 20, "MR": 19, "MT": 18, "MY": 17, "MI": 0, "MC": 0,
      "MF": 515, "MA": 215, "MK": 115, "MD": 65, "MM": 225, "MH": 45, "MS": 75,
    ;sherlock is worth 30 points
    "HB": 37, "HG": 36, "HP": 35, "HR": 34, "HT": 33, "HY": 32, "HI": 0, "HC": 0,
      "HF": 530, "HA": 230, "HK": 130, "HD": 80, "HM": 45, "HH": 900, "HS": 90,
    ;spy is worth 60 points
    "SB": 67, "SG": 66, "SP": 65, "SR": 64, "ST": 63, "SY": 62, "SI": 0, "SC": 0,
      "SF": 560, "SA": 260, "SK": 160, "SD": 110, "SM": 75, "SH": 90, "SS": 1200
  })
  (defun parrots-guard:guard () (create-module-guard 'parrots-admin))
  (defcap BET (account)
    "ensures only account holder is making the bets"
    (let ((g (at "guard" (details account))))
      (enforce-guard g)
    )
    ;true
  )
  ; --------------------------------------------------------------------------
  ; PACTY PARROTS CONTRACT -- main functions
  ; --------------------------------------------------------------------------
  (defun start-round (account:string)
    @doc "5 COINS TO ENTER. Lets any user registered in coin contract initiate a round \
    \ fails if round-id provided is not latest played and if round has ended \
    \ user must pay 5 coins to enter"
    (with-capability (BET account)
      ;with-default-read to account for new users
      (with-default-read user-games-table account
        {"rounds-played": 0,
        "coins-in": 0.0,
        "coins-out": 0.0,
        "total-rolls": 0,
        "rounds": []}
        {"rounds-played":= rounds-played,
        "coins-in":= coins-in,
        "coins-out":= coins-out,
        "total-rolls":= total-rolls,
        "rounds":= rounds}
        ;make sure round-id supplied is same as length of current rounds-played
          ;len is 0 if its a new user
        ;(enforce (= round-id (length rounds)) "incorrect round id supplied")
        ;if not round 0, check prev round is closed
        (if (= (length rounds) 0) "" (enforce (= ROUND_CLOSED (at 2 (at (- (length rounds) 1) rounds))) "selected round must be open"))
        ;send money to coin contract
          ;enforces that the account exits in contract
        (transfer account PARROTS_ACCOUNT 5.0)
        (let* ((draw-result (parrot-draw account))
              (points (at draw-result PAYOUT_MATRIX))
              (status (if (= 0 points) ROUND_CLOSED ROUND_OPEN))
              (new-round [[draw-result] points status]))
          (write user-games-table account
            {"rounds-played": (+ rounds-played 1),
            "coins-in": (+ coins-in 5.0),
            "coins-out": coins-out,
            "total-rolls": (+ total-rolls 1),
            "rounds": (+ rounds [new-round])}
          )
        )
      )
    )
  )
  (defun continue-round (account:string)
    @doc "lets users registered in this contract continue an existing round \
    \ must use a capability in this case as coin contract is not called to verify signer \
    \ if user rolls a 0 point case it closes the round automatically"
   (with-capability (BET account)
    (with-read user-games-table account
      {"rounds":= rounds, "total-rolls":= total-rolls}
      ;(enforce false (length rounds))
      ;make sure you are modifying the last element in the list of rounds
      ;(enforce (= round-id (- (length rounds) 1)) "incorrect round id supplied")
      ;make sure the round is open
      (enforce (= ROUND_OPEN (at 2 (at (- (length rounds) 1) rounds))) "selected round must be open")
      (let* ((round (at (- (length rounds) 1) rounds))
            (draw-result (parrot-draw account))
            (points (if (= 0 (at draw-result PAYOUT_MATRIX)) 0 (+ (at 1 round) (at draw-result PAYOUT_MATRIX))))
            (status (if (= 0 points) ROUND_CLOSED ROUND_OPEN))
            (new-round [(+ (at 0 round) [draw-result]) points status]))
        (update user-games-table account
          {"rounds": (+ (drop -1 rounds) [new-round]),
          "total-rolls": (+ total-rolls 1)}
        )
      )
    )
   )
  )
  (defun end-round (account:string)
    @doc "let users registered in this contract end an existing round \
    \ performs checks"
   (with-capability (BET account)
    (with-read user-games-table account
      {"rounds":= rounds, "coins-out":= coins-out}
      ;(enforce (= round-id (- (length rounds) 1)) "incorrect round id supplied")
      (enforce (= ROUND_OPEN (at 2 (at (- (length rounds) 1) rounds))) "selected round must be open")
      (let* ((round (at (- (length rounds) 1) rounds))
            (points (at 1 round)))
        ;pay user if has got more than 0 points
            ;although its impossible in theory to have 0 points and a status of ROUND_OPEN
        (if (not (= 0 points)) (transfer PARROTS_ACCOUNT account (* points 1.0)) "")
        (update user-games-table account
          {
           "rounds": (+ (drop -1 rounds) [[(at 0 round) (at 1 round) ROUND_CLOSED]]),
           "coins-out": (+ coins-out (* points 1.0))
          }
        )
      )
    )
   )
  )
  ; --------------------------------------------------------------------------
  ; HELPERS -> Draw functions
  ; --------------------------------------------------------------------------
  (defun str-to-draw (str:string)
    @doc "HELPER: converts two digit string to single parrot outcome"
    (let ((draw-int (str-to-int str)))
        ;8% chance of blue parrot
        (if (and (>= draw-int 0) (<= draw-int 79)) "B"
          ;9% chance of green parrot
          (if (and (>= draw-int 80) (<= draw-int 169)) "G"
            ;10% chance of purple parrot
            (if (and (>= draw-int 170) (<= draw-int 269)) "P"
              ;11% chance of red parrot
              (if (and (>= draw-int 270) (<= draw-int 379)) "R"
                ;12% chance of teal parrot
                (if (and (>= draw-int 380) (<= draw-int 499)) "T"
                  ;13% chance of yellow parrot
                  (if (and (>= draw-int 500) (<= draw-int 629)) "Y"
                    ;5% chance of pirate parrot
                    (if (and (>= draw-int 630) (<= draw-int 679)) "I"
                      ;5% chance of cop parrot
                      (if (and (>= draw-int 680) (<= draw-int 729)) "C"
                        ;7% chance of mustache parrot
                        (if (and (>= draw-int 730) (<= draw-int 799)) "M"
                          ;6% chance of sherlock parrot
                          (if (and (>= draw-int 800) (<= draw-int 859)) "H"
                            ;5% chance of deal-with-it parrot
                            (if (and (>= draw-int 860) (<= draw-int 909)) "D"
                              ;4% chance of spy parrot
                              (if (and (>= draw-int 910) (<= draw-int 949)) "S"
                                ;2.5% chance of keanu reeves parrot
                                (if (and (>= draw-int 950) (<= draw-int 974)) "K"
                                  ;1.5% chance of nicolas cage parrot
                                  (if (and (>= draw-int 975) (<= draw-int 989)) "A"
                                      ;1% chance of fieri parrot
                                      (if (and (>= draw-int 990) (<= draw-int 999)) "F" "")))))))))))))))
    )
  )
  ;need to restrict calling this function somehow...
  (defun parrot-draw (account:string)
    @doc "reads from (chain-data) to take in block-time, \
    \ block-height, prev-block-hash hashes it, \
    \ takes first three and last three digits of str-to-int base 64 to create double parrot outcome"
    ; (let* ((chain-seeds (chain-data))
    ;       (block-time-hash (hash (at "block-time" chain-seeds)))
    ;       (prev-block-hash (hash (at "prev-block-hash" chain-seeds)))
    ;       (block-height-hash (hash (at "block-height"chain-seeds)))
    ;       (master-hash-int (str-to-int 64 (hash (+ block-height-hash (+ prev-block-hash block-time-hash)))))
    (let* (;(block-time-hash (hash (at "block-time" (chain-data))))
          (prev-block-hash (at "prev-block-hash" (chain-data)))
          ;(block-height-hash (format "{}" [(at "block-height"(chain-data))]))
          ;(master-hash-int (str-to-int 64 (hash (+ block-height-hash (+ prev-block-hash block-time-hash)))))
          (master-hash-int (str-to-int 64 (hash (+ prev-block-hash (take 20 account)))))
          ;(master-hash-int (str-to-int 64 (hash prev-block-hash)))
          (master-hash-str (format "{}" [master-hash-int]))
          (first-parrot (take 3 master-hash-str))
          (second-parrot (take -3 master-hash-str)))
        (+ (str-to-draw first-parrot) (str-to-draw second-parrot))
    )
  )
  ; --------------------------------------------------------------------------
  ; UTILS -> for fetching data ( /local calls )
  ; --------------------------------------------------------------------------
  (defun get-table (account:string)
    (read user-games-table account)
  )
  (defun get-users ()
    (keys user-games-table)
  )
  (defun info-helper (payouts:object result:string)
    (at result payouts)
  )
  (defun get-payout-matrix ()
    PAYOUT_MATRIX
  )
  (defun get-current-round-info (account:string)
    (with-read user-games-table account
      { "rounds":= rounds }
      (let* ((current-round (at (- (length rounds) 1) rounds))
            (rolls (at 0 current-round))
            (points (map (info-helper PAYOUT_MATRIX) rolls))
            (total (fold (+) 0 points)))
        (format "your rolls and corresponding points from round {} are: {} {} and total points: {}" [(+ (- (length rounds) 1) 1) rolls points total])
      )
    )
  )
)



(create-table user-games-table)

;this can be done post deploy
;  by reading the guard from the coin contract
; (transfer-create "contract-admins" PARROTS_ACCOUNT (parrots-guard) 1000000.0)
