\m5_TLV_version 1d --inlineGen --bestsv --noline --noDirectiveComments: tl-x.org
\SV
   /*
   Copyright 2025 Redwood EDA, LLC
   
   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
   
   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
   */
\m5
   use(m5-1.0)

   var(PROG_NAME, my_custom)
   var(ISA, RISCV)
   var(EXT_E, 0)
   var(EXT_M, 0)
   var(EXT_F, 0)
   var(EXT_B, 0)
   var(NUM_CORES, 1)
   var(NUM_VCS, 2)
   var(NUM_PRIOS, 2)
   var(MAX_PACKET_SIZE, 8)
   var(soft_reset, 1'b0)
   var(cpu_blocked, 1'b0)
   var(BRANCH_PRED, two_bit)
   var(EXTRA_REPLAY_BUBBLE, 0)
   var(EXTRA_PRED_TAKEN_BUBBLE, 0)
   var(EXTRA_JUMP_BUBBLE, 0)
   var(EXTRA_BRANCH_BUBBLE, 0)
   var(EXTRA_INDIRECT_JUMP_BUBBLE, 0)
   var(EXTRA_NON_PIPELINED_BUBBLE, 1)
   var(EXTRA_TRAP_BUBBLE, 1)
   var(NEXT_PC_STAGE, 0)
   var(FETCH_STAGE, 0)
   var(DECODE_STAGE, 1)
   var(BRANCH_PRED_STAGE, 1)
   var(REG_RD_STAGE, 1)
   var(EXECUTE_STAGE, 2)
   var(RESULT_STAGE, 2)
   var(REG_WR_STAGE, 3)
   var(MEM_WR_STAGE, 3)
   var(LD_RETURN_ALIGN, 4)
\SV
   // Include WARP-V.
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v/a62bbe1258b914c7d5ce00cd6ffb075aea8fb952/warp-v.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/wordle_accelerator/5688443cf83e04e372d56715444b62f3f70072cf/wordle.tlv'])
\m5
   TLV_fn(riscv_my_custom_prog, {
      ~assemble(['
         # /=====================\
         # | Count to 10 Program |
         # \=====================/
         #
         # Default program for RV32I test
         # Add 1,2,3,...,9 (in that order).
         # Store incremental results in memory locations 0..9. (1, 3, 6, 10, ...)
         # Updated for wordle support, to guess a new word (though not legal words) in each loop iteration.
         #
         # Regs:
         # t0: cnt
         # a2: ten
         # a0: out
         # t1: final value
         # a1: expected result
         # t2: store addr
         # a5: guess word
         # a6: answer word
         reset:
            # Load words "GUESS" (guess word) and "TEASE" (answer word)
            LI a5, 0b1001010010001001010000110  # "GUESS"
            LI a6, 0b0010010010000000010010011  # "TEASE"
            ORI t2, zero, 0          #     store_addr = 0
            ORI t0, zero, 1          #     cnt = 1
            ORI a2, zero, 10         #     ten = 10
            ORI a0, zero, 0          #     out = 0
         loop:
            WORDLE a4, a5, a6
            ADD a0, t0, a0           #  -> out += cnt
            SW a0, 0(t2)             #     store out at store_addr
            ADDI t0, t0, 1           #     cnt++
            ADDI t2, t2, 4           #     store_addr++
            # Modify the wordle guess word by adding or subtracting one to/from each letter.
            LI t3, 0b1111011111000001111100001
            ADD a5, a5, t3
            BLT t0, a2, loop         #  ^- branch back if cnt < 10
         # Result should be 0x2d.
            LW t1, -4(t2)            #     load the final value
            ADDI a1, zero, 0x2d      #     expected result (0x2d)
            BEQ t1, a1, pass         #     pass if as expected
         
            # Branch to one of these to report pass/fail to the default testbench.
         fail:
            ADD a1, a1, zero         #     nop fail
         pass:
            ADD t1, t1, zero         #     nop pass
         
      '])
   })
m4+module_def()
\TLV
   // Instantiate WARP-V with custom instructions.
   // For example, here we add byte add instructions, defining:
   //   - their encoding (see similar in https://github.com/stevehoover/warp-v_includes/blob/master/risc-v_defs.tlv)
   //   - logic to assign their result value (see similar in https://github.com/stevehoover/warp-v/blob/master/warp-v.tlv).
   m5+warpv_with_custom_instructions(
      ['R, 32, I, 01110, 000, 0000000, WORDLE'],
      \TLV
         m5+wordle_rslt(/instr, /wordle_rslt, $wordle_rslt, /src[1]$reg_value, /src[2]$reg_value)
      )
   |fetch
      /instr
         @m5_VIZ_STAGE
            m5+wordle_viz(/instr, /wordle_rslt, /instr$is_wordle_instr, ['left: 295, top: 23, width: 15, height: 15'])
\SV
   endmodule
