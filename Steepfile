# frozen_string_literal: true

target :lib do
  signature "sig"
  check "lib"

  library "digest", "uri", "zlib"

  # Gradual-typing profile: catches signature mismatches while tolerating the
  # nil-noise stdlib RBS produces for methods like String#byteslice.
  configure_code_diagnostics(Steep::Diagnostic::Ruby.lenient)
end
