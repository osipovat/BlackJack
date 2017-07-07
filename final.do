vlib work
vlog -timescale 1ps/1ps final.v yellowram300x3.v greenram300x3.v blueram300x3.v redram300x3.v

# Load simulation using mux as the top level simulation module.
vsim -L altera_mf_ver final
#vsim sum_cards_2
# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

# KEY[0] player 1 bet
# KEY[1] player 1 card
# KEY[2] player 2 bet
# KEY[3] player 2 card
# SW[6] done for hitting for player 1
# SW[7] done for betting player 1
# SW[2] done for hitting for player 2
# SW[1] done for betting player 2

force {SW[1]} 0 0, 1 140 -r 180
force {SW[2]} 0 0, 1 230 -r 250
force {SW[6]} 0 0, 1 160 -r 200
force {SW[7]} 0 0, 1 70 -r 80 
force {SW[9]} 1 0, 0 12 
force {CLOCK_50} 0 0, 1 5 -r 10
force {KEY[3]} 0 0, 1 190 -r 230
force {KEY[1]} 0 0, 1 135 -r 170
force {KEY[0]} 1 0, 0 60 -r 120
force {KEY[2]} 0 0, 1 60 -r 120
run 10000ps