module bloom_set
    (
        input clk_i,
        input rst_i,
        input [58:0]    data_i,
        output match_o
    )

wire [6:0] hash_w[3:0];

  h3_gen hg0 (
    .data_i({data_i}),
    .seed_i(7'd0),
    
    .hash_o(hash_w[4'h0])
  );
  
  h3_gen hg1 (
    .data_i({data_i}),
    .seed_i(7'd1),
    
    .hash_o(hash_w[4'h1])
  );

  h3_gen hg2 (
    .data_i({data_i}),
    .seed_i(7'd2),
    
    .hash_o(hash_w[4'h2])
  );

  h3_gen hg3 (
    .data_i({data_i}),
    .seed_i(7'd3),
    
    .hash_o(hash_w[4'h3])
  );

  h3_gen hg4 (
    .data_i({data_i}),
    .seed_i(7'd4),
    
    .hash_o(hash_w[4'h4])
  );

  h3_gen hg5 (
    .data_i({data_i}),
    .seed_i(7'd5),
    
    .hash_o(hash_w[4'h5])
  );
  
  h3_gen hg6 (
    .data_i({data_i}),
    .seed_i(7'd6),
    
    .hash_o(hash_w[4'h6])
  );

  h3_gen hg7 (
    .data_i({data_i}),
    .seed_i(7'd7),
    
    .hash_o(hash_w[4'h7])
  );

  h3_gen hg8 (
    .data_i({data_i}),
    .seed_i(7'd8),
    
    .hash_o(hash_w[4'h8])
  );

  bloom_filter bf0 (
    .rst_i(rst_i),
    .hash0_i    (hash_w[0]),
    .hash1_i    (hash_w[1]),
    .hash2_i    (hash_w[2]),
    .hash3_i    (hash_w[3]),
    .hash4_i    (hash_w[4]),
    .hash5_i    (hash_w[5]),
    .hash6_i    (hash_w[6]),
    .hash7_i    (hash_w[7]),
    .hash8_i    (hash_w[8]),
    .clk_i      (clk_i), 

    .match_o    (match_o)
  );

endmodule