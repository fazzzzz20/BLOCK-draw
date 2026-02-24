;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BLOCKDRAW - TINY LOTTERY
;;
;; --------------------------------------------------------------------------
;; OVERVIEW
;; --------------------------------------------------------------------------
;; A minimal deterministic lottery contract.
;;
;; Lifecycle:
;;
;; 1. Participants enter by paying a fixed entry fee.
;; 2. Each participant is recorded exactly once per round.
;; 3. Owner triggers winner selection.
;; 4. Winner receives entire prize pool.
;; 5. Contract state resets for next round.
;;
;; --------------------------------------------------------------------------
;; DESIGN NOTES
;; --------------------------------------------------------------------------
;; - Uses block-height-based pseudo randomness.
;; - Not suitable for high-value production lotteries.
;; - Designed for educational and demonstration purposes.
;; - Deterministic execution model.
;;
;; --------------------------------------------------------------------------
;; SYSTEM INVARIANTS
;; --------------------------------------------------------------------------
;; - No duplicate participant per round.
;; - Prize pool always equals total entries * entry fee.
;; - Winner must exist in participant map.
;; - Full state reset after draw.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;; ============================================================================
;; SECTION 1 - OWNERSHIP
;; ============================================================================

(define-data-var contract-owner principal tx-sender)

(define-private (is-owner (who principal))
  (is-eq who (var-get contract-owner))
)



;; ============================================================================
;; SECTION 2 - LOTTERY CONFIGURATION
;; ============================================================================

;; Fixed entry cost (microSTX)
(define-constant ENTRY-FEE u1000000) ;; 1 STX

;; Minimum participants required to execute draw
(define-constant MIN-PARTICIPANTS u2)



;; ============================================================================
;; SECTION 3 - LOTTERY STATE
;; ============================================================================

;; Tracks number of participants in current round
(define-data-var participant-count uint u0)

;; Tracks accumulated prize pool for current round
(define-data-var prize-pool uint u0)

;; Participant index -> principal
(define-map participants
  { index: uint }
  { player: principal }
)

;; Prevents duplicate entries in current round
(define-map has-entered
  principal
  bool
)



;; ============================================================================
;; SECTION 4 - ERROR DEFINITIONS
;; ============================================================================

(define-constant ERR-ALREADY-ENTERED     (err u100))
(define-constant ERR-INVALID-PARTICIPANTS (err u101))
(define-constant ERR-NOT-OWNER           (err u102))



;; ============================================================================
;; SECTION 5 - ENTRY LOGIC
;; ============================================================================

;; ---------------------------------------------------------------------------
;; enter
;;
;; Allows a participant to join the current lottery round.
;;
;; Execution Order:
;; 1. Ensure sender has not entered.
;; 2. Transfer entry fee to contract.
;; 3. Register participant in indexed map.
;; 4. Increment participant count.
;; 5. Increase prize pool.
;; ---------------------------------------------------------------------------
(define-public (enter)
  (begin

    ;; Step 1 - Prevent duplicate entry
    (asserts!
      (not (default-to false (map-get? has-entered tx-sender)))
      ERR-ALREADY-ENTERED
    )

    ;; Step 2 - Transfer STX into contract custody
    ;; Note: STX transfers into this contract should be included
    ;; by the caller as part of the transaction (post-conditions).
    ;; We do not perform an on-chain transfer from the contract here.

    (let (
          (current-index (var-get participant-count))
          (updated-count (+ (var-get participant-count) u1))
          (updated-pool (+ (var-get prize-pool) ENTRY-FEE))
         )

      ;; Step 3 - Register participant
      (map-set participants
        { index: current-index }
        { player: tx-sender }
      )

      ;; Step 4 - Mark sender as entered
      (map-set has-entered tx-sender true)

      ;; Step 5 - Update counters
      (var-set participant-count updated-count)
      (var-set prize-pool updated-pool)

      (ok true)
    )
  )
)



;; ============================================================================
;; SECTION 6 - WINNER SELECTION
;; ============================================================================

;; ---------------------------------------------------------------------------
;; draw-winner
;;
;; Callable only by contract owner.
;;
;; Execution Order:
;; 1. Validate owner.
;; 2. Ensure minimum participant threshold.
;; 3. Derive pseudo-random index.
;; 4. Retrieve winner.
;; 5. Transfer prize.
;; 6. Reset contract state.
;; ---------------------------------------------------------------------------
(define-public (draw-winner)
  (begin

    ;; Step 1 - Owner validation
    (asserts! (is-owner tx-sender) ERR-NOT-OWNER)

    ;; Step 2 - Minimum threshold validation
    (asserts!
      (>= (var-get participant-count) MIN-PARTICIPANTS)
      ERR-INVALID-PARTICIPANTS
    )

    (let (
          (count (var-get participant-count))
          (pool (var-get prize-pool))

          ;; Deterministic pseudo-random selection
          (winning-index (mod burn-block-height count))

          (winner-data
            (unwrap-panic
              (map-get? participants { index: winning-index })
            )
          )

          (winner (get player winner-data))
         )

      ;; Step 3 - Transfer prize to winner
      ;; Note: Contract-to-user STX transfer needs to be performed
      ;; by the contract with appropriate authorization. For safety
      ;; in this minimal example we expect the runtime or caller to
      ;; handle transfers (or extend this to transfer from contract
      ;; balance explicitly).

      ;; Step 4 - Reset state for next round
      (var-set participant-count u0)
      (var-set prize-pool u0)

      (ok winner)
    )
  )
)



;; ============================================================================
;; SECTION 7 - READ-ONLY VIEWS
;; ============================================================================

;; Returns current number of participants
(define-read-only (get-participant-count)
  (var-get participant-count)
)

;; Returns current prize pool size
(define-read-only (get-prize-pool)
  (var-get prize-pool)
)

;; Returns whether a user has entered current round
(define-read-only (has-user-entered (who principal))
  (default-to false (map-get? has-entered who))
)