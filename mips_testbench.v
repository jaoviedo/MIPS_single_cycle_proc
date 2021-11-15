module tb();

    wire clk, reset;

    top dut (clk, reset);

    initial
        begin
            reset <= 1;
            #22;
            reset <= 0;
        end
    always
        begin
            clk <= 1; #5; clk <= 0; #5;
        end
    // always@(negedge clk)begin
    //     if(memwrite)begin
    //         if()begin
                
    //         end
    //     end
    //     else if()
    // end
    
    
endmodule