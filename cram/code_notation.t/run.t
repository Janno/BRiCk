  $ bash ../gen-project.sh
  $ export COQPATH="$DUNE_SOURCEROOT/_build/install/default/lib/coq/user-contrib"
  $ dune build test.vo
  {s: $"foo" = !$"bar";}
       : Stmt' ?type Expr
  where
  ?type : [ty : type  e : Expr  s : Stmt |- Set]
  {e: (*&$"hello" + #3)}
       : Expr
  {s: $"hello";
      continue; 
      break; 
      $"world";
      if ($"world") {
        continue; 
      } else {
        break; 
      }
      // end block}
       : Stmt' ?type Expr
  where
  ?type : [ty : type  e : Expr  s : Stmt |- Set]
  {s: if (mut int32 $"x" = #0; $"x") {
        continue; 
        continue; 
        continue; 
        continue; 
        // end block
      } else {
        break; 
      }
      if (mut int32 $"x" = #0; $"x") {
        // end block
      } else {
        break; 
      }
      return $"x"; 
      $"x";
      return; 
      // end block}
       : Stmt
  {s: if (mut int32 $"x" = #0; $"x") {
        continue; 
      } else {
        continue; 
        continue; 
        continue; 
        continue; 
        // end block
      }
      return $"x"; 
      return; 
      // end block}
       : Stmt
  {s: if (mut int32 $"x" = #0; $"x") {
        continue; 
      } else {
        continue; 
      }
      return $"x"; 
      return; 
      // end block}
       : Stmt
  {s: if (mut int32 $"x" = #0; $"x") {
        $"x"++;
        // end block
      } else {
        continue; 
      }
      // end block}
       : Stmt
  {s: if (mut int32 $"x" = #0; $"x") {
        $"x"++;
        // end block
      } else {
        --$"x";
        // end block
      }
      while (mut int32 $"x" = #0; $"x") {
        $"x"--;
        // end block
      }
      // end block}
       : Stmt
  {s: do {
        $"x"--;
        // end block
      } while($"x");
      // end block}
       : Stmt' ?type Expr
  where
  ?type : [ty : type  e : Expr  s : Stmt |- Set]
  {s: do {
        $"foo" = !$"bar";
        // end block
      } while($"x");
      // end block}
       : Stmt' ?type Expr
  where
  ?type : [ty : type  e : Expr  s : Stmt |- Set]
  {s: $"should_continue" =
        !$::"_Z15process_commandPKN4Zeta8Zeta_ctxEPcR9UmxSharedRmR5Admin"(
         $"ctx",
         $"buffer",
         $"shared",
         $"client",
         $"result");}
       : Stmt' ?type Expr
  where
  ?type : [ty : type  e : Expr  s : Stmt |- Set]
  {s: if (mut int32 $"x" = #0; $"x") {
        continue; 
      } else {
        continue; 
        continue; 
        continue; 
        continue; 
        // end block
      }
      return $"x"; 
      return; 
      // end block}
       : Stmt
  {s: if (mut int32 $"x" = #0; $"x") {
        continue; 
      } else {
        continue; 
      }
      return $"x"; 
      return; 
      // end block}
       : Stmt
  {s: if (mut int32 $"x" = #0; $"x") {
        $"x"++;
        // end block
      } else {
        continue; 
      }
      // end block}
       : Stmt
  {s: if (mut int32 $"x" = #0; $"x") {
        $"x"++;
        // end block
      } else {
        --$"x";
        // end block
      }
      while (mut int32 $"x" = #0; $"x") {
        $"x"--;
        // end block
      }
      // end block}
       : Stmt
  {s: do {
        $"x"--;
        // end block
      } while($"x");
      // end block}
       : Stmt' ?type Expr
  where
  ?type : [ty : type  e : Expr  s : Stmt |- Set]
  {s: do {
        $"foo" = !$"bar";
        // end block
      } while($"x");
      // end block}
       : Stmt' ?type Expr
  where
  ?type : [ty : type  e : Expr  s : Stmt |- Set]
  {s: $"should_continue" =
        !$::"_Z15process_commandPKN4Zeta8Zeta_ctxEPcR9UmxSharedRmR5Admin"(
         $"ctx",
         $"buffer",
         $"shared",
         $"client",
         $"result");}
       : Stmt' ?type Expr
  where
  ?type : [ty : type  e : Expr  s : Stmt |- Set]
