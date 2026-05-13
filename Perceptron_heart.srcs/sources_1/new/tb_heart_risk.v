`timescale 1ns / 1ps

module tb_heart_risk;

    reg clk;
    reg reset;
    reg btn_enter;
    reg [7:0] sw;

    wire red_led;
    wire green_led;
    wire buzzer;
    wire [6:0] seg;
    wire [3:0] an;

    // =========================
    // DUT
    // =========================
    heart_risk_minimal uut (
        .clk(clk),
        .reset(reset),
        .btn_enter(btn_enter),
        .sw(sw),
        .red_led(red_led),
        .green_led(green_led),
        .buzzer(buzzer),
        .seg(seg),
        .an(an)
    );

    // =========================
    // CLOCK (100 MHz)
    // =========================
    always #5 clk = ~clk;

    // =========================
    // BUTTON PRESS (SYNC FIX)
    // =========================
    task press_button;
    begin
        @(posedge clk);
        btn_enter = 1;

        @(posedge clk);
        @(posedge clk);

        btn_enter = 0;

        repeat(10) @(posedge clk); // allow FSM update
    end
    endtask

    // =========================
    // ENTER 8 INPUTS
    // =========================
    task enter_inputs;
        input [7:0] a1,a2,a3,a4,a5,a6,a7,a8;
    begin
        sw=a1; press_button();
        sw=a2; press_button();
        sw=a3; press_button();
        sw=a4; press_button();
        sw=a5; press_button();
        sw=a6; press_button();
        sw=a7; press_button();
        sw=a8; press_button();
    end
    endtask

    // =========================
    // MONITOR (DEBUG)
    // =========================
    initial begin
        $monitor("TIME=%0t | STAGE=%0d | SUM=%0d | RISK=%b | RED=%b GREEN=%b BUZZER=%b",
                 $time, uut.stage, uut.sum, uut.risk,
                 red_led, green_led, buzzer);
    end

    // =========================
    // TEST SEQUENCE
    // =========================
    initial begin
        clk = 0;
        reset = 1;
        btn_enter = 0;
        sw = 0;

        // RESET
        repeat(10) @(posedge clk);
        reset = 0;

        // =====================
        // 🟢 GOOD
        // =====================
        $display("===== GOOD =====");
        enter_inputs(
            8'b00011110,
            8'b01100100,
            8'b01101110,
            8'b01010000,
            8'b01000110,
            8'b00011001,
            8'b01111000,
            8'b00000000
        );

        repeat(50) @(posedge clk);

        // =====================
        // 🟡 AUG
        // =====================
        $display("===== AUG =====");
        enter_inputs(
            8'b00111100,
            8'b01010000,
            8'b11011100,
            8'b00111100,
            8'b11001101,
            8'b00010010,
            8'b01011010,
            8'b00000000
        );

        repeat(50) @(posedge clk);

        // =====================
        // 🟠 LOU
        // =====================
        $display("===== LOU =====");
        enter_inputs(
            8'b01000110,
            8'b00111100,
            8'b11110000,
            8'b00110010,
            8'b11011100,
            8'b00010010,
            8'b00111100,
            8'b11111111
        );

        repeat(50) @(posedge clk);

        // =====================
        // 🔴 HIGH
        // =====================
        $display("===== HIGH =====");
        enter_inputs(
            8'b01011010,
            8'b00101000,
            8'b11111111,
            8'b00101000,
            8'b11111111,
            8'b00001010,
            8'b00010100,
            8'b11111111
        );

        repeat(100) @(posedge clk);

        $stop;
    end

endmodule