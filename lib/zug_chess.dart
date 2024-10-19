library zug_chess;

import 'dart:js' as js;
import 'package:chess/chess.dart' as dc;
import 'dart:math';
import 'package:flutter/material.dart';

enum PieceStyle  {
  cburnett,
  merida,
  pirouetti,
  chessnut,
  chess7,
  alpha,
  reillycraig,
  companion,
  riohacha,
  kosal,
  leipzig,
  fantasy,
  spatial,
  celtic,
  california,
  caliente,
  pixel,
  maestro,
  fresca,
  cardinal,
  gioco,
  tatiana,
  staunty,
  governor,
  dubrovny,
  icpieces,
  libra,
  mpchess,
  shapes,
  kiwenSuwi,
  horsey,
  anarcandy,
  letter,
  disguised,
  symmetric;
}

enum GameStyle {
  bullet,blitz,rapid,classical
}

const startFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
const ranks = 8, files = 8;
int get numSquares => (ranks * files);

enum ChessColor {
  none("x",null),
  white("w",dc.Color.WHITE),
  black("b",dc.Color.BLACK);
  final String fileLetter;
  final dc.Color? dartChessColor;
  const ChessColor(this.fileLetter,this.dartChessColor);
}
enum PieceType {
  unknown("?",null),
  none("X",null),
  pawn("P",dc.PieceType.PAWN),
  knight("N",dc.PieceType.KNIGHT),
  bishop("B",dc.PieceType.BISHOP),
  rook("R",dc.PieceType.ROOK),
  queen("Q",dc.PieceType.QUEEN),
  king("K",dc.PieceType.KING);
  final String fileLetter;
  final dc.PieceType? dartChessType;
  const PieceType(this.fileLetter, this.dartChessType);
}

enum ColorComponent {red,green,blue}

const Color deepBlue = Color(0xFF0000FF);
const Color deepRed = Color(0xFFFF0000);
const Color deepYellow = Color(0xFFFFFF00);

enum ColorStyle {
  heatmap(MatrixColorScheme(deepBlue,deepRed,Colors.black)),
  lava(MatrixColorScheme(deepYellow,deepRed,Colors.black)),
  rainbow(MatrixColorScheme(deepYellow,deepBlue,Colors.black)),
  forest(MatrixColorScheme(Color(0xffd8ffb0),Color(0xff171717),Color(0xff76c479),blackPieceBlendColor: Color(0xff92cf94),whitePieceBlendColor: Color(0xff14ffe9))),
  mono(MatrixColorScheme(Colors.white,Colors.black,Colors.grey)),
  ;
  final MatrixColorScheme colorScheme;
  const ColorStyle(this.colorScheme);
}
enum MixStyle {pigment,checker,additive, none}

class ColorArray {
  final List<int> values;
  int get red => values[0]; set addRed(int i) => values[0] += i;
  int get green => values[1]; set addGreen(int i) => values[1] += i;
  int get blue => values[2]; set addBlue(int i) => values[2] += i;
  ColorArray.fromFill(final int v) : values = List.filled(3, 0);
  ColorArray.fromColor(Color c) : values = [c.red,c.green,c.blue];
  ColorArray(final int red, final int green, final int blue) : values = List.of([red,green,blue]);
  @override
  String toString() {
    return "[$red,$green,$blue]";
  }
}

class MatrixColorScheme {
  final Color whiteColor;
  final Color blackColor;
  final Color voidColor;
  final Color whitePieceBlendColor;
  final Color blackPieceBlendColor;
  final Color gridColor;
  final Color edgeColor;

  const MatrixColorScheme(this.whiteColor,this.blackColor,this.voidColor, {
    this.whitePieceBlendColor = const Color.fromARGB(255, 255, 231, 20 ),
    this.blackPieceBlendColor = const Color.fromARGB(255, 20, 255, 233 ),
    this.gridColor = const Color.fromARGB(72, 255, 255, 255),
    this.edgeColor = Colors.black,
  });
}

