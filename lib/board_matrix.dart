library zug_chess;

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:zug_chess/zug_chess.dart';

typedef UIImageCallback = void Function(ui.Image image);
typedef RawImageCallback = void Function(Uint8List data);

var boardLogger = Logger(
  printer: PrettyPrinter(),
);

class BoardMatrix {
  final String fen;
  final int width, height;
  final int? maxControl;
  final Color edgeColor;
  final MatrixColorScheme colorScheme;
  final MixStyle mixStyle;
  final bool blackPOV;
  final List<ControlTable>? controlList;
  late final List<Square> squares;
  late final bool offScreen;
  ui.Image? image;

  static List<Square> createSquares({List<ControlTable>? controlList}) { //print("Control List: $controlList");

    return List.generate(controlList?.length ?? numSquares, (i) => Square(
              const Piece(PieceType.none,ChessColor.none),
              (i).isEven ? SquareShade.light : SquareShade.dark, //control: controlList?.elementAt(numSquares - 1 - i) ?? const ControlTable(0, 0)));
              control: controlList?.elementAt(i) ?? const ControlTable(0, 0)));
  }

  BoardMatrix(this.fen,this.width,this.height,UIImageCallback imgCall, {
    this.colorScheme = const MatrixColorScheme(deepYellow, deepBlue, Colors.black),
    this.mixStyle = MixStyle.pigment,
    this.blackPOV  = false,
    this.maxControl,
    this.edgeColor = Colors.black,
    this.controlList,
    this.offScreen = false}) {
    loadImg(imgCall);
  }

  BoardMatrix.fromFEN(this.fen, {required this.colorScheme, this.width = 480, this.height = 480, this.offScreen = false,
    this.mixStyle = MixStyle.pigment, this.maxControl, this.edgeColor = Colors.black, this.blackPOV = false, this.controlList});

  Uint8List generateRawImage() {
    squares = createSquares(controlList: controlList);
    parseFEN();
    updateControl(squaresInitialized: controlList != null);
    return getLinearInterpolation();
  }

  void loadImg(UIImageCallback imgCall) {
    try {
      ui.decodeImageFromPixels(generateRawImage(), width, height, ui.PixelFormat.rgba8888, (ui.Image img) {
        image = img;
        imgCall(img);
      });
    }
    catch (e,s) { boardLogger.w("$e : $s"); }
  }

  void parseFEN() {
    List<String> fenStrs = fen.split(" ");
    _setPieces(fenStrs[0]);
  }

  void _setPieces(String boardStr) {
    List<String> fenRanks = boardStr.split("/");
    for (int rank = 0; rank < fenRanks.length; rank++) {
      int file = 0;
      for (int i = 0; i < fenRanks[rank].length; i++) {
        String char = fenRanks[rank][i];
        Piece piece = Piece.fromChar(char);
        if (piece.type == PieceType.none) {
          file += int.parse(char); //todo: try
        } else {
          if (blackPOV) {
            square(fenRanks.length - 1 - file++, fenRanks.length - 1 - rank).piece = piece;
          } else {
            square(file++,rank).piece = piece;
          }
        }
      }
    }
  }

  int colorVal(ChessColor color) {
    return color == ChessColor.black ? -1 : color == ChessColor.white ? 1 : 0;
  }

  bool isPiece(Coord p, PieceType t) {
    return getSquare(p).piece.type == t;
  }

  Square square(int file, int rank) => squares[Square.index(file,rank)];
  Square getSquare(Coord p) => squares[Square.index(p.x,p.y)];

  int calcMaxControl() {
    int mc = 0;
    for (int y = 0; y < ranks; y++) {
      for (int x = 0; x < files; x++) { //int tc = getSquare(Coord(x,y)).control.totalControl.abs(); //if (tc > mc) mc = tc;
        final sqr = getSquare(Coord(x,y));
        int c = max(sqr.control.whiteControl.abs(),sqr.control.blackControl.abs());
        if (c > mc) mc = c;
      }
    }
    return mc;
  }

