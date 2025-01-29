\m5_TLV_version 1d: tl-x.org
\m5
   
   // =================================================
   // Welcome!  New to Makerchip? Try the "Learn" menu.
   // =================================================
   
   use(m5-1.0)   /// uncomment to use M5 macro library.
   // Enumeration of guess and answer inputs.
   var(guess, 0)
   var(answer, 1)
   
\TLV wordle_rslt(/_top, /_name, @_stage, $_out, $_in0, $_in1, _where, @_viz)
   @_stage
      $_out[31:0] = {22'b0, /_name/guess_letter[*]$out};
      /_name
         // Input operands:
         // 1 word, 5 letters, 5 bits per letter.
         // in0: Guess word
         // in1: Answer word
         // Output:
         // 2 bits per letter:
         //   2'00: (gray) no match
         //   2'01: (yellow) in the word; wrong place
         //   2'10: (green) matched
         /in[1:0]
            $val[31:0] = #in == 0 ? /_top$_in0 : /_top$_in1;
            /letter[4:0]
               $letter[4:0]  = /_name/in$val[(#letter + 1) * 5 - 1 : #letter * 5];
         /answer_letter[4:0]
            $letter[4:0] = /_name/in[m5_answer]/letter[#answer_letter]$letter;
         /guess_letter[4:0]
            $letter[4:0] = /_name/in[m5_guess]/letter[#guess_letter]$letter;
            
            // Is this letter green?
            $green = /_name/answer_letter[#guess_letter]$letter == /_name/guess_letter[#guess_letter]$letter;
            
            // Is this letter yellow?
            // There can be at most two yellows. (If both have three of the same letter, at least one must be green.)
            // For each guess letter, determine, for each answer letter and prior guess letter,
            //   whether it "may be yellow" (in the guess) or "may match yellow" (in the answer),
            //   meaning it matches the guess letter and is non-green.
            // First Yellow: There's a may-match-yellow and there are no prior may-be-yellows.
            // Second Yellow: There are at least two may-match-yellows in the answer and there is exactly
            //         one prior may-be-yellow in the guess.
            /earlier
               $ANY = /guess_letter/earlier_letter[(#guess_letter + 4) % 5]$ANY;
            $first_yellow = (| /answer_letter[*]$may_match_yellow) &&
                            (#guess_letter == 0 ? 1'b1 : /earlier$no_yellows_so_far);
            $second_yellow = $answer_may_match_two_yellows &&
                             (#guess_letter == 0 ? 1'b0 : /earlier$one_yellow_so_far);
            $yellow = $first_yellow || $second_yellow;
            $out[1:0] = {$green, $yellow};
            
            $answer_may_match_two_yellows = /answer_letter[4]$may_match_yellow_cnt[1];
            /answer_letter[4:0]
               $match = /_name/answer_letter[#answer_letter]$letter == /_name/guess_letter[#guess_letter]$letter;
               $may_match_yellow =
                    #answer_letter != #guess_letter &&   // shortcut for aligned letter, which may not be/match yellow.
                    $match && ! /guess_letter[#answer_letter]$green;
               /prev
                  $ANY = /answer_letter[(#answer_letter + 4) % 5]$ANY;
               // Sum $may_match_yellow across letters up to 2, and make [1] sticky.
               $may_match_yellow_cnt[1:0] =
                    {#answer_letter == 0 ? 1'b0 : /prev$may_match_yellow_cnt[1], 1'b0} |   // [1] is sticky
                    ({1'b0, $may_match_yellow} +
                     (#answer_letter == 0 ? 2'b0 : {1'b0, /prev$may_match_yellow_cnt[0]})
                    );
            /earlier_letter[#guess_letter - 1:0]
               $match = /_name/guess_letter[#earlier_letter]$letter == /_name/guess_letter[#guess_letter]$letter;
               $may_be_yellow = $match && ! /guess_letter[#earlier_letter]$green;
               /prev
                  $ANY = /earlier_letter[(#earlier_letter + 4) % 5]$ANY;
               $no_yellows_so_far = ! $may_be_yellow &&
                    (#earlier_letter == 0 ? 1'b1 : /prev$no_yellows_so_far);
               $one_yellow_so_far =
                    #earlier_letter == 0 ? $may_be_yellow :
                    $may_be_yellow     ? /prev$no_yellows_so_far :
                                         /prev$one_yellow_so_far;
   
   @_viz
      /_name
         \viz_js
            box: {strokeWidth: 0},
            where: {_where},
         /in[1:0]
            \viz_js
               layout: {top: 15},
            /letter[4:0]
               \viz_js
                  box: {width: 10, height: 10, },
                  template: {letter:  ["Text", "X", {left: 2, top: 1,
                                                     fontFamily: "Roboto Mono", fontSize: 8}]},
                  render() {
                     this.getObjects().letter.set("text", String.fromCharCode('$letter'.asInt() + 65))
                  },
                  renderFill() {
                     if (this.getIndex("in") == m5_guess) {
                        return '/_name/guess_letter[this.getIndex()]$green'.asBool() ? "green" :
                               '/_name/guess_letter[this.getIndex()]$yellow'.asBool() ? "yellow" :
                                   "gray";
                     } else {
                     }
                  },
         /guess_letter[4:0]
            /answer_letter[4:0]
               \viz_js
                  box: {left: 15, width: 10, height: 10},
                  renderFill() {
                     return '$may_match_yellow'.asBool() ? "yellow" : "gray"
                  },
            \viz_js
               // Guess word horizontally beside grid.
               where: {left: -15, top: 30},
               box: {width: 10, height: 10},
               layout: "vertical",
               template: {letter:  ["Text", "X", {left: 2, top: 1,
                                                  fontFamily: "Roboto Mono", fontSize: 8}]},
               render() {
                  this.getObjects().letter.set("text", String.fromCharCode('$letter'.asInt() + 65))
               },
   
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   |wordle
      /in[1:0]
         @1
            $val[31:0] = $rand_val[31:0] & 32'b00000000011100111001110011100111;
      m5+wordle_rslt(|wordle, /wordle_rslt, @1, $out, /in[0]$val, /in[1]$val, [''], @1)

   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