class ControlTable {
  final int whiteControl;
  final int blackControl;
  int get totalControl => whiteControl - blackControl;
  const ControlTable(this.whiteControl,this.blackControl);
  ControlTable add(ControlTable ctab) {
    return ControlTable(whiteControl + ctab.whiteControl, blackControl + ctab.blackControl);
  }
  @override
  String toString() {
    return "[$whiteControl,$blackControl,$totalControl]";
  }
}

enum SquareShade {
  light,dark
}

class Square {

  static int index(int file, int rank) {
    return (rank * 8) + file;
  }

  final Color bigRed = const Color.fromARGB(255, 255, 0, 0);
  final Color bigGreen = const Color.fromARGB(255, 0,255, 0);
  final Color bigBlue = const Color.fromARGB(255, 0,0, 255);
  SquareShade shade;
  Piece piece;
  ControlTable control;
  ColorArray color = ColorArray.fromFill(0);
  Square(this.piece,this.shade, {this.control = const ControlTable(0, 0)});

  void setControl(ControlTable c, MatrixColorScheme colorScheme, MixStyle mixStyle, int maxControl) {
    control = c;
    color = switch(mixStyle) {
      MixStyle.none => getUnmixedColor(colorScheme, maxControl),
      MixStyle.checker => getCheckerColor(colorScheme, maxControl),
      MixStyle.pigment => getMixColor(colorScheme, maxControl, false),
      MixStyle.additive => getMixColor(colorScheme, maxControl, true),
    };
  }

  ColorArray getUnmixedColor(MatrixColorScheme colorScheme, int maxControl) {
    ColorArray colorMatrix = ColorArray.fromColor(colorScheme.voidColor);
    double controlGrad =  min(control.totalControl.abs(),maxControl) / maxControl;
    if (control.totalControl > 0) {
      colorMatrix.addRed = ((colorScheme.whiteColor.red - colorScheme.voidColor.red) * controlGrad).floor();
      colorMatrix.addGreen = ((colorScheme.whiteColor.green - colorScheme.voidColor.green) * controlGrad).floor();
      colorMatrix.addBlue = ((colorScheme.whiteColor.blue - colorScheme.voidColor.blue) * controlGrad).floor();
    } else if (control.totalControl < 0) {
      colorMatrix.addRed = ((colorScheme.blackColor.red - colorScheme.voidColor.red) * controlGrad).floor();
      colorMatrix.addGreen = ((colorScheme.blackColor.green - colorScheme.voidColor.green) * controlGrad).floor();
      colorMatrix.addBlue = ((colorScheme.blackColor.blue - colorScheme.voidColor.blue) * controlGrad).floor();
    } //if (control.totalControl != 0) print("${control.totalControl} -> ${colorMatrix.values}");
    return colorMatrix;
  }

  ColorArray getCheckerColor(MatrixColorScheme colorScheme, int maxControl) {
    double whiteControlGrad =  min(control.whiteControl,maxControl) / maxControl;
    double blackControlGrad =  min(control.blackControl,maxControl) / maxControl;
    return ColorArray(
      (255 * blackControlGrad).floor(),
      shade == SquareShade.dark ? 0 : 255,
      (255 * whiteControlGrad).floor(),
    );
  }