  void updateControl({squaresInitialized = false}) {
    int mc = (squaresInitialized && !offScreen) ? calcMaxControl() : maxControl ?? calcMaxControl();  //print("Max Control: $mc");
    for (int y = 0; y < ranks; y++) {
      for (int x = 0; x < files; x++) {
        if (squaresInitialized) { //print("Current Control: ${squares[x][y].control}");
          if (offScreen) {
            square(x,y).control = calcControl(Coord(x,y),cTab: square(x,y).control);
          }
          else {
            square(x,y).setControl(square(x,y).control,colorScheme,mixStyle,mc);
          }
        } else {
          square(x,y).setControl(calcControl(Coord(x,y)),colorScheme,mixStyle,mc);
        }
      }
    }
  }

  ControlTable calcControl(Coord p, {cTab = const ControlTable(0, 0)}) {
    cTab = cTab.add(knightControl(p));
    cTab = cTab.add(diagControl(p));
    cTab = cTab.add(lineControl(p));
    return cTab;
  }

  ControlTable knightControl(Coord p) {
    int blackControl = 0, whiteControl = 0;
    for (int x = -2; x <= 2; x++) {
      for (int y = -2; y <= 2; y++) {
        if ((x.abs() + y.abs()) == 3) {
          Coord p2 = Coord(p.x + x,  p.y + y);
          if (p2.x >= 0 && p2.x < 8 && p2.y >= 0 && p2.y < 8) {
            Piece piece = getSquare(p2).piece;
            if (piece.type == PieceType.knight) {
              piece.color == ChessColor.black ? blackControl++ : whiteControl++;
            }
          }
        }
      }
    }
    return ControlTable(whiteControl,blackControl);
  }

  ControlTable diagControl(Coord p1) {
    int blackControl = 0, whiteControl = 0;
    for (int dx = -1; dx <= 1; dx += 2) {
      for (int dy = -1; dy <= 1; dy += 2) {
        Coord p2 = Coord.fromCoord(p1);
        bool clearLine = true;
        while (clearLine) {
          p2.add(dx,dy);
          clearLine = p2.squareBounds(8);
          if (clearLine) {
            Piece piece = getSquare(p2).piece;
            if (piece.type == PieceType.bishop || piece.type == PieceType.queen) {
              piece.color == ChessColor.black ? blackControl++ : whiteControl++;
            } else if (p1.isAdjacent(p2)) {
              if (piece.type == PieceType.king) {
                piece.color == ChessColor.black ? blackControl++ : whiteControl++;
              } else if (piece.type == PieceType.pawn && piece.color == ChessColor.white && (blackPOV ? p1.y > p2.y : p1.y < p2.y)) {
                whiteControl++;
              } else if (piece.type == PieceType.pawn && piece.color == ChessColor.black && (blackPOV ? p1.y < p2.y : p1.y > p2.y)) {
                blackControl++;
              }
            }
            clearLine = (piece.type == PieceType.none);
          }
        }
      }
    }
    return ControlTable(whiteControl,blackControl);
  }

