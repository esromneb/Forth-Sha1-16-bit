CODE DSHIFT		( d1\n2 -- d3 )
\ Assembly coded for Freescale HCS12/9S12
\ logically {i.e.,no sign extension} shifts d1 accding to the value of n2.
\ If n2 is positive, n1 is shifted left; if n2 is neg, n1 is shifted right.
\ the absolute value of n2 determines #bits of shifting;
\ unchecked error on overflow/underflow
2 IND,Y LDD				\ D <- msword
4 IND,Y LDX				\ X <- lsword
0 IND,Y TST				\ test msbyte of n2; is n2 negative?
MI IF,					\ if n2 is negative, shift right:
		BEGIN,
			LSRA 		\ shift right,preserve top bit, bot bit->carry INCORRECT
			RORB		\ rotate right,carry->top bit
			XGDX		\ D <- lsword, X <- msword, cond.codes unaffected
			RORA		\ shift right; carry->top.bit,bot bit->carry
			RORB		\ shift right; carry->top.bit
			XGDX		\ D <- msword, X <- lsword, cond.codes unaffected
			1 IND,Y INC
		GE UNTIL,
ELSE,					\ if n2 is positive, shift left
	1 IND,Y TST
	GT IF,				\ do nothing if index=0
		BEGIN,
			XGDX		\ D <- lsword, X <- msword, cond.codes unaffected
			LSLD 		\ shift left,top bit->carry INCORRECT
			XGDX		\ D <- msword, X <- lsword, cond.codes unaffected
			ROLB		\ rotate left,carry->bottom bit
			ROLA		\ rotate left,carry->bottom bit
			1 IND,Y DEC
		LE UNTIL,
	THEN,
THEN,
2 ,+Y STD				( d1.lsword\d3.msword -- ) \ save msword
2 IND,Y STX				( -- d3 ) \ save lsword
RTS
END.CODE