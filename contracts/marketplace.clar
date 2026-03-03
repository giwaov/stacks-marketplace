;; NFT Marketplace Contract - Buy and sell NFTs on Stacks
;; Built with @stacks/transactions

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_LISTING_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PRICE (err u102))
(define-constant ERR_ALREADY_LISTED (err u103))
(define-constant FEE_PERCENT u25) ;; 2.5%

;; Data vars
(define-data-var listing-count uint u0)
(define-data-var total-sales uint u0)
(define-data-var total-volume uint u0)

;; Maps
(define-map listings uint {
  seller: principal,
  price: uint,
  token-id: uint,
  contract: principal,
  active: bool,
  created-at: uint
})

(define-map sales uint {
  listing-id: uint,
  buyer: principal,
  price: uint,
  sold-at: uint
})

;; Read-only functions
(define-read-only (get-listing-count)
  (var-get listing-count))

(define-read-only (get-total-sales)
  (var-get total-sales))

(define-read-only (get-total-volume)
  (var-get total-volume))

(define-read-only (get-listing (id uint))
  (map-get? listings id))

(define-read-only (calculate-fee (price uint))
  (/ (* price FEE_PERCENT) u1000))

;; Public functions
(define-public (create-listing (token-id uint) (price uint) (nft-contract principal))
  (let ((new-id (+ (var-get listing-count) u1)))
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (map-set listings new-id {
      seller: tx-sender,
      price: price,
      token-id: token-id,
      contract: nft-contract,
      active: true,
      created-at: block-height
    })
    (var-set listing-count new-id)
    (ok new-id)))

(define-public (buy-listing (listing-id uint))
  (let (
    (listing (unwrap! (map-get? listings listing-id) ERR_LISTING_NOT_FOUND))
    (price (get price listing))
    (fee (calculate-fee price))
    (seller-amount (- price fee))
    (sale-id (+ (var-get total-sales) u1))
  )
    (asserts! (get active listing) ERR_LISTING_NOT_FOUND)
    (try! (stx-transfer? seller-amount tx-sender (get seller listing)))
    (try! (stx-transfer? fee tx-sender CONTRACT_OWNER))
    (map-set listings listing-id (merge listing { active: false }))
    (map-set sales sale-id {
      listing-id: listing-id,
      buyer: tx-sender,
      price: price,
      sold-at: block-height
    })
    (var-set total-sales sale-id)
    (var-set total-volume (+ (var-get total-volume) price))
    (ok sale-id)))

(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? listings listing-id) ERR_LISTING_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get seller listing)) ERR_NOT_AUTHORIZED)
    (map-set listings listing-id (merge listing { active: false }))
    (ok true)))

;; ===== OFFER SYSTEM =====
(define-data-var offer-count uint u0)

(define-map offers uint {
  listing-id: uint,
  buyer: principal,
  amount: uint,
  status: (string-ascii 20),
  created-at: uint
})

(define-constant ERR_OFFER_NOT_FOUND (err u104))
(define-constant ERR_OFFER_EXPIRED (err u105))
(define-constant OFFER_DURATION u1440) ;; ~10 days in blocks

;; Make an offer on a listing
(define-public (make-offer (listing-id uint) (amount uint))
  (let (
    (listing (unwrap! (map-get? listings listing-id) ERR_LISTING_NOT_FOUND))
    (new-offer-id (+ (var-get offer-count) u1))
  )
    (asserts! (get active listing) ERR_LISTING_NOT_FOUND)
    (asserts! (> amount u0) ERR_INVALID_PRICE)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set offers new-offer-id {
      listing-id: listing-id,
      buyer: tx-sender,
      amount: amount,
      status: "pending",
      created-at: block-height
    })
    (var-set offer-count new-offer-id)
    (ok new-offer-id)))

;; Accept an offer (seller)
(define-public (accept-offer (offer-id uint))
  (let (
    (offer (unwrap! (map-get? offers offer-id) ERR_OFFER_NOT_FOUND))
    (listing (unwrap! (map-get? listings (get listing-id offer)) ERR_LISTING_NOT_FOUND))
    (amount (get amount offer))
    (fee (calculate-fee amount))
    (seller-amount (- amount fee))
    (sale-id (+ (var-get total-sales) u1))
  )
    (asserts! (is-eq tx-sender (get seller listing)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status offer) "pending") ERR_OFFER_NOT_FOUND)
    (try! (as-contract (stx-transfer? seller-amount tx-sender tx-sender)))
    (try! (as-contract (stx-transfer? fee tx-sender CONTRACT_OWNER)))
    (map-set offers offer-id (merge offer { status: "accepted" }))
    (map-set listings (get listing-id offer) (merge listing { active: false }))
    (map-set sales sale-id {
      listing-id: (get listing-id offer),
      buyer: (get buyer offer),
      price: amount,
      sold-at: block-height
    })
    (var-set total-sales sale-id)
    (var-set total-volume (+ (var-get total-volume) amount))
    (ok sale-id)))

;; Cancel/withdraw offer (buyer)
(define-public (cancel-offer (offer-id uint))
  (let ((offer (unwrap! (map-get? offers offer-id) ERR_OFFER_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get buyer offer)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status offer) "pending") ERR_OFFER_NOT_FOUND)
    (try! (as-contract (stx-transfer? (get amount offer) tx-sender tx-sender)))
    (map-set offers offer-id (merge offer { status: "cancelled" }))
    (ok true)))

;; Read-only for offers
(define-read-only (get-offer (id uint))
  (map-get? offers id))

(define-read-only (get-offer-count)
  (var-get offer-count))
