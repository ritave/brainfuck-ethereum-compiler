// Hand written contract simulation of the following brainfuck
// ,>,[-<+>].
// can be optimized quite a bit, but is specially
// written in a clean way for easier learning
//
// Written using Solidity ASM notation
//
// Memory format (inclusive ranges):
// 0x00-0x3F: scratch space
// 0x40: inputStream size
// 0x60: inputStream current position
// calldataload(mload(0x60)): current inputStream word
// 0x80: outputStream size
// keccak256(0x80)-add(keccak256(0x80), mload(0x80)) (+1 for inclusive): outputStream words
// 0xA0: current brainfuck cell
// keccak256(0xA0)-infinity: brainfuck cells
//
// web3.sha3('0x80', {encoding: 'hex'})
// "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421"
// web3.sha3('0xA0', {encoding: 'hex'})
// "0xfec18a9ddb06077929803cdc92f56c05e3eaa46edb2fa1ae550563b37906c77c"
//
// TODO: That memory format doesn't work because memory is a byte array instead of mapping :/ Change it into linked-lists

// ctor
// Check if no money inserted
{
    jumpi(ctor_not_paid, iszero(callvalue))
    revert(0x0, 0x0) // optimization -> 0x0 dup1 revert
  ctor_not_paid:
    codecopy(0x0, dataOffset(contract_code), dataSize(contract_code))
    return(0x0, 0x0)
  stop

  contract_code: {
      jumpi(function_selector, iszero(callvalue))
      revert(0x0, 0x0) // optimization -> 0x0 dup1 revert
    function_selector:
      0xc5cb5d2e // web3.sha3('call(uint256[])')
      // Get first four bytes
      and(div(calldataload(0x0), 0x100000000000000000000000000000000000000000000000000000000), 0xffffffff)
      eq
      call_function
      jumpi
      revert(0x0, 0x0)

    call_function:
      // get inputStream offset
      calldataload(0x4) // first four bytes are the function selector
      0x4
      add
      dup1 // we now have two absolute offsets
      // get inputStream size
      calldataload
      // now stack is [size, offset]
      0x40
      mstore // save size at 0x40
      // offset includes size word, first input is 32 bytes after
      0x20
      add
      0x60
      mstore // save first input offset at 0x60
      // initial output stream size is zero, but the memory is zeroed by default
      // mstore(0x80, 0x0)
    
    execution_context:
      // real brainfuck now!
      // v
      // ,>,[-<+>].
      // -> load input
      // TODO: Security when array overflows
      calldataload(mload(0x60))
      // -> store input in cell
      add(mload(0xA0), 0xfec18a9ddb06077929803cdc92f56c05e3eaa46edb2fa1ae550563b37906c77c)
      mstore // stack: [cell_location, input_word]
      // -> increase input stream counter
      mstore(0x60, add(mload(0x60), 0x20))
      //  v
      // ,>,[-<+>].
      // -> move the cell counter to the right
      mstore(0xA0, add(mload(0xA0), 0x20))
      //   v
      // ,>,[-<+>].
      calldataload(mload(0x60))
      add(mload(0xA0), 0xfec18a9ddb06077929803cdc92f56c05e3eaa46edb2fa1ae550563b37906c77c)
      mstore
      mstore(0x60, add(mload(0x60), 0x20))
      
      //    v
      // ,>,[-<+>].
      loop_1:
        // -> load cell
        end_loop_1
        mload(add(mload(0xA0), 0xfec18a9ddb06077929803cdc92f56c05e3eaa46edb2fa1ae550563b37906c77c))
        iszero
        jumpi
        //     v
        // ,>,[-<+>].
        // -> calculate location of cell
        add(mload(0xA0), 0xfec18a9ddb06077929803cdc92f56c05e3eaa46edb2fa1ae550563b37906c77c) 
        dup1 // [cell_location, cell_location]
        mload // [cell_data, cell_location]
        // -> actual substraction
        0x1
        swap1 // [cell_data, 0x1, cell_location]
        sub
        // -> storage of the cell
        swap1 // [cell_location, cell_data]
        mstore
        //      v
        // ,>,[-<+>].
        // TODO: Check for underflow
        mstore(0xA0, sub(mload(0xA0), 0x20))
        //       v
        // ,>,[-<+>].
        add(mload(0xA0), 0xfec18a9ddb06077929803cdc92f56c05e3eaa46edb2fa1ae550563b37906c77c) 
        dup1 // [cell_location, cell_location]
        mload // [cell_data, cell_location]
        // -> actual substraction
        0x1
        add
        // -> storage of the cell
        swap1 // [cell_location, cell_data]
        mstore
        //        v
        // ,>,[-<+>].
        mstore(0xA0, add(mload(0xA0), 0x20))
        //         v
        // ,>,[-<+>].
        jump(loop_1)
      end_loop_1:

      //          v
      // ,>,[-<+>].
      // -> get cell's contents
      mload(add(mload(0xA0), 0xfec18a9ddb06077929803cdc92f56c05e3eaa46edb2fa1ae550563b37906c77c))
      // -> location of place to put character in the outputStream
      add(mload(0x80), 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421)
      // -> store the contents to the outputStream
      mstore    
      // -> increase outputStream size
      mstore(0x80, add(mload(0x80), 0x1))

    call_function_return:
      // copy the length of outputStream to just before it's data
      // notice the "0" at the end of the hex insteand of "2"
      0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b401
      dup1 // [beginning, beginning]
      mload(0x80)
      dup1 // [length, length, beginning, beginning]
      swap2 // [beginning, length, length, beginning]
      mstore // [length, beginning]
      // the length of return is data + the length itself
      0x1
      add
      swap1
      return // [beginning, length+1]
    }
}
