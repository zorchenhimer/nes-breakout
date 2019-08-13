--This is an example script to give a general idea of how to build scripts
--Press F5 or click the Run button to execute it
--Scripts must be written in Lua (https://www.lua.org)
--This text editor contains an auto-complete feature for all Mesen-specific functions
--Typing "emu." will display a list containing every available API function to interact with Mesen

colorRed = 0x80FF0000
paddleYOffset = 3
paddleXOffset = 11

function printInfo()
  paddleY = emu.read(emu.getLabelAddress("PaddleY+1"), emu.counterMemType.nesRam, false)
  paddleX = emu.read(emu.getLabelAddress("PaddleX+1"), emu.counterMemType.nesRam, false)
  
  ballY = emu.read(emu.getLabelAddress("BallY+1"), emu.counterMemType.nesRam, false)
  ballX = emu.read(emu.getLabelAddress("BallX+1"), emu.counterMemType.nesRam, false)
  
  -- top of paddle
  emu.drawLine(0, paddleY - paddleYOffset, 255, paddleY - paddleYOffset, colorRed, 1, 0)
  -- right
  emu.drawLine(paddleX + paddleXOffset, 0, paddleX + paddleXOffset, 255, colorRed, 1, 0)
  -- left
  emu.drawLine(paddleX - paddleXOffset, 0, paddleX - paddleXOffset, 255, colorRed, 1, 0)
  
  -- crosshair on ball
  emu.drawLine(0, ballY, 255, ballY, colorRed, 1, 0)
  emu.drawLine(ballX, 0, ballX, 255, colorRed, 1, 0)
end

--Register some code (printInfo function) that will be run at the end of each frame
emu.addEventCallback(printInfo, emu.eventType.endFrame)
