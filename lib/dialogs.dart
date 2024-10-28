import 'package:flutter/material.dart';
import 'package:zug_chess/zug_chess.dart';

class ChessDialogs {
  static Future<Piece?> pieceDialog(List<Piece> pieces, BuildContext context, {double? width = 800, msg = 'Choose a piece', Image? cancelImg}) async {
    return showDialog<Piece>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        double? choiceWidth;
        if (width != null) choiceWidth = width / (pieces.length + 1);
        List<Widget> choices = [InkWell(
          child: SizedBox(width: choiceWidth, child: cancelImg ?? const SizedBox.shrink()),
          onTap: () {
            Navigator.of(context).pop(null);
          },
        ), ...List.generate(pieces.length, (i) =>  InkWell(
          child: SizedBox(width: choiceWidth, child: Piece.imgMap[pieces.elementAt(i).toString()]),
          onTap: () {
            Navigator.of(context).pop(pieces.elementAt(i));
          },
        ))];
        return AlertDialog(
          title: Text(msg),
          content: SizedBox(width: width, child: SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: choices
          ))),
        );
      },
    ).then((p) {
      return p;
    });
  }
}


