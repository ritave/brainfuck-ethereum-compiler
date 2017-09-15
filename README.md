# brainfuck-ethereum-compiler
A compilator that compiles brainfuck into Ethereum's bytecode

## Brainfuck assumptions:
 - Array of infinite size to the right
 - Going to the left of row 0 throw exception
 - Each row is 8 bits
 - Underflow and oveflow go back to other side