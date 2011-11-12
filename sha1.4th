\ Based on code taken from:
\ http://www.forth.org.ru/~mlg/mirror/home.earthlink.net/~neilbawd/sha1.html


decimal 

anew nielsha1

#include "helper.4th"

\ number of bytes per memory address
4 CONSTANT CELL
: CELLS CELL * ;

\ real number of bytes per memory address
2 CONSTANT QEDCELL

2VARIABLE SIZE
VARIABLE Single-Bytee


\ Source program uses: CREATE Message-Digest   5 CELLS ALLOT
VHERE 5 CELLS VALLOT
XCONSTANT Message-Digest

20 vallot \ burn space for clean priting using dump

\ Source program uses: CREATE Message-Block   16 CELLS ALLOT
VHERE 16 CELLS VALLOT
XCONSTANT Message-Block

VHERE 9 VALLOT
XCONSTANT Final-Count




\ NOT NEEDED / DEBUG
\ Display as an unsigned binary number
: B.  ( n -- )  BASE @ >R  2 BASE !  U.  R> BASE ! ;
\ Display as an unsigned hexadecimal number
: H.  ( n -- )  BASE @ >R  HEX U.  R> BASE ! ;
: DH. H. H. ;



\ Double versions of bitwise and, or, xor
 
: DOR ( d1 d2 -- d3 )
  rot OR -rot OR swap ;
: DXOR ( d1 d2 -- d3 )
  rot XOR -rot XOR swap ;
: DAND ( d1 d2 -- d3 ) 
  rot AND -rot AND swap ;
  
  
\ double-width tuck
: DTUCK 2swap 2over ; 

\ duplicate 3 double numbers on the stack
: 6DUP 4 xpick 4 xpick 4 xpick ;

: 4SWAP 7 roll 7 roll 7 roll 7 roll ;

\ \\ this is the equivalent of +! 
\ \\ : +! 2dup @ 3 pick + -rot ! drop ;
\ two-plus-store
: 2+! 2dup 2@ 4 xpick d+ 2swap 2! 2drop ;



: DLSHIFT DSHIFT ;
: DRSHIFT negate DSHIFT ;

: INVERT complement ;

: DINVERT complement swap complement swap ;

: DLROTATE           ( d1 n -- d2 )
    3DUP  DLSHIFT D>R  32 SWAP -  DRSHIFT DR>  DOR ;

