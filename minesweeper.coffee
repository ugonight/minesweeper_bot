# Description:
#   hubot用マインスイーパ
#
# Notes:
#   ゲーム実装参考:http://vivi.dyndns.org/tech/games/minesweeper.html

N_MINE  =   10  #   爆弾数
BD_WD   =   9   #   盤面横数
BD_HT   =   9   #   盤面縦数
BD_MAX  =   (BD_WD+2)*(BD_HT+2) #配列の最大値

play = false    #   ゲームが始まっているかどうか

open = [0...BD_MAX]  #   マス目を開いているかどうか
mine = [0...BD_MAX]  #   爆弾があるかどうか
nMine = [0...BD_MAX] #   0-8: 周りの爆弾の数

#   盤面初期化
init_board = ->
    for x in [0...BD_WD+2]
        for y in [0...BD_HT+2]
            mine[x * (BD_WD+2) + y] = false
            nMine[x * (BD_WD+2) + y] = 0
            open[x * (BD_WD+2) + y] = false

    #   爆弾を配置
    for i in [0...N_MINE]
        loop
            x = Math.floor(Math.random() * BD_WD) + 1   #   [1, BD_WD]
            y = Math.floor(Math.random() * BD_HT) + 1   #   [1, BD_HT]
            break unless mine[x * (BD_WD+2) + y] is true #   既に爆弾が置いてある
        mine[x * (BD_WD+2) + y] = true
        #   8近傍の爆弾数をインクリメント
        nMine[(x-1) * (BD_WD+2) + y-1] += 1
        nMine[x * (BD_WD+2) + y-1] += 1
        nMine[(x+1) * (BD_WD+2) + y-1] += 1
        nMine[(x-1) * (BD_WD+2) + y] += 1
        nMine[(x+1) * (BD_WD+2) + y] += 1
        nMine[(x-1) * (BD_WD+2) + y+1] += 1
        nMine[x * (BD_WD+2) + y+1] += 1
        nMine[(x+1) * (BD_WD+2) + y+1] += 1

    
    return

digitStr = ['１','２','３','４','５','６','７','８','９']

#   盤面表示
print_board = ->
    message = ""
    message += "\n　ａｂｃｄｅｆｇｈｉ\n"
    for y in [1..BD_HT]
        message += digitStr[y-1]
        for x in [1..BD_WD]
            if open[x * (BD_WD+2) + y] is false  #   開いていない
                message += "■"
            else if mine[x * (BD_WD+2) + y] is true  #   地雷有り
                message += "★"
            else if nMine[x * (BD_WD+2) + y] is 0    #   周りに地雷無し
                message += "・"
            else                    #   周りに地雷有り
                message += " " + nMine[x * (BD_WD+2) + y]
        message += "\n"
    message += "\n"
    message

#	(x, y) を開く、x は [1, BD_WD], y は [1, BD_HT] の範囲
#	周りの爆弾数がゼロならば、周りも開く
open = (x, y) ->
    if (x < 1) or (x > BD_WD) or (y < 1) or (y > BD_HT) #   範囲外の場合
        return
    if open[x * (BD_WD+2) + y] is true   #   既に開いている場合
        return
    open[x * (BD_WD+2) + y] = true
    if (mine[x * (BD_WD+2) + y] is false) and (nMine[x * (BD_WD+2) + y] is false) #   そこに爆弾が無く、周りにも爆弾が無い場合
        open(x-1, y-1)  #周りも開く
        open(x, y-1)
        open(x-1, y)
        open(x+1, y)
        open(x-1, y+1)
        open(x, y+1)
        open(x+1, y+1)
    return

#   爆弾箇所以外が全て開いていれば、成功
checkSweeped = ->
    for x in [1..BD_WD]
        for y in [1..BD_HT]
            if (mine[x * (BD_WD+2) + y] is false) and (open[x * (BD_WD+2) + y] is false)
                false
                return

    true
    return

module.exports = (robot) ->
    robot.respond /start/i, (msg) ->
        play = true
        init_board()
        msg.send print_board()
        msg.send "where will you open ? [a-i][1-9]"

    alphaStr = ['a','b','c','d','e','f','g','h','i']

    robot.respond /([a-i][1-9])/i, (msg) ->
        if play
            buffer = msg.match[1]
            x = 0
            y = 0
            for i in [0..8]
                if buffer[0] is alphaStr[i]
                    x = i + 1
                    break
            y = parseInt(buffer[1],10)
            open(x, y)
            msg.send print_board()

            if checkSweeped()
                msg.send "Good-Job !!!  you've sweeped all Mines in success.\n"
                play = false
            else if mine[x * (BD_WD+2) + y]
                msg.send "Oops !!! You've stepped on a Mine...\n\n"
                play = false