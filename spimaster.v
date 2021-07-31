module spimaster(clk,rst,start,MODE,TxData,RxData,
                 Sclk,SS,MOSI,MISO,finish);
  
  input clk,rst,start;
  input [1:0] MODE;
  input [7:0] TxData;
  output reg [7:0] RxData;
  output reg finished;
  //
  input MISO;
  output reg SS,Sclk;
  output reg MOSI;
  //
  
  wire CPOL = (MODE == 2) || (MODE == 3);
  wire CPHA = (MODE == 1) || (MODE == 3);
  
  
  reg [5:0] clk_count;
  reg [5:0] data_count = 0;
  reg [7:0] MasterReg;
 
  ////

  
  always @(posedge clk)
      
        case(CPOL)
          1'b0:begin
                 if(start)
                    begin
                       Sclk <= 1;
                       clk_count <= 0;
                       SS <= 0;
                       MasterReg <= TxData;
                    end
                   else if(clk_count == 3)
                     begin
                       Sclk <= ~Sclk;
                       clk_count <= 0;
                     end  
                   else
                     begin
                      Sclk <= Sclk;
                      clk_count <= clk_count + 1;
                    end
                end
  
  
            1'b1:begin
                 if(start)
                    begin
                       Sclk <= 0;
                       clk_count <= 0;
                       SS <= 0;
                       MasterReg <= TxData;
                    end
              else if(clk_count == 3)
                     begin
                       Sclk <= ~Sclk;
                       clk_count <= 0;
                     end  
                   else
                     begin
                      Sclk <= Sclk;
                      clk_count <= clk_count + 1;
                    end
            end 
           default:;
     endcase
  
 
  reg [5:0]sclkcount=0;
    
  output reg finish;
   
  always@(posedge Sclk)
      begin
        if(sclkcount==8)
          begin
            finish <= 1;
            SS <= 1;
            sclkcount <= sclkcount +1;
          end  
        else if((sclkcount>=0)&&(sclkcount<8))
          begin
            finish <= 0;
            SS <= 0;
            sclkcount <= sclkcount +1;
          end
        else if(sclkcount ==9)
             sclkcount <= 0;
        else 
          begin
            finish <= 0;
            SS <= SS;
            sclkcount <= sclkcount  ;
          end
      end
    
          
  
  always@(posedge clk)
    if (rst)
      begin
      MasterReg <= 0;
      data_count <= 0;
      Sclk <= CPOL;
      //RxData <= 0;  
      end
  
  
  always@(posedge start)
          MasterReg <= TxData;
  
  
   //always@(*)
   // begin
    //  if((MODE==0)&&(sclkcount == 1))
     //   MOSI = TxData[7];
    //end
  
  
  
  always@(posedge Sclk)
    begin
      case(MODE)
        2'b00:
              RxData <= {RxData[6:0],MISO};
             
        2'b01:begin
               MasterReg <= {MasterReg[6:0],1'b0};
               MOSI <= MasterReg [7];
              end
        
        2'b10:begin
               MasterReg <= {MasterReg[6:0],1'b0};
               MOSI <= MasterReg [7];
              end
        
        2'b11:
              RxData <= {RxData[6:0],MISO};
        default:;
      endcase  
    end
      
       
  always@(negedge Sclk)
    begin
      case(MODE)
        
        2'b00:begin
              MasterReg <= {MasterReg[6:0],1'b0};
              MOSI <= MasterReg [7];
              end
        
        2'b01: RxData <= {RxData[6:0],MISO};
          
        2'b10: RxData <= {RxData[6:0],MISO};
          
        2'b11:begin
              MasterReg <= {MasterReg[6:0],1'b0};
              MOSI <= MasterReg [7];
              end
        
        default:;
      endcase  
    end
      
  
  reg [5:0]sclkcountdelayed;
  always@(negedge Sclk)
      sclkcountdelayed <= sclkcount;
  
  reg [7:0] masterreceived;
  always@(sclkcount,sclkcountdelayed)
    case(MODE)
      0: if(sclkcount==9)
           masterreceived <= RxData;
      1: if(sclkcountdelayed == 8)
           masterreceived <= RxData;
      2: if(sclkcountdelayed == 8)
            masterreceived <= RxData;
      3: if(sclkcount ==8)
           masterreceived <= RxData;
      default:;
    endcase  
      
endmodule     
