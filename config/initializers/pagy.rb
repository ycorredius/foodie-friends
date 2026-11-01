# API lists use Pagy's keyset pagination: clients send the previous response's
# `next_page` token as `page`, and may request up to 50 items with `limit`.
Pagy::OPTIONS[:limit] = 20
Pagy::OPTIONS[:client_limit] = 50
Pagy::OPTIONS.freeze
