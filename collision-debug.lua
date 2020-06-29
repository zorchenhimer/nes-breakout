x = 80
y = 64
width = 12 * 8
height = 6 * 8

function drawBoardBounds()
    emu.drawRectangle(x, y, width, height, 0x000000FF, false)

    tmpX = emu.read(emu.getLabelAddress("TmpX"), emu.memType.Cpu)
    tmpY = emu.read(emu.getLabelAddress("TmpY"), emu.memType.Cpu)

    emu.drawPixel(tmpX, tmpY, 0x00FF0000)
end

--Register some code (printInfo function) that will be run at the end of each frame
--emu.addEventCallback(drawBoardBounds, emu.eventType.startFrame)
emu.addMemoryCallback(drawBoardBounds, emu.memCallbackType.cpuExec, 0x8DD9, 0x8E63)
drawBoardBounds()