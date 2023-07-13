(lang dune 3.6)
(using coq 0.6)
(name coq-cpp2v)

(generate_opam_files)

(maintainers
 "Gregory Malecha <gregory@bedrocksystems.com>"
 "Abhishek Anand <abhishek@bedrocksystems.com>"
 "Gordon Stewart <gordon@bedrocksystems.com>")
(authors
 "Gregory Malecha <gregory@bedrocksystems.com>"
 "Abhishek Anand <abhishek@bedrocksystems.com>"
 "Gordon Stewart <gordon@bedrocksystems.com>")
(source (github bedrocksystems/cpp2v))

(package
 (name coq-cpp2v)
 (synopsis "Frontend and program logic for C++")
 (depends
  (coq (= dev))
  (coq-ext-lib (= dev))
  (coq-iris (= dev.2023-04-06.0.09fa9322))
  (elpi (>= 1.16.5))
  (coq-elpi (= dev))))

(package
 (name coq-cpp2v-bin)
 (synopsis "Binary package for cpp2v")
 (depends conf-clang conf-llvm conf-cmake))