  ColorArray getMixColor(MatrixColorScheme colorScheme, int maxControl, bool additive) {
    double whiteControlGrad =  min(control.whiteControl,maxControl) / maxControl;
    double blackControlGrad =  min(control.blackControl,maxControl) / maxControl;

    ColorArray whiteMatrix = ColorArray(
        (colorScheme.whiteColor.red * whiteControlGrad).floor(),
        (colorScheme.whiteColor.green * whiteControlGrad).floor(),
        (colorScheme.whiteColor.blue * whiteControlGrad).floor());

    ColorArray blackMatrix = ColorArray(
        (colorScheme.blackColor.red * blackControlGrad).floor(),
        (colorScheme.blackColor.green * blackControlGrad).floor(),
        (colorScheme.blackColor.blue * blackControlGrad).floor());

    if (control.whiteControl == 0 && control.blackControl >  0) {
      return blackMatrix;
    } else if (control.whiteControl > 0 && control.blackControl == 0) {
      return whiteMatrix;
    } else if (control.whiteControl == 0 && control.blackControl == 0) {
      return ColorArray.fromColor(colorScheme.voidColor);
    }

    if (additive) {
      return ColorArray(
          max(whiteMatrix.red,blackMatrix.red),
          max(whiteMatrix.green,blackMatrix.green),
          max(whiteMatrix.blue,blackMatrix.blue)
      );
    } else {
      var mixedColor = js.context.callMethod("mixColors",[
        whiteMatrix.red,whiteMatrix.green,whiteMatrix.blue,
        blackMatrix.red,blackMatrix.green,blackMatrix.blue,
        .5 //TODO: show diffs
      ]); //print("Mixed Color: $mixedColor");
      return ColorArray(mixedColor[0], mixedColor[1], mixedColor[2]);
    }
  }
}

class Piece {
  static final Map<String,Image> imgMap = {};
  final PieceType type;
  final ChessColor color;
  static const whitePieces = [
     Piece(PieceType.pawn,ChessColor.white),
     Piece(PieceType.knight,ChessColor.white),
     Piece(PieceType.bishop,ChessColor.white),
     Piece(PieceType.rook,ChessColor.white),
     Piece(PieceType.queen,ChessColor.white),
     Piece(PieceType.king,ChessColor.white),
  ];
  static const blackPieces = [
    Piece(PieceType.pawn,ChessColor.black),
    Piece(PieceType.knight,ChessColor.black),
    Piece(PieceType.bishop,ChessColor.black),
    Piece(PieceType.rook,ChessColor.black),
    Piece(PieceType.queen,ChessColor.black),
    Piece(PieceType.king,ChessColor.black),
  ];

  static PieceType _decodePieceType(dc.PieceType pt) {
    return switch(pt) {
      dc.PieceType.PAWN => PieceType.pawn,
      dc.PieceType.KNIGHT => PieceType.knight,
      dc.PieceType.BISHOP => PieceType.bishop,
      dc.PieceType.ROOK => PieceType.rook,
      dc.PieceType.QUEEN => PieceType.queen,
      dc.PieceType.KING => PieceType.king,
      dc.PieceType() => PieceType.none, //eh?
    };
  }

  static PieceType _decodeChar(String char) {
    return switch(char.toUpperCase()) {
      "P" => PieceType.pawn,
      "N" => PieceType.knight,
      "B" => PieceType.bishop,
      "R" => PieceType.rook,
      "Q" => PieceType.queen,
      "K" => PieceType.king,
      "U" => PieceType.unknown,
      _ => PieceType.none,
    };
  }

  const Piece(this.type,this.color);
  Piece.fromChar(String char) :
        type = _decodeChar(char),
        color = char == char.toUpperCase() ? ChessColor.white : ChessColor.black;

  Piece.fromDartChess(dc.Piece p) :
    type = _decodePieceType(p.type),
    color = p.color == dc.Color.BLACK ? ChessColor.black : ChessColor.white;


  Piece.fromDartChessType(dc.PieceType pt, this.color) :
    type = _decodePieceType(pt);


  bool eq(PieceType t, ChessColor c) {
    return type == t && color == c;
  }

  String toFilename({ext = ".png"}) {
    return toString() + ext;
  }

  String toLetter({bool capColor = true}) {
    String letter = (type == PieceType.knight) ? "n" : (type == PieceType.none) ? "x" : type.name[0];
    return color == ChessColor.white ? letter.toUpperCase() : letter.toLowerCase();
  }

