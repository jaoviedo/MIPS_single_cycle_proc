module tb();

    reg clk, reset;

    top dut (clk, reset);
	
    initial begin
	clk = 0;
	forever #10 clk = ~clk;
    end
    initial begin
	reset = 1;
	#100;
	reset = 0;
    end
    // always@(negedge clk)begin
    //     if(memwrite)begin
    //         if()begin
                
    //         end
    //     end
    //     else if()
    // end
    
    
endmodule