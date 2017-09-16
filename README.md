# brainfuck-ethereum-compiler
A compilator that compiles brainfuck into Ethereum's bytecode

## Brainfuck assumptions:
 - Array of infinite size to the right
 - Going to the left of row 0 throw exception
 - Each row is 256 bits
 - Underflow and oveflow go back to other side

## ABI
The contract abides by the standard solidity ABIs, and can be used normally
with web3 and alike. The ABI is the same as the following contract:

```solidity
contract ExampleBrainfuckAbi {
    function call(uint[] inputStream) constant returns (uint[] outputStream) {
        // execution goes here
    }
}
```