  @override
  String toString({bool white = false}) { //String pieceChar = (type == PieceType.knight) ? "n" : (type == PieceType.none) ? "x" : type.name[0];
    return (white || color == ChessColor.white ? "w" : "b") + toLetter(capColor: false).toUpperCase();
  }
}

class Move {
  final String moveStr;
  late final PieceType prom;
  late final Coord from, to;
  get fromStr => moveStr.substring(0,2);
  get toStr => moveStr.substring(2,4);

  Move(this.moveStr) {
    from = Coord(moveStr.codeUnitAt(0) - "a".codeUnitAt(0),7 - (moveStr.codeUnitAt(1) - "1".codeUnitAt(0)));
    to = Coord(moveStr.codeUnitAt(2) - "a".codeUnitAt(0),7 - (moveStr.codeUnitAt(3) - "1".codeUnitAt(0)));
    prom = (moveStr.length == 5) ? Piece.fromChar(moveStr[4]).type : PieceType.none;
  }

  dynamic toJson() {
    if (moveStr.length == 4) {
      return {'from': moveStr.substring(0,2), 'to': moveStr.substring(2,4)};
    }
    else if (moveStr.length == 5) {
      return {'from': moveStr.substring(0,2), 'to': moveStr.substring(2,4), 'promotion': moveStr[4]};
    }
    return {};
  }

  bool eq(Move move) {
    return from.eq(move.from) && to.eq(move.to);
  }

  @override
  String toString() {
    return moveStr;
  }

  static coord2Int(Coord c) {
    return c.x + (c.y * ranks);
  }
}

class Coord {
  int x,y;
  Coord(this.x,this.y);
  Coord.fromCoord(Coord p) : x = p.x, y = p.y;
  void add(int x1, int y1) {
    x += x1; y += y1;
  }
  bool squareBounds(int n) {
    return x >= 0 && y >= 0 && x < n && y < n;
  }
  bool isAdjacent(Coord p) {
    return (p.x - x).abs() < 2 && (p.y - y).abs() < 2;
  }
  bool eq(Coord p) {
    return x == p.x && y == p.y;
  }
  @override
  String toString() {
    return "[$x,$y]";
  }
}

class MoveState {
  final String? beforeFEN;
  final String afterFEN;
  final Move move;
  final int whiteClock, blackClock;
  late Piece piece;
  late ChessColor turn;
  //late final bool isCheck, isCapture, isCastle, isEP, isProm; //TODO: calc

  MoveState(this.move,this.whiteClock,this.blackClock,this.beforeFEN,this.afterFEN) {
    final game = dc.Chess.fromFEN(afterFEN);
    final p = game.get(move.toStr);
    turn = getTurnFromFEN(afterFEN);
    piece = p != null ? Piece.fromDartChess(p) : Piece(PieceType.king,turn);
  }
}

ChessColor getTurnFromFEN(String? fen) {
  if (fen == null) return ChessColor.white;
  final fenFields = fen.split(" ");
  return fenFields.length > 1 ? (fenFields[1] == "b" ? ChessColor.black : ChessColor.white) : ChessColor.none;
}

class Player {
  final String name;
  final int rating;
  int clock = 0;

  Player.fromTV(dynamic data) : name = data['user']['name'], rating = int.parse(data['rating'].toString());
  Player.fromSeek(dynamic data) : name = data['id'], rating = data['rating'];

  void nextTick() {
    if (clock > 0) clock--;
  }

  //TODO: improve?
  String _formattedTime(int seconds) {
    final int hour = (seconds / 3600).floor();
    final int minute = ((seconds / 3600 - hour) * 60).floor();
    final int second = ((((seconds / 3600 - hour) * 60) - minute) * 60).round();
    return [
      if (hour > 0) hour.toString().padLeft(2, "0"),
      minute.toString().padLeft(2, "0"),
      second.toString().padLeft(2, '0'),
    ].join(':');
  }

  @override
  String toString({bool showTime = true}) {
    String info = "$name ($rating)";
    return showTime ? "$info: ${_formattedTime(clock)}" : info;
  }
}


