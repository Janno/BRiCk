  $ . ../../setup-cpp2v.sh
  $ check_cpp2v test.cpp
  cpp2v -v -check-types -names test_17_cpp_names.v -o test_17_cpp.v test.cpp -- -std=c++17 2>&1 | sed 's/^ *[0-9]* | //'
  $TESTCASE_ROOT/test.cpp:7:3: warning: expression result unused [-Wunused-value]
    A; // A here has type `E`
    ^
  1 warning generated.
  coqc -w -notation-overridden -w -notation-incompatible-prefix test_17_cpp_names.v
  coqc -w -notation-overridden -w -notation-incompatible-prefix test_17_cpp.v
