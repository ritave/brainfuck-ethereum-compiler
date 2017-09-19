// Since memory is a byte array, dynamic arrays are no go unless
// we create our own heap and defragmenter. Easier way will be to make
// doubly-linked lists. Since memory is very limited, we can use one word
// for both pointers
//
// Function parameters are on top of the stack from the left, followed by the return position
// for the jump
{
  list_init:
    /* init_list(location)
     *   Initializes a new linked list at :location.
     *   Creates a dummy node, with prev pointer being set to 16 times 0xFF
     *   Head, or the last node will always have set the next node to 16 times 0xFF too
     */
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    SWAP1
    MSTORE
    // no need to push zeros to the next word
    JUMP

  list_push:
    /* list_push(free_space, node_value, last_head)
     *   Creates a new node at the specified :free_space and updates the
     *   pointer on the :last_head node. Sets the new value of node to :node_value
     *
     *   Free space should be unusued location of at least 64 free bytes
     */
    DUP1
    DUP1 // [space, space, space, val, head, jump]
    SWAP4 // [head, space, space, val, space, jump]
    DUP1
    SWAP2 // [space, head, space, head, val, space, jump]
    SWAP1
    0x100000000000000000000000000000000
    MUL // [head<<16 space, space, head, val, space, jump]
    SWAP1 // [space, head<<16, space, head, val, space, jump]
    MSTORE // -> stored ptr to last head
    0x20
    ADD // [space+0x20, head, val, space, jump]
    SWAP2 // [val, head, space+0x20, space, jump]
    SWAP1 // [head, val, space+0x20, space, jump]
    SWAP2 // [space+0x20, val, head, space, jump]
    MSTORE // -> save the node value
    DUP1 // [head, head, space, jump]
    MLOAD // [prev_ptr<<16|0xFF.16, head, space, jump]
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000
    AND // [prev_ptr<<16|0x00.16, head, space, jump]
    SWAP1 // [head, prev_ptr<<16|0x00.16, space, jump]
    SWAP2 // [space, prev_ptr<<16|0x00.16, head, jump]
    OR // [prev_ptr<<16|space, head, jump]
    SWAP1
    MSTORE // -> updated previous node with new pointer
    JUMP

  list_update:
    /* list_update(location, node_value)
     *   Updates the node at :location with new :node_value
     */
    0x20
    ADD
    MSTORE // -> save new value
    JUMP

  list_peek:
    /* list_peek(location) constant -> node_value
     *   Gets the value of the current node at :location
     */
    0x20
    ADD
    MLOAD
    SWAP1
    JUMP

  list_prev:
    /* list_prev(location) constant -> location
     *   Returns a location of the previous node from the current.
     *   Calls REVERT if first node
     */
    MLOAD
    0x100000000000000000000000000000000
    DIV
    SWAP1
    JUMP

  list_next:
    /* list_next(location) constant -> location
     *   Returns a location of the next node from the current.
     *   Calls REVERT if the last node
     */
    MLOAD
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    AND
    SWAP1
    JUMP

  list_is_begin:
    /* list_is_begin(location) constant -> is_first_node
     *   Checks if is the first dummy node
     */
    MLOAD
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000
    DUP1
    SWAP2 // [prev_ptr|next_ptr, 0xFF..., 0xFF..., JUMP]
    AND
    EQ
    SWAP1
    JUMP
    
  list_is_end:
    /* ilst_is_end(location) constant -> is_last_node
     *   Checks if is the last node
     */
    MLOAD
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    DUP1
    SWAP2
    AND
    EQ
    SWAP1
    JUMP

  list_flatten:
    /* list_flatten(tail_location, array_start) -> size
     *   Traverses the whole linked list backwards, counting number of nodes and then
     *   traverses it again flattening it into dynamic unit[] array.
     *   At :array_start will be it's length follwing by length uints of node values
     */
    // First get the length
    0x0
    SWAP1

    // begin -> [tail, 0x0, ...]
    // invariant -> [node, count_of_nodes_between_node_tail, ...]
    // end -> [head, count_of_nodes_between_head_tail, ...]
    loop_traverse_left:
      MLOAD // [prev_ptr|next_ptr, count, array, jump]
      0x100000000000000000000000000000000
      DIV
      DUP1 // [prev_ptr, prev_ptr, count, array, jump]
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      AND // [is_first, prev_ptr, count, array, jump]
      end_loop_traverse_left
      JUMPI
      SWAP1
      0x1
      ADD
      SWAP1 // [location, count+1, array, jump]
      loop_traverse_left
      JUMP
    end_loop_traverse_left:

    SWAP1 // [count, head, array, jump]
    DUP1 // [count, count, head, array, jump]
    DUP4 // [array, count, count, head, array, jump]
    MSTORE // -> save the number of elements in linked list
    DUP1
    SWAP2 // [array, count, head, count, jump]
    0x20
    ADD // [array+0x20, count, head, count, jump]
    SWAP1 // [count, array+0x20, head, count, jump]

    // begin -> [count, array+0x20, head, count, jump], i=0
    // invariant -> [count-i, array+0x20*(i+1), i_th_node, count, jump], 0<=i<=count
    // end -> [0, array+0x20*(count+1), tail, count, jump]
    loop_flatten:
        DUP1
        ISZERO
        end_loop_flatten
        JUMPI
        0x1
        SUB
        SWAP2
        DUP1 // [node, node, array+0x20*(i+1), count-i-1, count, jump]
        MLOAD
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        AND
        SWAP1
        0x20
        ADD
        MLOAD // [node_val, next_ptr, array+0x20*(i+1), count-i-1, count, jump]
        DUP3
        SWAP2 // [array+0x20*(i+1), node_val, next_ptr, array+0x20*(i+1), count-i-1, count, jump]
        MSTORE // -> save the element to new array
        SWAP1
        0x1
        ADD // [array+0x20*(i+2), next_ptr, count-i-1, count, jump]
        SWAP1
        SWAP2 // [count-i-1, array+0x20*(i+2), next_ptr, count, jump]
        loop_flatten
        JUMP // invariant satisifed, i++ -> [count-i, array+0x20*(i+1), i_th_node, count, jump]
    end_loop_flatten:

    POP
    POP
    POP
    SWAP1
    JUMP
}