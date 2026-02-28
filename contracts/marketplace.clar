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
