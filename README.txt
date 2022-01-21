
                ###################################
                #                                 #
                #         CARRYABLE PIPES         #
                #                                 #
                #  made in 2019 by WhiteYoshiEgg  #
                #                                 #
                ###################################

This sprite is used in pairs. You can carry them around, and when you enter
one of them, like a pipe, you'll be teleported to the other end.

You can have up to four different pairs in a level at the same time, which act
independently of each other and are distinguished by their color. The pairing
depends on the extra byte.

A pair of pipes only works when there are exactly two of them in the level,
and both are spawned (=the player has encountered both); they won't let you
enter otherwise.


MAIN FEATURES
    - Works at any distance
    - Works with Lunar Magic 3's extended levels
    - Works with Yoshi (even swallowable by Yoshi!)
    - Four independent pairs of pipes
    - Only one sprite to insert, no separate entrance/exit sprites, no uberASM

DRAWBACKS AND LIMITATIONS
    - Only works when there are exactly two pipes per pair spawned in the level
    - Only 16x16 pipes
    - Only enterable from the top
    - You can't carry anything through them (they won't allow you to enter)
    - May cause a bit of slowdown when more than one pair is active
    - Sprites may not spawn when you exit a pipe, as well as during teleporting

HOW TO USE
    - Just place two of them in a level and you're good!
    - To change the pipe color (=what pair the pipe belongs to),
      change the extra byte:
      00: green
      01: red
      02: blue
      03: yellow
      (04 and higher may technically work but probably won't look right)
    - Due to the sprite actually inserting a small hijack to fix some bugs
      (see the !FixFreeze define in the sprite), if you remove the sprite
      from Pixi while that hijack is applied, you should use the
      unpatchPipes.asm patch to remove it or your game will crash.

ALSO OF NOTE
    - If the pipe tiles appear in front of the player even when you're not
      entering them, try a different sprite memory setting (Lakitu button
      in Lunar Magic).
    - If you're using Lunar Magic 3's extended level sizes and pipes despawn,
      change the vertical spawn range (Lakitu button in Lunar Magic).

CREDIT?
    - It'd be awesome, but I can't force you, so whatever.
    
CHANGELOG
    - October 25, 2019:
        - Fixed a typo that would prevent you from entering a pipe
          when the ON/OFF switch was set to OFF
    - October 16, 2019 (by Thomas):
        - Added an (optional) hijack to fix a bug with freezing sprites
        - Prevented Yoshi from being able to eat the pipe during use
        - Fixed SA-1 support so that pipes don't disappear during
          transportation
    - August 1, 2019:
        - Disabled entering a pipe when a message box is active
        - Disabled entering a pipe when the other is in Yoshi's mouth
        - Disabled entering a pipe when the other is on the horizontal
          edges of the level

THANKS FOR HELP, BUG REPORTS AND SUGGESTIONS
    - GreenHammerBro
    - lx5
    - DKR_02
    - dtothefourth
    - Thomas

FOUND A BUG?
    - nooooooo please spare me i don't wanna spend any more time on this
