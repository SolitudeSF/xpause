# Package

version       = "0.1.0"
author        = "SolitudeSF"
description   = "Pause/unpause process of X window"
license       = "MIT"
srcDir        = "src"
bin           = @["xpause"]


# Dependencies

requires "nim >= 1.6.0", "xcb"
