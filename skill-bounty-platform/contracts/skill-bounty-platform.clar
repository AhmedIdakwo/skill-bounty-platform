;; Simplified Decentralized Skill Verification and Bounty Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-submission (err u104))
(define-constant err-voting-ended (err u105))
(define-constant err-voting-not-started (err u106))
(define-constant err-already-voted (err u107))
(define-constant err-unauthorized (err u108))
(define-constant err-invalid-status (err u109))

;; Data Variables
(define-data-var next-challenge-id uint u1)
(define-data-var next-solution-id uint u1)
(define-data-var voting-period uint u1008) ;; ~7 days in blocks

;; Challenge Status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-VOTING u2)
(define-constant STATUS-COMPLETED u3)

;; Data Maps
(define-map challenges uint 
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    skill-category: (string-ascii 50),
    reward-amount: uint,
    created-at: uint,
    voting-end: uint,
    status: uint,
    winner-solution: (optional uint)
  })

(define-map solutions uint
  {
    challenge-id: uint,
    submitter: principal,
    content-hash: (string-ascii 64),
    submitted-at: uint,
    vote-count: uint
  })

(define-map user-votes {challenge-id: uint, voter: principal} uint)

(define-map user-stats principal
  {
    challenges-created: uint,
    challenges-won: uint,
    total-earned: uint
  })

;; Private Functions
(define-private (update-user-stats-created (user principal))
  (let ((current-stats (default-to {challenges-created: u0, challenges-won: u0, total-earned: u0}
                                  (map-get? user-stats user))))
    (map-set user-stats user
      (merge current-stats {challenges-created: (+ (get challenges-created current-stats) u1)}))
    true))

(define-private (update-user-stats-won (user principal) (reward uint))
  (let ((current-stats (default-to {challenges-created: u0, challenges-won: u0, total-earned: u0}
                                  (map-get? user-stats user))))
    (map-set user-stats user
      (merge current-stats {
        challenges-won: (+ (get challenges-won current-stats) u1),
        total-earned: (+ (get total-earned current-stats) reward)
      }))
    true))

;; Public Functions

;; Create a new challenge
(define-public (create-challenge 
  (title (string-ascii 100)) 
  (description (string-ascii 500)) 
  (skill-category (string-ascii 50))
  (reward-amount uint))
  (let ((challenge-id (var-get next-challenge-id)))
    (asserts! (> reward-amount u0) err-insufficient-funds)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? reward-amount tx-sender (as-contract tx-sender)))
    
    ;; Create challenge
    (map-set challenges challenge-id
      {
        creator: tx-sender,
        title: title,
        description: description,
        skill-category: skill-category,
        reward-amount: reward-amount,
        created-at: block-height,
        voting-end: u0,
        status: STATUS-ACTIVE,
        winner-solution: none
      })
    
    ;; Update creator stats
    (update-user-stats-created tx-sender)
    
    ;; Increment counter
    (var-set next-challenge-id (+ challenge-id u1))
    
    (ok challenge-id)))

;; Submit a solution
(define-public (submit-solution 
  (challenge-id uint) 
  (content-hash (string-ascii 64)))
  (let ((challenge (unwrap! (map-get? challenges challenge-id) err-not-found))
        (solution-id (var-get next-solution-id)))
    
    ;; Check challenge is active
    (asserts! (is-eq (get status challenge) STATUS-ACTIVE) err-invalid-status)
    
    ;; Create solution
    (map-set solutions solution-id
      {
        challenge-id: challenge-id,
        submitter: tx-sender,
        content-hash: content-hash,
        submitted-at: block-height,
        vote-count: u0
      })
    
    ;; Increment counter
    (var-set next-solution-id (+ solution-id u1))
    
    (ok solution-id)))

;; Start voting period (only creator)
(define-public (start-voting (challenge-id uint))
  (let ((challenge (unwrap! (map-get? challenges challenge-id) err-not-found)))
    
    ;; Only creator can start voting
    (asserts! (is-eq tx-sender (get creator challenge)) err-unauthorized)
    ;; Must be active
    (asserts! (is-eq (get status challenge) STATUS-ACTIVE) err-invalid-status)
    
    ;; Update to voting status
    (map-set challenges challenge-id
      (merge challenge 
        {
          status: STATUS-VOTING,
          voting-end: (+ block-height (var-get voting-period))
        }))
    
    (ok true)))

;; Vote for a solution
(define-public (vote-for-solution (challenge-id uint) (solution-id uint))
  (let ((challenge (unwrap! (map-get? challenges challenge-id) err-not-found))
        (solution (unwrap! (map-get? solutions solution-id) err-not-found))
        (vote-key {challenge-id: challenge-id, voter: tx-sender}))
    
    ;; Check challenge is in voting
    (asserts! (is-eq (get status challenge) STATUS-VOTING) err-voting-not-started)
    ;; Check voting hasn't ended
    (asserts! (< block-height (get voting-end challenge)) err-voting-ended)
    ;; Check solution belongs to challenge
    (asserts! (is-eq (get challenge-id solution) challenge-id) err-invalid-submission)
    ;; Check user hasn't voted
    (asserts! (is-none (map-get? user-votes vote-key)) err-already-voted)
    
    ;; Record vote
    (map-set user-votes vote-key solution-id)
    
    ;; Increment vote count
    (map-set solutions solution-id
      (merge solution {vote-count: (+ (get vote-count solution) u1)}))
    
    (ok true)))

;; Finalize challenge and pay winner
(define-public (finalize-challenge (challenge-id uint) (winning-solution-id uint))
  (let ((challenge (unwrap! (map-get? challenges challenge-id) err-not-found))
        (solution (unwrap! (map-get? solutions winning-solution-id) err-not-found)))
    
    ;; Check voting period ended
    (asserts! (is-eq (get status challenge) STATUS-VOTING) err-invalid-status)
    (asserts! (>= block-height (get voting-end challenge)) err-voting-not-started)
    ;; Check solution belongs to challenge
    (asserts! (is-eq (get challenge-id solution) challenge-id) err-invalid-submission)
    
    ;; Pay winner
    (try! (as-contract (stx-transfer? (get reward-amount challenge) 
                                     tx-sender 
                                     (get submitter solution))))
    
    ;; Update challenge status
    (map-set challenges challenge-id
      (merge challenge 
        {
          status: STATUS-COMPLETED,
          winner-solution: (some winning-solution-id)
        }))
    
    ;; Update winner stats
    (update-user-stats-won (get submitter solution) (get reward-amount challenge))
    
    (ok true)))

;; Read-only functions

;; Get challenge details
(define-read-only (get-challenge (challenge-id uint))
  (map-get? challenges challenge-id))

;; Get solution details
(define-read-only (get-solution (solution-id uint))
  (map-get? solutions solution-id))

;; Get user stats
(define-read-only (get-user-stats (user principal))
  (map-get? user-stats user))

;; Get user vote for challenge
(define-read-only (get-user-vote (challenge-id uint) (voter principal))
  (map-get? user-votes {challenge-id: challenge-id, voter: voter}))

;; Check if voting is active
(define-read-only (is-voting-active (challenge-id uint))
  (match (map-get? challenges challenge-id)
    challenge
    (and (is-eq (get status challenge) STATUS-VOTING)
         (< block-height (get voting-end challenge)))
    false))