  ControlTable lineControl(Coord p1) {
    int whiteControl = 0, blackControl = 0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if ((dx == 0) ^ (dy == 0)) {
          Coord p2 = Coord.fromCoord(p1);
          bool clearLine = true;
          while (clearLine) {
            p2.add(dx, dy);
            clearLine = p2.squareBounds(8);
            if (clearLine) {
              Piece piece = getSquare(p2).piece;
              if (piece.type == PieceType.rook || piece.type == PieceType.queen) {
                piece.color == ChessColor.black ? blackControl++ : whiteControl++;
              } else if (p1.isAdjacent(p2)) {
                if (piece.type == PieceType.king) {
                  piece.color == ChessColor.black ? blackControl++ : whiteControl++;
                }
              }
              clearLine = (piece.type == PieceType.none);
            }
          }
        }
      }
    }
    return ControlTable(whiteControl,blackControl);
  }

  Uint8List getLinearInterpolation() {
    Uint8List imgData =  Uint8List(width * height * 4); //ctx.createImageData(board_dim.board_width,board_dim.board_height);

    int squareWidth = (width / ranks).floor();
    int squareHeight = (height / files).floor();
    int paddedBoardWidth = squareWidth * 10, paddedBoardHeight = squareHeight * 10;
    List<List<ColorArray>> pixArray = List<List<ColorArray>>.generate(
        paddedBoardWidth, (i) => List<ColorArray>.generate(
        paddedBoardHeight, (index) => ColorArray.fromFill(0), growable: false), growable: false);

    int w2 = (squareWidth/2).floor(), h2 = (squareHeight/2).floor();
    ColorArray edgeCol = ColorArray.fromColor(edgeColor);

    for (int my = -1; my < ranks; my++) {
      for (int mx = -1; mx < files; mx++) {

        Coord coordNW = Coord(mx, my);
        Coord coordNE = Coord(mx, my + 1);
        Coord coordSW = Coord(mx + 1, my);
        Coord coordSE = Coord(mx + 1, my + 1);

        ColorArray colorNW = coordNW.squareBounds(8) ? getSquare(coordNW).color : edgeCol;
        ColorArray colorNE = coordNE.squareBounds(8) ? getSquare(coordNE).color : edgeCol;
        ColorArray colorSW = coordSW.squareBounds(8) ? getSquare(coordSW).color : edgeCol;
        ColorArray colorSE = coordSE.squareBounds(8) ? getSquare(coordSE).color : edgeCol;
        if (colorSE == null) { boardLogger.w("WTF: $fen"); return imgData; }  //print("$colorSE , $colorSW, $colorNE, $colorNW");

        //TODO: un-reverse this?
        int x = (((coordNW.y + 1) * squareHeight) + h2).floor();
        int y = (((coordNW.x + 1) * squareWidth) + w2).floor();

        for (int i = 0; i < 3; i++) {
          for (int x1 = 0; x1 < squareWidth; x1++) {
            double v = x1 / squareWidth;
            int ly = y + squareHeight;
            int x2 = x + x1;
            if (pixArray.isNotEmpty) {
              //interpolate right
              pixArray[y][x2].values[i] =
                  lerp(v, colorNW.values[i], colorNE.values[i]).floor();
              pixArray[ly][x2].values[i] =
                  lerp(v, colorSW.values[i], colorSE.values[i]).floor();
              //interpolate down
              for (int y1 = 0; y1 < squareHeight; y1++) {
                int y2 = y + y1;
                pixArray[y2][x2].values[i] = lerp(y1 / squareHeight,
                    pixArray[y][x2].values[i], pixArray[ly][x2].values[i]).floor();
              }
            }

          }
        }
      }
    }

    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        int off = ((py * height) + px) * 4;
        int px2 = px + squareWidth;
        int py2 = py + squareHeight;
        imgData[off] = pixArray[px2][py2].values[0];
        imgData[off + 1] = pixArray[px2][py2].values[1];
        imgData[off + 2] = pixArray[px2][py2].values[2];
        imgData[off + 3] = 255;
      }
    }
    return imgData; //ctx.putImageData(imgData,board_dim.board_x,board_dim.board_y);
  }

  double lerp(double v, int start, int end) {
    return (1 - v) * start + v * end;
  }

  @override
  String toString() {
    StringBuffer strBuff = StringBuffer();
    for (int rank = 0; rank < ranks; rank++) {
      for (int file = 0; file < files; file++) {
        strBuff.write("$file,$rank = ${getSquare(Coord(file, rank)).control}");
      }
    }
    return strBuff.toString();
  }

}

