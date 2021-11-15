module tb();

    reg clk, reset;

    top dut (clk, reset);
	
    initial
        begin
            reset <= 1;
            #22;
            reset <= 0;
        end
    integer i = 0;
    always
        begin
            //if(i < 13)begin
              clk <= 1; 
              #5; 
              clk <= 0; 
	      #5;
              i = i + 1;
	    //end else begin
              //$stop;
            //end
        end
    // always@(negedge clk)begin
    //     if(memwrite)begin
    //         if()begin
                
    //         end
    //     end
    //     else if()
    // end
    
    
endmodule