hex
: LROTATE           ( x n -- x' )
  0 swap dlshift or ;

: Flip-Endian       ( 0102 -- 0201 )
    DUP 8 LROTATE 0xFF00 AND
    SWAP 8 LROTATE 0x00FF AND OR ;
decimal



\ BLK0: Convert the first 16 cells of Message-Block to Work-Block.
\ BLK0: takes single-width index i,
\       which is added to the base of Message-Block and two-fetched
: BLK0              ( i -- d )     \  Big Endian
    CELLS Message-Block rot xn+ 2@ ;

\ BLK: Convert the remaining cells of Message-Block to Work-Block. 
\ BLK0: takes single-width index i, does some fancy XOR work folding
\       into the same double. saves the final result to Message-Block,
\       and also returns it ( final double )
: BLK               ( i -- d )
    DUP  0xd + 0xf AND CELLS Message-Block rot xn+ 2@
    2 pick 0x8 + 0xf AND CELLS Message-Block rot xn+ 2@  DXOR
    2 pick 0x2 + 0xf AND CELLS Message-Block rot xn+ 2@  DXOR
    2 pick       0xf AND CELLS Message-Block rot xn+ 2@  DXOR
    1 DLROTATE  \  This operation was added for SHA-1.
    2DUP 4 roll 15 AND CELLS Message-Block rot xn+ 2! ;



\ -------- This section is marked as "Program Text 6" ---------------



: __F                 ( dd dc db -- bc or b'd )
    2DUP D>R DAND 2SWAP DR> DINVERT DAND DOR ;

: __G                 ( d c b -- bc or bd or cd )
    4DUP DAND D>R  DOR DAND DR>  DOR ;

: __H                 ( d c b -- d xor c xor b )
    DXOR DXOR ;

\  temp = temp + (m + (a <<< 5)) + e
: MIX               ( e d c b temp a m -- e d c b a )
    2SWAP 2DUP D>R                 ( e d c b temp m a)( R: a)
    0x5 DLROTATE d+ d+               ( e d c b temp)    ( R: a)
    2SWAP D>R  2SWAP D>R  2SWAP D>R   ( e temp)    ( R: a b c d)
    D+                           ( temp)      ( R: a b c d)
    \  e = d
       DR> 2SWAP                  ( e temp)      ( R: a b c)
    \  d = c
       DR> 2SWAP                  ( e d temp)      ( R: a b)
    \  c = (b <<< 30)
       DR> 0x1e DLROTATE            ( e d temp c)      ( R: a)
       2SWAP                     ( e d c temp)      ( R: a)
    \  b = a
       DR>                       ( e d c temp b)     ( R: )
    \  a = temp
       2SWAP                     ( e d c b a)
    ;


\ -------- This section is marked as "Program Text 7" ---------------

   : Fetch-Message-Digest   ( -- de dd dc db da )
        4 CELLS U>D Message-Digest D+       ( addr)
            2DUP 2@ 2SWAP CELL U>D d-          ( e addr)
            2DUP 2@ 2SWAP CELL U>D d-          ( e d addr)
            2DUP 2@ 2SWAP CELL U>D d-          ( e d c addr)
            2DUP 2@ 2SWAP CELL U>D d-          ( e d c b addr)
                2@ ;                    ( e d c b a)

    : Add-to-Message-Digest  ( de dd dc db da -- )
        Message-Digest                 ( e d c b a addr)
            DTUCK 2+! CELL U>D D+              ( e d c b addr)
            DTUCK 2+! CELL U>D D+              ( e d c addr)
            DTUCK 2+! CELL U>D D+              ( e d addr)
            DTUCK 2+! CELL U>D D+              ( e addr)
                 2+! ;                  ( )


: TRANSFORM         ( -- )
    Fetch-Message-Digest    ( e d c b a)

    \  Do 80 Rounds of Complicated Processing.
    0x10  0x0 DO  D>R  6DUP __F din 0x5A827999 D+  DR>  I BLK0  MIX  LOOP
    0x14 0x10 DO  D>R  6DUP __F din 0x5A827999 D+  DR>  I BLK   MIX  LOOP
    0x28 0x14 DO  D>R  6DUP __H din 0x6ED9EBA1 D+  DR>  I BLK   MIX  LOOP
    0x3c 0x28 DO  D>R  6DUP __G din 0x8F1BBCDC D+  DR>  I BLK   MIX  LOOP
    0x50 0x3c DO  D>R  6DUP __H din 0xCA62C1D6 D+  DR>  I BLK   MIX  LOOP

    Add-to-Message-Digest ;



: SHA-INIT          ( -- )
    \  Initialize Message-Digest with starting constants.
    Message-Digest
        din 0x67452301 2OVER 2! CELL xn+
        din 0xEFCDAB89 2OVER 2! CELL xn+
        din 0x98BADCFE 2OVER 2! CELL xn+
        din 0x10325476 2OVER 2! CELL xn+
        din 0xC3D2E1F0 2SWAP 2!
    \  Zero bit count.
    0. SIZE 2! ;




: SHA-UPDATE        ( stringxaddr doublelen -- )
   4 needed
    \  Transform 512-bit blocks of message.
    BEGIN    \  Transform Message-Block?
        size 2@      \ fetch upper cell (4 bytes) of SIZE variable
        0x1ff u>d DAND        \ fast modulo 512
        0x3 DRSHIFT   \ shift result 3 ( for example 511 >> 3 is 63 )
        D>R              \ save to return stack, name: modshiftcount
        0x40 U>D DR@ D-  \ grab from return stack, 64 subtract modshiftcount
        2OVER DU> NOT    \ copy string count compare for loop
        
        
    WHILE \ Store some of str&len, and transform.        
        4DUP                ( xstr dlen xstr dlen)            \ duplicate string and count 
        0x40 U>D DR@ D-     ( xstr dlen xstr dlen dnewlen)    \ 64 subtract dmodshiftcount 
        drop nip            ( xstr dlen xstr len newlen)      \ convert len,newlen to single width
        /STRING           \ ( xstr dlen xnewstr (len-newlen) )   \ cut string to newlen
        U>D 2DUP D>R      \ ( xstr dlen xnewstr d(len-newlen) )  \ duplicate the difference, save to rstack
        4SWAP             \ ( xnewstr d(len-newlen) xstr dlen )
        DR> D-            \ ( xnewstr d(len-newlen) xstr dnewlen ) \ grab difference from rstack, use it to get newlen in top cell
        Message-Block DR@ D+ \ ( xnewstr d(len-newlen) xstr dnewlen xmessageaddr+modshiftcount )
        2SWAP              \ ( xnewstr d(len-newlen) xstr xmessageaddr+modshiftcount dnewlen )
        drop              \ ( xnewstr d(len-newlen) xstr xmessageaddr+modshiftcount newlen )
        MOVE              \ ( xnewstr d(len-newlen) )
        TRANSFORM         \ ( xnewstr d(len-newlen) )
        SIZE 2@           \ ( xnewstr d(len-newlen) dsize ) 
        0x40 U>D DR>      \ ( xnewstr d(len-newlen) dsize 0x40 0 dmodshiftcount)
        D- 
        3 DLSHIFT D+ SIZE 2!  ." in" size 2@ d.
    REPEAT
    \  Save final fraction of input.
    ( stringxaddr doublelen )
    Message-Block DR> D+ ( stringxaddr doublelen messageblockxaddr+modshiftcount ) 
    2SWAP  2DUP          ( stringxaddr messageblockxaddr+modshiftcount doublelen doublelen )
    D>R                  ( stringxaddr messageblockxaddr+modshiftcount doublelen )
    drop CMOVE  ( )      \ CMOVE
    SIZE 2@ DR>  D2* D2* D2* D+ SIZE 2! ( )
   
    ;
    
: SHA-FINAL         ( -- )
    \  Save SIZE for final padding.
    
    \ final-count must be 64 bits, so we use 0 0 sizelow sizehi
    0 0 final-count 2!
    SIZE 2@
    Final-Count 4xn+ 2!


    \  Pad so SIZE is 64 bits less than a multiple of 512.
    Single-Bytee 0x80 2 pick 2 pick C!   ( xsingle-bytee )
    1 u>d SHA-UPDATE
    BEGIN  SIZE 2@ 0x1ff u>d DAND 0x1C0 u>d d= NOT WHILE
        Single-Bytee 0 2 pick 2 pick C!  1 u>d SHA-UPDATE
    REPEAT

    \ final-count is 64 bits (hence length of 8)
    Final-Count 8 u>d SHA-UPDATE
    ;
: .SHA
cr
." digest: "
   Message-Digest 0x20 dump  cr \  Display Message-Digest.
;


\ top level word
: sha1 ( string-xaddress )
  sha-init
  count u>d sha-update
  sha-final
.sha ;

hex

\ zero out variable memory.
\ some of this is taken care of in sha-init
2000 0 100 0 fill

