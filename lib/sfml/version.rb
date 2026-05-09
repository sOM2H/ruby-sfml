module SFML
  # The SFML/CSFML release this gem is built against. End users can
  # check this at runtime to assert binding compatibility.
  CSFML_VERSION = "3.0.0"

  # Gem version. The first three segments mirror CSFML_VERSION exactly;
  # the trailing fourth segment is our own patch number for fixes /
  # additions made on top of the same upstream CSFML release.
  #
  # Examples on a hypothetical timeline:
  #
  #   "3.0.0.0"  — first cut against CSFML 3.0.0
  #   "3.0.0.1"  — our bug fix, still on CSFML 3.0.0
  #   "3.0.0.2"  — another patch
  #   "3.0.1.0"  — CSFML 3.0.1 ships, we re-cut from upstream
  #   "3.0.1.1"  — our patch on top of CSFML 3.0.1
  #   "3.1.0.0"  — CSFML 3.1.0 ships, we add new bindings
  VERSION = "3.0.0.2"
end
